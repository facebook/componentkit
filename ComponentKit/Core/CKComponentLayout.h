/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <utility>
#import <vector>

#import <UIKit/UIKit.h>

#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKSizeRange.h>

@class CKComponent;
@class CKComponentScopeRoot;

struct CKComponentLayoutChild;

/** Deletes the target off the main thread; important since component layouts are large recursive structures. */
struct CKOffMainThreadDeleter {
  void operator()(std::vector<CKComponentLayoutChild> *target);
};

/** Represents the computed size of a component, as well as the computed sizes and positions of its children. */
struct CKComponentLayout {
  CKComponent *component;
  CGSize size;
  std::shared_ptr<const std::vector<CKComponentLayoutChild>> children;
  NSDictionary *extra;

  CKComponentLayout(CKComponent *c, CGSize s, std::vector<CKComponentLayoutChild> ch = {}, NSDictionary *e = nil)
  : component(c), size(s), children(new std::vector<CKComponentLayoutChild>(std::move(ch)), CKOffMainThreadDeleter()), extra(e) {
    CKCAssertNotNil(c, @"Nil components are not allowed");
  };

  CKComponentLayout()
  : component(nil), size({0, 0}), children(new std::vector<CKComponentLayoutChild>(), CKOffMainThreadDeleter()), extra(nil) {};
};

struct CKComponentLayoutChild {
  CGPoint position;
  CKComponentLayout layout;
};

/**
 Recursively mounts the layout in the view, returning a set of the mounted components.
 @param layout The layout to mount, usually returned from a call to -layoutThatFits:parentSize:
 @param view The view in which to mount the layout.
 @param previouslyMountedComponents If a previous layout was mounted, pass the return value of the previous call to
        CKMountComponentLayout; any components that are not present in the new layout will be unmounted.
 @param supercomponent Usually pass nil; if you are mounting a subtree of a layout, pass the parent component so the
        component responder chain can be connected correctly.
 */
NSSet *CKMountComponentLayout(const CKComponentLayout &layout,
                              UIView *view,
                              NSSet *previouslyMountedComponents,
                              CKComponent *supercomponent);

/**
 Safely computes the layout of the given root component by guarding against nil components.
 @param rootComponent The root component to compute the layout for.
 @param sizeRange The size range to compute the component layout within.
 */
CKComponentLayout CKComputeRootComponentLayout(CKComponent *rootComponent, const CKSizeRange &sizeRange);

/**
 Safely computes the layout of the given component by guarding against nil components.
 @param component The component to compute the layout for.
 @param sizeRange The size range to compute the component layout within.
 @param parentSize The parent size of the component to compute the layout for.
 */
CKComponentLayout CKComputeComponentLayout(CKComponent *component,
                                           const CKSizeRange &sizeRange,
                                           const CGSize parentSize);

/** Unmounts all components returned by a previous call to CKMountComponentLayout. */
void CKUnmountComponents(NSSet *componentsToUnmount);
