/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKComponent.h>

typedef NS_OPTIONS(NSUInteger, CKCenterLayoutComponentCenteringOptions) {
  /** The child is positioned in {0,0} relatively to the layout bounds */
  CKCenterLayoutComponentCenteringNone = 0,
  /** The child is centered along the X axis */
  CKCenterLayoutComponentCenteringX = 1 << 0,
  /** The child is centered along the Y axis */
  CKCenterLayoutComponentCenteringY = 1 << 1,
  /** Convenience option to center both along the X and Y axis */
  CKCenterLayoutComponentCenteringXY = CKCenterLayoutComponentCenteringX | CKCenterLayoutComponentCenteringY
};

typedef NS_OPTIONS(NSUInteger, CKCenterLayoutComponentSizingOptions) {
  /** The component will take up the maximum size possible */
  CKCenterLayoutComponentSizingOptionDefault,
  /** The component will take up the minimum size possible along the X axis */
  CKCenterLayoutComponentSizingOptionMinimumX = 1 << 0,
  /** The component will take up the minimum size possible along the Y axis */
  CKCenterLayoutComponentSizingOptionMinimumY = 1 << 1,
  /** Convenience option to take up the minimum size along both the X and Y axis */
  CKCenterLayoutComponentSizingOptionMinimumXY = CKCenterLayoutComponentSizingOptionMinimumX | CKCenterLayoutComponentSizingOptionMinimumY,
};

/** Lays out a single child component and position it so that it is centered into the layout bounds. */
@interface CKCenterLayoutComponent : CKComponent

/**
 @param centeringOptions, see CKCenterLayoutComponentCenteringOptions.
 @param sizingOptions, see CKCenterLayoutComponentSizingOptions.
 @param child The child to center.
 @param size The component size or {} for the default which is for the layout to take the maximum space available.
 */
+ (instancetype)newWithCenteringOptions:(CKCenterLayoutComponentCenteringOptions)centeringOptions
                          sizingOptions:(CKCenterLayoutComponentSizingOptions)sizingOptions
                                  child:(CKComponent *)child
                                   size:(const CKComponentSize &)size;

@end
