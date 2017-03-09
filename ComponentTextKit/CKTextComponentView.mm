/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKTextComponentView.h"
#import "CKTextComponentViewInternal.h"

#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKAsyncLayer.h>
#import <ComponentKit/CKAsyncLayerSubclass.h>
#import <ComponentKit/CKTextKitRenderer.h>
#import <ComponentKit/CKTextKitRendererCache.h>
#import <ComponentKit/CKInternalHelpers.h>

#import "CKTextComponentLayer.h"
#import "CKTextComponentLayerHighlighter.h"
#import "CKTextComponentViewControlTracker.h"

@implementation CKTextComponentView
{
  CKTextComponentViewControlTracker *_controlTracker;
}

+ (Class)layerClass
{
  return [CKTextComponentLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    // Set some sensible defaults for a text view
    self.contentScaleFactor = CKScreenScale();
    self.backgroundColor = [UIColor whiteColor];
  }
  return self;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
  if (![self.backgroundColor isEqual:backgroundColor]) {
    BOOL opaque = self.textLayer.opaque;
    [super setBackgroundColor:backgroundColor];

    // for reasons I don't understand, UIView is setting opaque=NO on self.layer when setting the background color.  we
    // don't want to force our rich text layers to draw with blending, so check if we can keep the opacity value after
    // setting the backgroundColor.
    if (opaque) {
      CGFloat alpha = 0.0;
      if ([backgroundColor getRed:NULL green:NULL blue:NULL alpha:&alpha] ||
          [backgroundColor getWhite:NULL alpha:&alpha] ||
          [backgroundColor getHue:NULL saturation:NULL brightness:NULL alpha:&alpha]) {
        if (alpha == 1.0) {
          self.textLayer.opaque = YES;
        }
      }
    }
  }
}

- (CKTextComponentLayer *)textLayer
{
  return (CKTextComponentLayer *)self.layer;
}

- (void)setRenderer:(CKTextKitRenderer *)renderer
{
  [self.textLayer setRenderer:renderer];
}

- (CKTextKitRenderer *)renderer
{
  return [self.textLayer renderer];
}

#pragma mark - Control Tracking

- (CKTextComponentViewControlTracker *)controlTracker
{
  if (!_controlTracker) {
    // Lazily generate a control tracker to receive UIControl touch input.
    _controlTracker = [[CKTextComponentViewControlTracker alloc] init];
  }
  return _controlTracker;
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
  if (![super beginTrackingWithTouch:touch withEvent:event]) {
    return NO;
  }
  return [self.controlTracker beginTrackingForTextComponentView:self withTouch:touch withEvent:event];
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
  if (![super continueTrackingWithTouch:touch withEvent:event]) {
    return NO;
  }
  return [self.controlTracker continueTrackingForTextComponentView:self withTouch:touch withEvent:event];
}

- (void)cancelTrackingWithEvent:(UIEvent *)event
{
  [self.controlTracker cancelTrackingForTextComponentView:self withEvent:event];
  [super cancelTrackingWithEvent:event];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
  [self.controlTracker endTrackingForTextComponentView:self withTouch:touch withEvent:event];
  [super endTrackingWithTouch:touch withEvent:event];
}

#pragma mark - Touch Interaction

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)recognizer
{
  // We want the same behavior as UIButton: "...a UIButton, by default, does return NO for a single tap
  // UITapGestureRecognizer whose view is not the UIButton itself."
  // http://www.apeth.com/iOSBook/ch18.html#_gesture_recognizers
  if ([recognizer isKindOfClass:[UITapGestureRecognizer class]]) {
    UITapGestureRecognizer *tapRecognizer = (UITapGestureRecognizer *)recognizer;
    if (tapRecognizer.numberOfTapsRequired == 1 && tapRecognizer.view != self) {
      return NO;
    }
  }
  return [super gestureRecognizerShouldBegin:recognizer];
}

@end
