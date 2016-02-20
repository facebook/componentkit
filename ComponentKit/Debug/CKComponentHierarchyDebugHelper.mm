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

#import "CKComponent.h"
#import "CKComponentInternal.h"
#import "CKComponentDataSourceAttachController.h"
#import "CKComponentDataSourceAttachControllerInternal.h"
#import "CKComponentLifecycleManager.h"
#import "CKComponentLifecycleManagerInternal.h"
#import "CKComponentViewInterface.h"
#import "CKComponentLayout.h"
#import "CKComponentRootView.h"
#import "CKComponentHostingView.h"
#import "CKComponentHostingViewInternal.h"

#include <deque>

struct CKComponentDescriptionInformation {
  const CKComponentLayout &layout;
  UIView *view;
  CGPoint position;
};

static NSString *const indentString = @"| ";

@implementation CKComponentHierarchyDebugHelper

+ (NSString *)componentHierarchyDescription
{
  UIWindow *window = [[UIApplication sharedApplication] keyWindow];
  return [self componentHierarchyDescriptionForView:window searchUpwards:NO showViews:YES];
}

/**
 This is being kept around because it is used directly by chisel.
 This should be removed once chisel has been updated.
 Do not use this, use componentHierarchyDescriptionForView:searchUpwards:showViews:
 */
+ (NSString *)componentHierarchyDescriptionForView:(UIView *)view searchUpwards:(BOOL)upwards
{
  return [self componentHierarchyDescriptionForView:view searchUpwards:upwards showViews:YES];
}

+ (NSString *)componentHierarchyDescriptionForView:(UIView *)view searchUpwards:(BOOL)upwards showViews:(BOOL)showViews
{
  if (upwards) {
    return ancestorComponentHierarchyDescriptionForView(view, showViews);
  } else {
    return componentHierarchyDescriptionForView(view, showViews);
  }
}

static NSString *ancestorComponentHierarchyDescriptionForView(UIView *view, BOOL showViews)
{
  NSString *ancestorDescription;
  if (view.ck_component) {
    CKComponentRootView *rootView = rootViewForView(view);
    const CKComponentLayout &rootLayout = *rootLayoutFromRootView(rootView);
    NSString *viewAncestorDescription;
    NSString *prefix;
    if (showViews) {
      viewAncestorDescription = ancestorDescriptionForView(rootView);
      prefix = [@"" stringByPaddingToLength:depthOfViewInViewHierarchy(rootView) * indentString.length
                                 withString:indentString
                            startingAtIndex:0];
    } else {
      NSString *rootViewDescription = computeDescription(nil, rootView, CGSizeZero, CGPointZero, @"", YES);
      viewAncestorDescription = [NSString stringWithFormat:@"For View: %@", rootViewDescription];
      prefix = indentString;
    }
    NSString *componentAncestorDescription = componentAncestorDescriptionForView(view, rootLayout, prefix, showViews);
    ancestorDescription = [viewAncestorDescription stringByAppendingString:componentAncestorDescription];
  } else if (showViews) {
    // Views including and above root view do not have an associated component
    ancestorDescription = ancestorDescriptionForView(view);
  } else {
    ancestorDescription = @"No component found for given view";
  }
  return ancestorDescription;
}

static NSUInteger depthOfViewInViewHierarchy(UIView *view)
{
  NSUInteger depth = 0;
  while (view) {
    depth++;
    view = view.superview;
  }
  return depth;
}

static NSString *ancestorDescriptionForView(UIView *view)
{
  NSMutableArray *ancestors = [NSMutableArray array];
  while (view) {
    [ancestors addObject:view];
    view = view.superview;
  }

  NSMutableString *prefix = [NSMutableString string];
  NSMutableString *description = [NSMutableString string];
  // reverse
  NSArray *orderedAncestors = [[ancestors reverseObjectEnumerator] allObjects];

  for (UIView *ancestor in orderedAncestors) {
    [description appendString:computeDescription(nil, ancestor, CGSizeZero, CGPointZero, prefix, YES)];
    [prefix appendString:indentString];
  }
  return description;
}

static NSString *componentAncestorDescriptionForView(UIView *view,
                                                     const CKComponentLayout &rootLayout,
                                                     NSString *prefix,
                                                     BOOL showViews)
{
  CKComponent *component = view.ck_component;
  std::deque<CKComponentDescriptionInformation> ancestors;
  buildComponentAncestors(rootLayout, component, CGPointZero, ancestors);
  NSMutableString *description = [NSMutableString string];
  NSMutableString *currentPrefix = [prefix mutableCopy];
  for (auto &descriptionInformation : ancestors) {
    [description appendString:computeDescription(descriptionInformation.layout.component,
                                                 descriptionInformation.view,
                                                 descriptionInformation.layout.size,
                                                 descriptionInformation.position,
                                                 currentPrefix,
                                                 showViews)];
    [currentPrefix appendString:indentString];
  }
  return description;
}

static BOOL buildComponentAncestors(const CKComponentLayout &layout,
                                    CKComponent *component,
                                    CGPoint position,
                                    std::deque<CKComponentDescriptionInformation> &ancestors)
{
  CKComponent *layoutComponent = layout.component;
  UIView *view = layoutComponent.viewContext.view;
  CKComponentDescriptionInformation descriptionInformation = {layout, view, position};
  ancestors.push_back(descriptionInformation);

  if (component != layoutComponent) {
    if (layout.children) {
      for (const auto &child : *layout.children) {
        BOOL childResult = buildComponentAncestors(child.layout, component, child.position, ancestors);

        if (childResult) {
          return YES;
        }
      }
    }
    ancestors.pop_back();
    return NO;
  }
  return YES;
}

