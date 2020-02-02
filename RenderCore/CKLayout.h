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

struct CKComponentLayoutChild;

/** Represents the computed size of a component, as well as the computed sizes and positions of its children. */
struct CKComponentLayout { // This is pending renaming
  id<CKMountable> component;
  CGSize size;
  std::shared_ptr<const std::vector<CKComponentLayoutChild>> children;
  NSDictionary *extra;

  CKComponentLayout(id<CKMountable> c, CGSize s) noexcept;
  CKComponentLayout(id<CKMountable> c, CGSize s, const std::vector<CKComponentLayoutChild> &ch, NSDictionary *e = nil) noexcept;
  CKComponentLayout(id<CKMountable> c, CGSize s, std::vector<CKComponentLayoutChild> &&ch, NSDictionary *e = nil) noexcept;

  CKComponentLayout() noexcept;

  void enumerateLayouts(const std::function<void(const CKComponentLayout &)> &f) const;

private:
  static std::shared_ptr<const std::vector<CKComponentLayoutChild>> emptyChildren() noexcept;
};

struct CKComponentLayoutChild {
  CGPoint position;
  CKComponentLayout layout;
};

struct CKMountLayoutResult {
  CK::NonNull<NSSet *> mountedComponents;
  NSSet *unmountedComponents;
  CK::Optional<CK::Component::MountAnalyticsContext> mountAnalyticsContext;
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

 @param isUpdate Indicates whether the mount is due to an (state/props) update.
 @param shouldCollectMountInfo should mount information be collected and returned in `CKMountLayoutResult`.
 @param listener Object collecting all mount layout events. Can be nil.
 */
CKMountLayoutResult CKMountLayout(const CKComponentLayout &layout,
                                  UIView *view,
                                  NSSet *previouslyMountedComponents,
                                  id<CKMountable> supercomponent,
                                  BOOL isUpdate = NO,
                                  BOOL shouldCollectMountInfo = NO,
                                  id<CKMountLayoutListener> listener = nil);

/** Unmounts all components returned by a previous call to CKMountComponentLayout. */
void CKUnmountComponents(NSSet<id<CKMountable>> *componentsToUnmount);

#endif
