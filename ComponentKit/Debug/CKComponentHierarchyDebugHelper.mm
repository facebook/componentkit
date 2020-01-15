/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentHierarchyDebugHelper.h"

#import <UIKit/UIKit.h>

#import "CKComponent+UIView.h"
#import "CKComponent.h"
#import "CKComponentInternal.h"
#import "CKComponentAttachController.h"
#import "CKComponentAttachControllerInternal.h"
#import "CKComponentLayout.h"
#import "CKComponentRootView.h"
#import "CKComponentHostingView.h"
#import "CKComponentHostingViewInternal.h"
#import "ComponentUtilities.h"

static NSString *const indentString = @"| ";

@interface CKComponentHierarchyDebugHelper ()

+ (NSString *)componentHierarchyDescriptionForView:(UIView *)view NS_EXTENSION_UNAVAILABLE("Recursively describes components using -[UIApplication keyWindow]");
+ (NSString *)componentHierarchyDescriptionForView:(UIView *)view searchUpwards:(BOOL)upwards showViews:(BOOL)showViews NS_EXTENSION_UNAVAILABLE("Recursively describes components using -[UIApplication keyWindow]");

@end

@implementation CKComponentHierarchyDebugHelper

+ (NSString *)componentHierarchyDescription
{
  NSMutableString *description = [NSMutableString string];
  for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
    if ([description length]) {
      [description appendString:@"\n"];
    }
    buildRecursiveDescriptionForView(description, [NSMutableSet new], [NSMutableSet new], window, @"");
  }
  return description;
}

/** Used by Chisel. Don't rename or remove this without changing Chisel! */
+ (NSString *)componentHierarchyDescriptionForView:(UIView *)view  NS_EXTENSION_UNAVAILABLE("Recursively describes components using -[UIApplication keyWindow]")
{
  if (view == nil) {
    return [self componentHierarchyDescription];
  } else {
    NSMutableString *description = [NSMutableString string];
    buildRecursiveDescriptionForView(description, [NSMutableSet new], [NSMutableSet new], view, @"");
    return description;
  }
}

/** Deprecated, used by old versions of Chisel. If you come across this after June 2018, delete it. */
+ (NSString *)componentHierarchyDescriptionForView:(UIView *)view searchUpwards:(BOOL)upwards showViews:(BOOL)showViews  NS_EXTENSION_UNAVAILABLE("Recursively describes components using -[UIApplication keyWindow]")
{
  return [self componentHierarchyDescriptionForView:view];
}

static void buildRecursiveDescriptionForView(NSMutableString *description,
                                             NSMutableSet<UIView *> *visitedViews,
                                             NSMutableSet<id<CKMountable>> *visitedComponents,
                                             UIView *view,
                                             NSString *prefix)
{
  if ([visitedViews containsObject:view]) {
    return;
  }
  [visitedViews addObject:view];

  CKComponent *component = CKMountedComponentForView(view);
  if (component) {
    // If we encounter a component in this way, either we were asked to start printing from the
    // middle of the tree via componentHierarchyDescriptionForView:, or someone is playing tricks
    // and doing weird things. In any case, go ahead and try to find the corresponding layout
    // and print it.
    const CKComponentLayout layout = findLayoutForComponent(view, component);
    if (layout.component) {
      buildRecursiveDescriptionForLayout(description,
                                         visitedViews,
                                         visitedComponents,
                                         layout,
                                         {0, 0},
                                         prefix);
      return; // that covers this view and its subviews
    }
  }

  [description appendString:prefix];
  [description appendString:forceToSingleLine([view description]) ?: @"(unknown)"];
  [description appendString:@"\n"];

  NSString *newPrefix = [prefix stringByAppendingString:indentString];

  // If we encounter a CKComponentRootView, we want to print the view and then jump into
  // visiting the root layout it contains.
  if ([view isKindOfClass:[CKComponentRootView class]]) {
    CKComponentLayout rootLayout = rootLayoutFromRootView((CKComponentRootView *)view);
    if (rootLayout.component) {
      buildRecursiveDescriptionForLayout(description,
                                         visitedViews,
                                         visitedComponents,
                                         rootLayout,
                                         {0, 0},
                                         prefix);
      return; // CKComponentRootView should only have ComponentKit-managed subviews.
    }
  }

  if (view.subviews) {
    for (UIView *subview in view.subviews) {
      buildRecursiveDescriptionForView(description,
                                       visitedViews,
                                       visitedComponents,
                                       subview,
                                       newPrefix);
    }
  }
}

