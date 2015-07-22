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
  return [self componentHierarchyDescriptionForView:window searchUpwards:NO];
}

+ (NSString *)componentHierarchyDescriptionForView:(UIView *)view searchUpwards:(BOOL)upwards
{
  if (upwards) {
    return ancestorComponentHierarchyDescriptionForView(view);
  } else {
    return componentHierarchyDescriptionForView(view);
  }
}

static NSString *ancestorComponentHierarchyDescriptionForView(UIView *view)
{
  NSString *ancestorDescription;
  if (view.ck_component) {
    CKComponentRootView *rootView = rootViewForView(view);
    const CKComponentLayout &rootLayout = *rootLayoutFromRootView(rootView);
    NSString *viewAncestorDescription = ancestorDescriptionForView(rootView);
    NSString *componentAncestorDescription = componentAncestorDescriptionForView(view, rootLayout, [@"" stringByPaddingToLength:depthOfViewInViewHierarchy(rootView) * indentString.length
                                                                                                         withString:indentString
                                                                                                    startingAtIndex:0]);
    ancestorDescription = [viewAncestorDescription stringByAppendingString:componentAncestorDescription];
  } else {
    // Views including and above root view do not have an associated component
    ancestorDescription = ancestorDescriptionForView(view);
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
    [description appendString:computeDescription(nil, ancestor, {0, 0}, {0, 0}, prefix)];
    [prefix appendString:indentString];
  }
  return description;
}

static NSString *componentAncestorDescriptionForView(UIView *view, const CKComponentLayout &rootLayout, NSString *prefix)
{
  CKComponent *component = view.ck_component;
  std::deque<CKComponentDescriptionInformation> ancestors;
  buildComponentAncestors(rootLayout, component, {0, 0}, ancestors);
  NSMutableString *description = [NSMutableString string];
  NSMutableString *currentPrefix = [prefix mutableCopy];
  for (auto &descriptionInformation : ancestors) {
    [description appendString:computeDescription(descriptionInformation.layout.component, descriptionInformation.view, descriptionInformation.layout.size, descriptionInformation.position, currentPrefix)];
    [currentPrefix appendString:indentString];
  }
  return description;
}

static BOOL buildComponentAncestors(const CKComponentLayout &layout, CKComponent *component, CGPoint position, std::deque<CKComponentDescriptionInformation> &ancestors)
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

static NSString *componentHierarchyDescriptionForView(UIView *view)
{
  NSString *description;
  if (view.ck_component) {
    CKComponentRootView *rootView = rootViewForView(view);
    CKComponent *component = view.ck_component;
    const CKComponentLayout &rootLayout = *rootLayoutFromRootView(rootView);
    const CKComponentLayout &layout = *findLayoutForComponent(component, rootLayout);
    description = recursiveDescriptionForLayout(layout, {0, 0}, @"");
  } else {
    description = recursiveDescriptionForView(view, @"");
  }
  return description;
}

static NSMutableString *computeDescription(CKComponent *component, UIView *view, CGSize size, CGPoint position, NSString *prefix)
{
  NSMutableString *nodeDescription = [NSMutableString string];
  if (component) {
    NSString *componentDescription = [NSString stringWithFormat:@"%@%@, Position: %@, Size: %@\n", prefix, component, NSStringFromCGPoint(position), NSStringFromCGSize(size)];
    [nodeDescription appendString:componentDescription];
    // We do not add a viewDescription for the component if this condition is not satisfied
    if (component == view.ck_component) { // @"^-> " is used for component's associated view
      NSString *viewDescription = [NSString stringWithFormat:@"%@^-> %@\n", prefix, view];
      [nodeDescription appendString:viewDescription];
    }
  } else { // Isolated view
    NSString *viewDescription = [NSString stringWithFormat:@"%@%@\n", prefix, view];
    [nodeDescription appendString:viewDescription];
  }
  return nodeDescription;
}

static NSMutableString *recursiveDescriptionForView(UIView *view, NSString *prefix)
{
  NSMutableString *description = [NSMutableString string];
  if ([view isKindOfClass:[CKComponentRootView class]]) {
    CKComponentRootView *rootView = (CKComponentRootView *)view;
    const CKComponentLayout *rootLayout = rootLayoutFromRootView(rootView);

    if (rootLayout) {
      [description appendString:computeDescription(nil, rootView, {0, 0}, {0, 0}, prefix)];
      [description appendString:recursiveDescriptionForLayout(*rootLayout, {0, 0}, [prefix stringByAppendingString:indentString])];
      return description;
    }
  }

  description = computeDescription(nil, view, {0, 0}, {0, 0}, prefix);

  if (view.subviews) {
    for (UIView *subview in view.subviews) {
      [description appendString:recursiveDescriptionForView(subview, [prefix stringByAppendingString:indentString])];
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

/* Note: This is fragile code that is being used because ComponentKit is
 * currently in the process of transitioning away holding the root layout in
 * CKComponentRootView
 */
static const CKComponentLayout *rootLayoutFromRootView(CKComponentRootView *rootView)
{
  const CKComponentLayout *rootLayout;
  if (rootView.ck_componentLifecycleManager) {
    rootLayout = &rootView.ck_componentLifecycleManager.state.layout;
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

static NSMutableString *recursiveDescriptionForLayout(const CKComponentLayout &layout, CGPoint position, NSString *prefix)
{
  CKComponent *component = layout.component;
  UIView *view = component.viewContext.view;
  NSMutableString *description = computeDescription(component, view, layout.size, position, prefix);

  if (layout.children) {
    for (const auto &child : *layout.children) {
      [description appendString:recursiveDescriptionForLayout(child.layout, child.position, [prefix stringByAppendingString:indentString])];
    }
  }
  return description;
}

@end
