/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */


#import <ComponentKit/CKLayoutComponent.h>
#import <ComponentKit/CKDefines.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, CKCenterLayoutComponentCenteringOptions) {
  /** The child is positioned in {0,0} relatively to the layout bounds */
  CKCenterLayoutComponentCenteringNone = 0,
  /** The child is centered along the X axis */
  CKCenterLayoutComponentCenteringX = 1 << 0,
  /** The child is centered along the Y axis */
  CKCenterLayoutComponentCenteringY = 1 << 1,
  /** Convenience option to center both along the X and Y axis */
  CKCenterLayoutComponentCenteringXY = CKCenterLayoutComponentCenteringX | CKCenterLayoutComponentCenteringY
} NS_SWIFT_NAME(CenterLayoutComponent.CenteringOptions);

typedef NS_OPTIONS(NSUInteger, CKCenterLayoutComponentSizingOptions) {
  /** The component will take up the maximum size possible */
  CKCenterLayoutComponentSizingOptionDefault,
  /** The component will take up the minimum size possible along the X axis */
  CKCenterLayoutComponentSizingOptionMinimumX = 1 << 0,
  /** The component will take up the minimum size possible along the Y axis */
  CKCenterLayoutComponentSizingOptionMinimumY = 1 << 1,
  /** Convenience option to take up the minimum size along both the X and Y axis */
  CKCenterLayoutComponentSizingOptionMinimumXY = CKCenterLayoutComponentSizingOptionMinimumX | CKCenterLayoutComponentSizingOptionMinimumY,
} NS_SWIFT_NAME(CenterLayoutComponent.SizingOptions);

/** Lays out a single child component and position it so that it is centered into the layout bounds. */
NS_SWIFT_NAME(CenterLayoutComponent)
@interface CKCenterLayoutComponent : CKLayoutComponent

CK_INIT_UNAVAILABLE;

CK_LAYOUT_COMPONENT_INIT_UNAVAILABLE;

#if CK_SWIFT

/**
 @param centeringOptions see CKCenterLayoutComponentCenteringOptions.
 @param sizingOptions see CKCenterLayoutComponentSizingOptions.
 @param child The child to center.
 @param swiftSize The component size or nil for the default which is for the layout to take the maximum space available.
 */
- (instancetype)initWithCenteringOptions:(CKCenterLayoutComponentCenteringOptions)centeringOptions
                           sizingOptions:(CKCenterLayoutComponentSizingOptions)sizingOptions
                                   child:(CKComponent *)child
                               swiftSize:(CKComponentSize_SwiftBridge *_Nullable)swiftSize NS_DESIGNATED_INITIALIZER;


#else

/**
 @param centeringOptions see CKCenterLayoutComponentCenteringOptions.
 @param sizingOptions see CKCenterLayoutComponentSizingOptions.
 @param child The child to center.
 @param size The component size or {} for the default which is for the layout to take the maximum space available.
 */
- (instancetype)initWithCenteringOptions:(CKCenterLayoutComponentCenteringOptions)centeringOptions
                           sizingOptions:(CKCenterLayoutComponentSizingOptions)sizingOptions
                                   child:(CKComponent *_Nullable)child
                                    size:(const CKComponentSize &)size NS_DESIGNATED_INITIALIZER;

#endif

@end

NS_ASSUME_NONNULL_END

#import <ComponentKit/CenterLayoutComponentBuilder.h>