static CKComponentLayout rootLayoutFromRootView(CKComponentRootView *rootView)
{
  if (CKGetAttachStateForView(rootView)) {
    return CKComponentAttachStateRootLayout(CKGetAttachStateForView(rootView)).layout();
  } else if ([rootView.superview isKindOfClass:[CKComponentHostingView class]]) {
    CKComponentHostingView *hostingView = (CKComponentHostingView *)rootView.superview;
    return hostingView.mountedLayout;
  } else {
    return {};
  }
}

/** Given a layout, finds the sub-layout for a given component. */
static CKComponentLayout findComponentInLayout(CKComponentLayout layout, CKComponent *component)
{
  if (layout.component == component) {
    return layout;
  } else if (layout.children) {
    for (const auto &child : *(layout.children)) {
      const CKComponentLayout childLayout = findComponentInLayout(child.layout, component);
      if (childLayout.component) {
        return childLayout;
      }
    }
  }
  return {};
}

/**
 Given a view, searches up the hierarchy and finds all ancestor root views.
 For each, looks in its layout to find the component if it exists, and returns its layout.
 */
static const CKComponentLayout findLayoutForComponent(UIView *view, CKComponent *component)
{
  while (view) {
    if ([view isKindOfClass:[CKComponentRootView class]]) {
      CKComponentLayout rootLayout = rootLayoutFromRootView((CKComponentRootView *)view);
      CKComponentLayout layoutForComponent = findComponentInLayout(rootLayout, component);
      if (layoutForComponent.component == component) {
        return layoutForComponent;
      }
    }
    view = view.superview;
  }
  return {};
}

static void buildRecursiveDescriptionForLayout(NSMutableString *description,
                                               NSMutableSet<UIView *> *visitedViews,
                                               NSMutableSet<id<CKMountable>> *visitedComponents,
                                               const CKComponentLayout &layout,
                                               CGPoint position,
                                               NSString *prefix)
{
  if (layout.component == nil) {
    return;
  }
  auto component = layout.component;
  if ([visitedComponents containsObject:component]) {
    return;
  }
  [visitedComponents addObject:component];
  [description appendString:prefix];
  [description appendString:forceToSingleLine([component description]) ?: @"(unknown)"];
  [description appendFormat:@", position=%@", NSStringFromCGPoint(position)];
  UIView *mountedView = component.mountedView;
  if (mountedView) {
    [visitedViews addObject:mountedView];
    [description appendString:@": "];
    [description appendString:forceToSingleLine([mountedView description]) ?: @"(unknown)"];
    [description appendString:@"\n"];
  } else {
    [description appendFormat:@", size: %@\n", NSStringFromCGSize(layout.size)];
  }
  NSString *newPrefix = [prefix stringByAppendingString:indentString];
  if (layout.children) {
    for (const auto &child : *layout.children) {
      buildRecursiveDescriptionForLayout(description,
                                         visitedViews,
                                         visitedComponents,
                                         child.layout,
                                         position + child.position,
                                         newPrefix);
    }
  }
  if (mountedView) {
    // We've already recursively visited all child layouts and their views, so all ComponentKit-
    // managed subviews should be present in visitedViews. Just do a pass through to check for
    // any non-ComponentKit subviews and print those; we'll ignore everything already in
    // visitedViews.
    for (UIView *subview in mountedView.subviews) {
      buildRecursiveDescriptionForView(description,
                                       visitedViews,
                                       visitedComponents,
                                       subview,
                                       newPrefix);
    }
  }
}

static NSString *forceToSingleLine(NSString *description)
{
  return [description stringByReplacingOccurrencesOfString:@"\n" withString:@"$"];
}

@end
