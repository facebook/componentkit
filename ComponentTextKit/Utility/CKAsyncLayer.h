/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <QuartzCore/QuartzCore.h>

typedef NS_ENUM(NSUInteger, CKAsyncLayerDisplayMode) {
  /** Crawls up superlayers. If an async transaction container layer is found, renders async; otherwise, sync. */
  CKAsyncLayerDisplayModeDefault,
  /** Always renders async, even if no parent async transaction container layer is found. */
  CKAsyncLayerDisplayModeAlwaysAsync,
  /** Always render synchronously. This skips crawling superlayers to find a container, which may improve perf. */
  CKAsyncLayerDisplayModeAlwaysSync,
};

@interface CKAsyncLayer : CALayer

/**
 @summary Controls the async display behavior of the layer.

 @default CKAsyncLayerDisplayModeDefault
 */
@property (atomic, assign) CKAsyncLayerDisplayMode displayMode;

/**
 @summary Captures parameters from the receiver on the main thread that will be passed to drawInContext:parameters:
 on a background queue.  Override to capture values from any properties that are needed for drawing.

 @returns The parameters.
 */
- (NSObject *)drawParameters;

/**
 @summary This method may be executed on a background queue to draw the contents of the layer.

 @desc Parameters needed for drawing must be captured in drawParameters in order to ensure that they are consistent for
 the drawing routine.  Subsequent changes to the properties of the layer will require setNeedsDisplay to trigger another
 async display.

 @param context The graphics context in which to draw the content.
 @param parameters The captured parameters from drawParameters.
 */
+ (void)drawInContext:(CGContextRef)context parameters:(NSObject *)parameters;

/**
 @summary Cancels any pending async display.

 @desc If the receiver has had display called and is waiting for the dispatched async display to be executed, this will
 cancel that dispatched async display.  This method is useful to call when removing the receiver from the window.
 */
- (void)cancelAsyncDisplay;

/**
 If contents is nil, this is the same as -setNeedsDisplay.
 If -setNeedsDisplay is called for any other reason during the same pass, it overrides any calls to
 -setNeedsAsyncDisplay and results in the default behavior of -setNeedsDisplay.

 Otherwise, redisplays the layer in the following manner:
 - Redisplay is always asynchronous.
 - Parent transaction containers are ignored.
 - The existing contents are left in the layer instead of being cleared during async display.

 This method can be used when the existing layer contents are valid, just out of date, so there is no need to clear
 contents or modify the parent transaction container.
 */
- (void)setNeedsAsyncDisplay;

@end
