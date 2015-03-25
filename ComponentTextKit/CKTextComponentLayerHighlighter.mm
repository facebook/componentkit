/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKTextComponentLayerHighlighter.h"

#import <ComponentKit/CKAssert.h>

#import <ComponentKit/CKHighlightOverlayLayer.h>

#import <ComponentKit/CKTextKitRenderer+Positioning.h>
#import <ComponentKit/CKTextKitRenderer.h>

#import "CKTextComponentLayer.h"

@implementation CKTextComponentLayerHighlighter
{
  __weak CKTextComponentLayer *_textComponentLayer;

  CKHighlightOverlayLayer *_highlightOverlayLayer;
}

- (instancetype)initWithTextComponentLayer:(CKTextComponentLayer *)textComponentLayer
{
  if (self = [super init]) {
    _textComponentLayer = textComponentLayer;
  }
  return self;
}

- (void)setHighlightedRange:(NSRange)highlightedRange
{
  CKAssertMainThread();
  if (!NSEqualRanges(_highlightedRange, highlightedRange)) {
    _highlightedRange = highlightedRange;

    if (NSEqualRanges(_highlightedRange, CKTextComponentLayerInvalidHighlightRange)) {
      // We should hide the overlay layer
      if (_highlightOverlayLayer) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [_highlightOverlayLayer removeFromSuperlayer];
        _highlightOverlayLayer = nil;
        [CATransaction commit];
      }
    } else {
      NSArray *rects = [_textComponentLayer.renderer rectsForTextRange:_highlightedRange measureOption:CKTextKitRendererMeasureOptionBlock];
      [CATransaction begin];
      [CATransaction setDisableActions:YES];
      if (_highlightOverlayLayer) {
        [_highlightOverlayLayer removeFromSuperlayer];
      }
      _highlightOverlayLayer = [[CKHighlightOverlayLayer alloc] initWithRects:rects targetLayer:_textComponentLayer];

      CALayer *highlightContainerLayer = _textComponentLayer;
      CALayer *superlayer;
      while (!highlightContainerLayer.ck_allowsHighlightDrawing && (superlayer = highlightContainerLayer.superlayer) != nil) {
        highlightContainerLayer = superlayer;
      }

      _highlightOverlayLayer.frame = highlightContainerLayer.bounds;
      [highlightContainerLayer addSublayer:_highlightOverlayLayer];

      [CATransaction commit];
    }
  }
}

- (void)layoutHighlight
{
  if (_highlightOverlayLayer) {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    _highlightOverlayLayer.frame = _highlightOverlayLayer.superlayer.bounds;
    [CATransaction commit];
  }
}

@end
