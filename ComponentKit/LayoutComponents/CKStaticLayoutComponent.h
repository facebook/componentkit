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

#import <Foundation/Foundation.h>

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKDimension.h>

struct CKStaticLayoutComponentChild {
  CGPoint position;
  CKComponent *component;

  /**
   If specified, the component's size is restricted according to this size. Percentages are resolved relative to the
   static layout component.

   The default is Auto in both dimensions, which sets the child's min size to zero and max size to the maximum available
   space it can consume without overflowing the component's bounds.
   */
  CKRelativeSizeRange size;
};

/*
 A component that positions children at fixed positions.

 Computes a size that is the union of all childrens' frames.
 */
@interface CKStaticLayoutComponent : CKComponent

/**
 @param view Passed to the super class initializer.
 @param children Children to be positioned at fixed positions.
 */
+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view
                       size:(const CKComponentSize &)size
                   children:(const std::vector<CKStaticLayoutComponentChild> &)children;

/**
 Convenience that does not have a view or size.
 */
+ (instancetype)newWithChildren:(const std::vector<CKStaticLayoutComponentChild> &)children;

@end
