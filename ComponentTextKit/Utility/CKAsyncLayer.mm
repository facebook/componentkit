/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKAsyncLayer.h"
#import "CKAsyncLayerInternal.h"
#import "CKAsyncLayerSubclass.h"

#include <libkern/OSAtomic.h>

#import <ComponentKit/CKAssert.h>

#import "CKAsyncTransaction.h"
#import "CKAsyncTransactionContainer.h"

@implementation CKAsyncLayer
{
  BOOL _needsAsyncDisplayOnly;
}

#pragma mark - Class Methods

+ (dispatch_queue_t)displayQueue
{
  static dispatch_queue_t displayQueue = NULL;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    displayQueue = dispatch_queue_create("com.facebook.CKAsyncLayer.display", DISPATCH_QUEUE_CONCURRENT);
    // we use the highpri queue to prioritize UI rendering over other async operations
    dispatch_set_target_queue(displayQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
  });

  return displayQueue;
}

+ (id)defaultValueForKey:(NSString *)key
{
  if ([key isEqualToString:@"displayMode"]) {
    return @(CKAsyncLayerDisplayModeDefault);
  } else {
    return [super defaultValueForKey:key];
  }
}

#pragma mark - Properties

- (NSString *)name
{
  return [super name] ?: [NSString stringWithFormat:@"%@ (%p)", NSStringFromClass([self class]), self];
}

@dynamic displayMode;

- (void)setNeedsDisplay
{
  CKAssertMainThread();
  [self cancelAsyncDisplay];
  [super setNeedsDisplay];
  // Be sure to override any previous calls to -setNeedsAsyncDisplay:
  _needsAsyncDisplayOnly = NO;
}

- (void)setNeedsAsyncDisplay
{
  CKAssertMainThread();

  if ([self needsDisplay]) {
    // Either of these two situations:
    // 1. -setNeedsDisplay has already been called; in that case it overrides the call to -setNeedsAsyncDisplay.
    // 2. -setNeedsAsyncDisplay has already been called; in that case _needsAsyncDisplayOnly is already set.
    return;
  }

  [self cancelAsyncDisplay];
  [super setNeedsDisplay];
  _needsAsyncDisplayOnly = YES;
}

#pragma mark - Display

- (void)cancelAsyncDisplay
{
  CKAssertMainThread();
  OSAtomicIncrement32(&_displaySentinel);
}

+ (ck_async_transaction_operation_block_t)asyncDisplayBlockWithBounds:(CGRect)bounds
                                                        contentsScale:(CGFloat)contentsScale
                                                               opaque:(BOOL)opaque
                                                      backgroundColor:(CGColorRef)backgroundColor
                                                      displaySentinel:(int32_t *)displaySentinel
                                         expectedDisplaySentinelValue:(int32_t)expectedDisplaySentinelValue
                                                      drawingDelegate:(id<CKAsyncLayerDrawingDelegate>)drawingDelegate
                                                       drawParameters:(NSObject *)drawParameters
{
  // make this an id so the block will capture it
  id backgroundColorObject = (__bridge id)backgroundColor;
  return [^id{
    // Short-circuit to be efficient in the case where we've already started a different -display.
    if ((displaySentinel != nil) && (*displaySentinel != expectedDisplaySentinelValue)) {
      return nil;
    }

    if (CGRectIsEmpty(bounds)) {
      return nil;
    }

    UIGraphicsBeginImageContextWithOptions(bounds.size, opaque, contentsScale);
    CGContextRef bitmapContext = UIGraphicsGetCurrentContext();

    if (backgroundColorObject != NULL) {
      CGContextSetFillColorWithColor(bitmapContext, (CGColorRef)backgroundColorObject);
      CGContextFillRect(bitmapContext, bounds);
    }

    [drawingDelegate drawAsyncLayerInContext:bitmapContext parameters:drawParameters];

    CGImageRef image = CGBitmapContextCreateImage(bitmapContext);
    UIGraphicsEndImageContext();

    return CFBridgingRelease(image);
  } copy];
}

