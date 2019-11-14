/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKBuildTrigger.h>
#import <ComponentKit/CKLayout.h>
#import <ComponentKit/CKOptional.h>

@protocol CKAnalyticsListener;

/**
 Recursively mounts the layout in the view, returning a set of the mounted components.
 This function is not for a generic use case of mounting every implementation of `CKMountable`, instead it's only for `CKComponent`.
 @param layout The layout to mount, usually returned from a call to -layoutThatFits:parentSize:
 @param view The view in which to mount the layout.
 @param previouslyMountedComponents If a previous layout was mounted, pass the return value of the previous call to
        CKMountComponentLayout; any components that are not present in the new layout will be unmounted.
 @param supercomponent Usually pass nil; if you are mounting a subtree of a layout, pass the parent component so the
        component responder chain can be connected correctly.
 @param analyticsListener analytics listener used to log mount time.
 @param isUpdate Indicates whether the mount is due to an (state/props) update.
 */
CKMountLayoutResult CKMountComponentLayout(const CKComponentLayout &layout,
                                           UIView *view,
                                           NSSet *previouslyMountedComponents,
                                           id<CKMountable> supercomponent,
                                           id<CKAnalyticsListener> analyticsListener = nil,
                                           BOOL isUpdate = NO);

/**
 Safely computes the layout of the given root component by guarding against nil components.
 @param rootComponent The root component to compute the layout for.
 @param sizeRange The size range to compute the component layout within.
 @param analyticsListener analytics listener used to log layout time.
 @param buildTrigger Indicates the source that triggers this layout computation.
 */
CKComponentRootLayout CKComputeRootComponentLayout(id<CKMountable> rootComponent,
                                                   const CKSizeRange &sizeRange,
                                                   id<CKAnalyticsListener> analyticsListener = nil,
                                                   CK::Optional<CKBuildTrigger> buildTrigger = CK::none);
