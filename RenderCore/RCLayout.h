/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <RenderCore/CKDefines.h>

#if CK_NOT_SWIFT

#import <utility>
#import <vector>

#import <UIKit/UIKit.h>

#import <RenderCore/CKAssert.h>
#import <RenderCore/CKEqualityHelpers.h>
#import <RenderCore/CKMountable.h>
#import <RenderCore/CKNonNull.h>
#import <RenderCore/CKOptional.h>
#import <RenderCore/CKSizeRange.h>

@protocol CKAnalyticsListener;
@protocol CKMountable;

struct RCLayoutChild;

/** Represents the computed size of a component, as well as the computed sizes and positions of its children. */
struct RCLayout {
  id<CKMountable> component;
  CGSize size;
  std::shared_ptr<const std::vector<RCLayoutChild>> children;
  NSDictionary *extra;

  RCLayout(id<CKMountable> c, CGSize s) noexcept;
  RCLayout(id<CKMountable> c, CGSize s, const std::vector<RCLayoutChild> &ch, NSDictionary *e = nil) noexcept;
  RCLayout(id<CKMountable> c, CGSize s, std::vector<RCLayoutChild> &&ch, NSDictionary *e = nil) noexcept;

  RCLayout() noexcept;

  void enumerateLayouts(const std::function<void(const RCLayout &)> &f) const;
  std::string description(int indent = 0) const;

private:
  static std::shared_ptr<const std::vector<RCLayoutChild>> emptyChildren() noexcept;
};
using CKComponentLayout = RCLayout; // TODO remove after new version is released on Github.

struct RCLayoutChild {
  CGPoint position;
  RCLayout layout;
};

@protocol CKMountLayoutListener <NSObject>

/**
 Called before/after mounting a component.
 */
- (void)willMountComponent:(id<CKMountable>)component;
- (void)didMountComponent:(id<CKMountable>)component;

@end

/**
 Recursively mounts the layout in the view, returning a set of the mounted components.
 @param layout The layout to mount, usually returned from a call to -layoutThatFits:parentSize:
 @param view The view in which to mount the layout.
 @param previouslyMountedComponents If a previous layout was mounted, pass the return value of the previous call to
        CKMountLayout; any components that are not present in the new layout will be unmounted.
 @param supercomponent Usually pass nil; if you are mounting a subtree of a layout, pass the parent component so the
        component responder chain can be connected correctly.
 @param mountAnalyticsContext If non-null, the counters in this context will be incremented during mount.
 @param listener Object collecting all mount layout events. Can be nil.
 */
NSSet<id<CKMountable>> *CKMountLayout(const RCLayout &layout,
                                      UIView *view,
                                      NSSet<id<CKMountable>> *previouslyMountedComponents,
                                      id<CKMountable> supercomponent,
                                      CK::Component::MountAnalyticsContext *mountAnalyticsContext,
                                      id<CKMountLayoutListener> listener);

/** Unmounts all components returned by a previous call to CKMountComponentLayout. */
void CKUnmountComponents(NSSet<id<CKMountable>> *componentsToUnmount);

#endif
