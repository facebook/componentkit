/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentDescriptionHelper.h"

#import <RenderCore/CKMountable.h>

static NSString *componentDescriptionOrClass(id<CKMountable> component)
{
  return [component description] ?: NSStringFromClass([component class]);
}

static NSString *CKComponentBacktraceDescription(NSArray<id<CKMountable>> *componentBacktrace, BOOL nested, BOOL compactDescription) noexcept
{
  NSMutableString *const description = [NSMutableString string];
    for (NSInteger index = [componentBacktrace count] - 1; index >= 0; index--) {
      const NSInteger depth = componentBacktrace.count - index - 1;
      if (depth != 0) {
        [description appendString:@"\n"];
      }
      const auto component = componentBacktrace[index];
      if (nested) {
        [description appendString:[@"" stringByPaddingToLength:depth withString:@" " startingAtIndex:0]];
      }
      NSString *componentDescription = compactDescription ? CKComponentCompactDescription(component) : componentDescriptionOrClass(component);
      [description appendString:componentDescription];
    }
    return description;
}

NSString *CKComponentCompactDescription(id<CKMountable> component)
{
  return component.className ?: NSStringFromClass([component class]);
}

NSString *CKComponentBacktraceDescription(NSArray<id<CKMountable>> *componentBacktrace) noexcept
{
  return CKComponentBacktraceDescription(componentBacktrace, YES, NO);
}

NSString *CKComponentBacktraceStackDescription(NSArray<id<CKMountable>> *componentBacktrace) noexcept
{
  return CKComponentBacktraceDescription(componentBacktrace, NO, YES);
}

NSString *CKComponentChildrenDescription(std::shared_ptr<const std::vector<CKComponentLayoutChild>> children) noexcept
{
  NSMutableString *const description = [NSMutableString string];
  for (auto childIter = children->begin(); childIter != children->end(); childIter++) {
    if (childIter != children->begin()) {
      [description appendString:@"\n"];
    }
    id<CKMountable> child = childIter->layout.component;
    if (child) {
      [description appendString:componentDescriptionOrClass(child)];
    }
  }
  return description;
}

NSString *CKComponentDescriptionWithChildren(NSString *description, NSArray *children)
{
  NSMutableString *result = [description mutableCopy];
  for (id childComponent in children) {
    NSString *nested = [childComponent description];
    __block NSUInteger index = 0;
    [nested enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
      [result appendString:(index++ ? @"\n    " : @"\n  - ")];
      [result appendString:line];
    }];
  }
  return result;
}

NSArray<id<CKMountable>> *CKComponentGenerateBacktrace(id<CKMountable> component)
{
  NSMutableArray<id<CKMountable>> *const componentBacktrace = [NSMutableArray arrayWithObject:component];
  while ([componentBacktrace lastObject]
         && [componentBacktrace lastObject].mountInfo.supercomponent) {
    [componentBacktrace addObject:[componentBacktrace lastObject].mountInfo.supercomponent];
  }
  return componentBacktrace;
}
