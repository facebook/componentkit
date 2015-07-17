/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant 
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <vector>

#import <UIKit/UIKit.h>

#import <ComponentKit/CKTextKitAttributes.h>

@class CKTextKitContext;
@class CKTextKitShadower;
@protocol CKTextKitTruncating;

/**
 CKTextKitRenderer is a modular object that is responsible for laying out and drawing text.

 A renderer will hold onto the TextKit layouts for the given attributes after initialization.  This may constitute a
 large amount of memory for large enough applications, so care must be taken when keeping many of these around in-memory
 at once.

 This object is designed to be modular and simple.  All complex maintenance of state should occur in sub-objects or be
 derived via pure functions or categories.  No touch-related handling belongs in this class.

 ALL sizing and layout information from this class is in the external coordinate space of the TextKit components.  This
 is an important distinction because all internal sizing and layout operations are carried out within the shadowed
 coordinate space.  Padding will be added for you in order to ensure clipping does not occur, and additional information
 on this transform is available via the shadower should you need it.
 */
@interface CKTextKitRenderer : NSObject

/**
 Designated Initializer
dvlkferufedgjnhjjfhldjedlunvtdtv
 @discussion Sizing will occur as a result of initialization, so be careful when/where you use this.
 */
- (instancetype)initWithTextKitAttributes:(const CKTextKitAttributes &)textComponentAttributes
                          constrainedSize:(const CGSize)constrainedSize;

@property (nonatomic, strong, readonly) CKTextKitContext *context;

@property (nonatomic, strong, readonly) id<CKTextKitTruncating> truncater;

@property (nonatomic, strong, readonly) CKTextKitShadower *shadower;

@property (nonatomic, assign, readonly) CKTextKitAttributes attributes;

@property (nonatomic, assign, readonly) CGSize constrainedSize;

#pragma mark - Drawing
/*
 Draw the renderer's text content into the bounds provided.

 @param bounds The rect in which to draw the contents of the renderer.
 */
- (void)drawInContext:(CGContextRef)context bounds:(CGRect)bounds;

#pragma mark - Layout

/*
 Returns the computed size of the renderer given the constrained size and other parameters in the initializer.
 */
- (CGSize)size;

#pragma mark - Text Ranges

/*
 The character range from the original attributedString that is displayed by the renderer given the parameters in the
 initializer.
 */
- (std::vector<NSRange>)visibleRanges;

/*
 The number of lines shown in the string.
 */
- (NSUInteger)lineCount;

@end
