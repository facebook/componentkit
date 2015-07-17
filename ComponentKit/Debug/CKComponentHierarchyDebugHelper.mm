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

@implementation CKComponentHierarchyDebugHelper

+ (NSString *)componentHierarchyDescription
{
  UIWindow *window = [[UIApplication sharedApplication] keyWindow];
  return [[self class] componentHierarchyDescriptionForView:window searchUpwards:NO];
}

+ (NSString *)componentHierarchyDescriptionForView:(UIView *)view searchUpwards:(BOOL)upwards
{
  if (upwards) {
    while (view && !view.ck_componentLifecycleManager) {
      view = view.superview;
    }

    if (!view) {
      return @"Didn't find any components";
    }
  }
  return (CKRecursiveComponentHierarchyDescription(view) ?: @"Didn't find any components");
}

static NSString *CKRecursiveComponentHierarchyDescription(UIView *view)
{
  if (view.ck_componentLifecycleManager) {
    return [NSString stringWithFormat:@"For View: %@\n%@", view, CKComponentHierarchyDescription(view)];
  } else {
    NSMutableArray *array = [NSMutableArray array];
    for (UIView *subview in view.subviews) {
      NSString *subviewDescription = CKRecursiveComponentHierarchyDescription(subview);
      if (subviewDescription) {
        [array addObject:subviewDescription];
      }
    }
    return array.count ? [array componentsJoinedByString:@"\n\n"] : nil;
  }
}

static NSString *CKComponentHierarchyDescription(UIView *view)
{
  CKComponentLayout layout = [view.ck_componentLifecycleManager state].layout;
  NSMutableArray *description = [[NSMutableArray alloc] init];
  CKBuildComponentHierarchyDescription(description, layout, {0, 0}, @"");
  return [description componentsJoinedByString:@"\n"];
}

static void CKBuildComponentHierarchyDescription(NSMutableArray *result, const CKComponentLayout &layout, CGPoint position, NSString *prefix)
{
  [result addObject:[NSString stringWithFormat:@"%@%@, Position: %@, Size: %@",
                     prefix,
                     layout.component,
                     NSStringFromCGPoint(position),
                     NSStringFromCGSize(layout.size)]];

  for (const auto &child : *layout.children) {
    CKBuildComponentHierarchyDescription(result,
                                         child.layout,
                                         child.position,
                                         [NSString stringWithFormat:@"| %@", prefix]);
  }
}

@end