- (void)display
{
  CKAssertMainThread();

  BOOL renderSynchronously = NO;
  CALayer *parentTransactionContainer;

  if (!_needsAsyncDisplayOnly) {
    switch (self.displayMode) {
      case CKAsyncLayerDisplayModeDefault:
        parentTransactionContainer = self.ck_parentTransactionContainer;
        renderSynchronously = (parentTransactionContainer == nil);
        break;
      case CKAsyncLayerDisplayModeAlwaysAsync:
        parentTransactionContainer = self.ck_parentTransactionContainer;
        break;
      case CKAsyncLayerDisplayModeAlwaysSync:
        // Avoid cost of finding parentTransactionContainer, we're going to render synchronously regardless.
        renderSynchronously = YES;
        break;
    }
  }

  if (renderSynchronously) {
    [super display];
    return;
  }

  if (!_needsAsyncDisplayOnly) {
    // Reset needsDisplay to NO and remove any old content; otherwise it might appear stretched until rendering completes
    self.contents = nil;
  }
  // Clear the _needsAsyncDisplayOnly flag for this display pass, since we've started async display.
  _needsAsyncDisplayOnly = NO;

  CGRect bounds = self.bounds;
  if (CGRectIsEmpty(bounds)) {
    return;
  }

  NSObject *drawParameters = [self drawParameters];
  id shortCircuitContents = [self willDisplayAsynchronouslyWithDrawParameters:drawParameters];
  if (shortCircuitContents) {
    self.contents = shortCircuitContents;
    return;
  }

  int32_t displaySentinelValue = OSAtomicIncrement32(&_displaySentinel);
  CALayer *containerLayer = parentTransactionContainer ?: self;
  CKAsyncTransaction *transaction = containerLayer.ck_asyncTransaction;
  CKAssertNotNil(transaction, @"Expected async layer transaction to be non-nil");
  ck_async_transaction_operation_block_t transactionBlock = [[self class] asyncDisplayBlockWithBounds:bounds
                                                                                        contentsScale:self.contentsScale
                                                                                               opaque:self.opaque
                                                                                      backgroundColor:self.backgroundColor
                                                                                      displaySentinel:&_displaySentinel
                                                                         expectedDisplaySentinelValue:displaySentinelValue
                                                                                      drawingDelegate:(id<CKAsyncLayerDrawingDelegate>)[self class]
                                                                                       drawParameters:drawParameters];
  ck_async_transaction_operation_completion_block_t completionBlock = ^(id<NSObject> value, BOOL canceled) {
    CKCAssertMainThread();
    if (!canceled && (_displaySentinel == displaySentinelValue)) {
      [self didDisplayAsynchronously:value withDrawParameters:drawParameters];
      self.contents = value;
    }
  };
  [transaction addOperationWithBlock:transactionBlock queue:[[self class] displayQueue] completion:completionBlock];
}

- (id)willDisplayAsynchronouslyWithDrawParameters:(id<NSObject>)drawParameters
{
  return nil;
}

- (void)didDisplayAsynchronously:(id)newContents withDrawParameters:(id<NSObject>)drawParameters
{
}

#pragma mark - Drawing

/// this method exists to provide an override point for ASDisplayNodeAsyncLayer where it can use its asyncDelegate in place
/// of self for this implementation
+ (void)drawAsyncLayerInContext:(CGContextRef)context parameters:(NSObject *)parameters
{
  [self drawInContext:context parameters:parameters];
}

+ (void)drawInContext:(CGContextRef)context parameters:(NSObject *)parameters
{
  // Empty in base class
}

- (void)drawInContext:(CGContextRef)context
{
  CKAssertMainThread();
  [[self class] drawInContext:context parameters:[self drawParameters]];
}

- (NSObject *)drawParameters
{
  return nil;
}

@end
