/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKHighlightOverlayLayer.h"

#import <ComponentKit/CKInternalHelpers.h>

static const CGFloat kCornerRadius = 2.5;
static const UIEdgeInsets padding = {2, 4, 1.5, 4};

@implementation CKHighlightOverlayLayer
{
  NSArray *_rects;
}

+ (id)defaultValueForKey:(NSString *)key
{
  if ([key isEqualToString:@"contentsScale"]) {
    return [NSNumber numberWithFloat:CKScreenScale()];
  } else if ([key isEqualToString:@"highlightColor"]) {
    CGFloat components[] = {0, 0, 0, 0.25};
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGColorRef color = CGColorCreate(colorSpace, components);
    CGColorSpaceRelease(colorSpace);
    return CFBridgingRelease(color);
  } else {
    return [super defaultValueForKey:key];
  }
}

+ (BOOL)needsDisplayForKey:(NSString *)key
{
  if ([key isEqualToString:@"bounds"]) {
    return YES;
  } else {
    return [super needsDisplayForKey:key];
  }
}

- (id)initWithRects:(NSArray *)rects
{
  return [self initWithRects:rects targetLayer:nil];
}

- (id)initWithRects:(NSArray *)rects targetLayer:(id)targetLayer
{
  if (self = [super init]) {
    _rects = [rects copy];
    _targetLayer = targetLayer;
  }
  return self;
}

@dynamic highlightColor;

- (void)drawInContext:(CGContextRef)ctx
{
  [super drawInContext:ctx];

  CGAffineTransform affine = CGAffineTransformIdentity;
  CGMutablePathRef highlightPath = CGPathCreateMutable();
  CALayer *targetLayer = self.targetLayer;

  for (NSValue *value in _rects) {
    CGRect rect = [value CGRectValue];
    if (targetLayer != nil) {
      rect = [self convertRect:rect fromLayer:targetLayer];
    }
    rect = CGRectMake(roundf(rect.origin.x), roundf(rect.origin.y), roundf(rect.size.width), roundf(rect.size.height));

    CGFloat minX = rect.origin.x - padding.left;
    CGFloat maxX = CGRectGetMaxX(rect) + padding.right;
    CGFloat midX = (maxX - minX) / 2 + minX;
    CGFloat minY = rect.origin.y - padding.top;
    CGFloat maxY = CGRectGetMaxY(rect) + padding.bottom;
    CGFloat midY = (maxY - minY) / 2 + minY;

    CGPathMoveToPoint(highlightPath, &affine, minX, midY);
    CGPathAddArcToPoint(highlightPath, &affine, minX, maxY, midX, maxY, kCornerRadius);
    CGPathAddArcToPoint(highlightPath, &affine, maxX, maxY, maxX, midY, kCornerRadius);
    CGPathAddArcToPoint(highlightPath, &affine, maxX, minY, midX, minY, kCornerRadius);
    CGPathAddArcToPoint(highlightPath, &affine, minX, minY, minX, midY, kCornerRadius);
    CGPathCloseSubpath(highlightPath);
  }

  CGContextAddPath(ctx, highlightPath);
  CGContextSetFillColorWithColor(ctx, self.highlightColor);
  CGContextDrawPath(ctx, kCGPathFill);
  CGPathRelease(highlightPath);
}

- (CALayer *)hitTest:(CGPoint)p
{
  // Don't handle taps
  return nil;
}

@end

@implementation CALayer (CKHighlightOverlayLayerSupport)

// ASHighlightOverlayLayer compatibility
static NSString *kAllowsHighlightDrawingKey = @"allows_highlight_drawing";

- (BOOL)ck_allowsHighlightDrawing
{
  return [[self valueForKey:kAllowsHighlightDrawingKey] boolValue];
}

- (void)ck_setAllowsHighlightDrawing:(BOOL)allowsHighlightDrawing
{
  [self setValue:@(allowsHighlightDrawing) forKey:kAllowsHighlightDrawingKey];
}

@end
