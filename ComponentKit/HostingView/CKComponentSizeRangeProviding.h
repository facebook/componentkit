/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <Foundation/Foundation.h>

#import <ComponentKit/CKDimension.h>

@protocol CKComponentSizeRangeProviding <NSObject>
@required
/**
 Called when the layout of an `CKComponentHostingView` is dirtied.

 The delegate can use this callback to provide a size range that constrains the layout
 size of a component.
 */
- (CKSizeRange)sizeRangeForBoundingSize:(CGSize)size;
@end