static NSString *componentHierarchyDescriptionForView(UIView *view, BOOL showViews)
{
  NSString *description;
  if (view.ck_component) {
    CKComponentRootView *rootView = rootViewForView(view);
    CKComponent *component = view.ck_component;
    const CKComponentLayout &rootLayout = *rootLayoutFromRootView(rootView);
    const CKComponentLayout &layout = *findLayoutForComponent(component, rootLayout);
    if (showViews) {
      description = recursiveDescriptionForLayout(layout, CGPointZero, @"", showViews);
    } else {
      NSString *rootViewDescription = computeDescription(nil, rootView, CGSizeZero, CGPointZero, @"", YES);
      NSString *viewAncestorDescription = [NSString stringWithFormat:@"For View: %@", rootViewDescription];
      description = recursiveDescriptionForLayout(layout, CGPointZero, indentString, showViews);
      description = [viewAncestorDescription stringByAppendingString:description];
    }
  } else {
    description = recursiveDescriptionForView(view, @"", showViews);
  }
  return description;
}

static NSMutableString *computeDescription(CKComponent *component, UIView *view, CGSize size, CGPoint position, NSString *prefix, BOOL showView)
{
  NSMutableString *nodeDescription = [NSMutableString string];
  if (component) {
    [nodeDescription appendFormat:@"%@%@, Position: %@, Size: %@\n", prefix, component, NSStringFromCGPoint(position), NSStringFromCGSize(size)];
    if (showView && component == view.ck_component) {
      [nodeDescription appendFormat:@"%@^-> %@\n", prefix, view];
    }
  } else if (showView && view) {
    [nodeDescription appendFormat:@"%@%@\n", prefix, view];
  }
  return nodeDescription;
}

static NSMutableString *recursiveDescriptionForView(UIView *view, NSString *prefix, BOOL showViews)
{
  if ([view isKindOfClass:[CKComponentRootView class]]) {
    CKComponentRootView *rootView = (CKComponentRootView *)view;
    const CKComponentLayout *rootLayout = rootLayoutFromRootView(rootView);
    if (rootLayout) {
      NSMutableString *description = [NSMutableString string];
      if (!showViews) {
        [description appendString:@"For View: "];
      }
      // We always get the description of the CKComponentRootView (even if showViews is NO).
      [description appendString:computeDescription(nil, rootView, CGSizeZero, CGPointZero, prefix, YES)];
      [description appendString:recursiveDescriptionForLayout(*rootLayout,
                                                              CGPointZero,
                                                              [prefix stringByAppendingString:indentString],
                                                              showViews)];
      return description;
    }
  }
  // Either the view is not a RootView or it does not have a RootLayout.
  NSMutableString *description = [NSMutableString string];
  if (showViews) {
    [description appendString:computeDescription(nil, view, CGSizeZero, CGPointZero, prefix, YES)];
  }
  if (view.subviews) {
    // If we are not showing views then we shouldn't increase the prefix.
    NSString *newPrefix = showViews ? [prefix stringByAppendingString:indentString] : prefix;
    for (UIView *subview in view.subviews) {
      [description appendString:recursiveDescriptionForView(subview, newPrefix, showViews)];
    }
  }
  return description;
}

static CKComponentRootView *rootViewForView(UIView *view)
{
  while (view && ![view isKindOfClass:[CKComponentRootView class]]) {
    view = view.superview;
  }
  return (CKComponentRootView *)view;
}

static const CKComponentLayout *rootLayoutFromRootView(CKComponentRootView *rootView)
{
  const CKComponentLayout *rootLayout;
  if (rootView.ck_componentLifecycleManager) {
    rootLayout = &rootView.ck_componentLifecycleManager.state.layout;
  } else if (rootView.ck_attachState) {
    rootLayout = &[rootView.ck_attachState layout];
  } else if ([rootView.superview isKindOfClass:[CKComponentHostingView class]]) {
    CKComponentHostingView *hostingView = (CKComponentHostingView *)rootView.superview;
    rootLayout = &hostingView.mountedLayout;
  } else {
    rootLayout = nil;
  }
  return rootLayout;
}

static const CKComponentLayout *findLayoutForComponent(CKComponent *component, const CKComponentLayout &layout)
{
  const CKComponentLayout *componentLayout = nil;
  if (layout.component == component) {
    componentLayout = &layout;
  } else {
    for (const auto &child : *(layout.children)) {
      const CKComponentLayout *childLayout = findLayoutForComponent(component, child.layout);

      if (childLayout) {
        componentLayout = childLayout;
        break;
      }
    }
  }
  return componentLayout;
}

static NSMutableString *recursiveDescriptionForLayout(const CKComponentLayout &layout,
                                                      CGPoint position,
                                                      NSString *prefix,
                                                      BOOL showViews)
{
  CKComponent *component = layout.component;
  NSMutableString *description = computeDescription(component, component.viewContext.view, layout.size, position, prefix, showViews);
  if (layout.children) {
    for (const auto &child : *layout.children) {
      [description appendString:recursiveDescriptionForLayout(child.layout,
                                                              child.position,
                                                              [prefix stringByAppendingString:indentString],
                                                              showViews)];
    }
  }
  return description;
}

@end
