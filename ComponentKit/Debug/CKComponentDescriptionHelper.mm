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

#import <ComponentKit/CKStatelessComponent.h>

static NSString *componentDescriptionOrClass(CKComponent *component)
{
  return [component description] ?: NSStringFromClass([component class]);
}

/* This functions prints only the class, or in case of Stateless component, the description that will help us identify the Spec */
static NSString *componentCompactDescription(CKComponent *component)
{
  return [component isMemberOfClass:[CKStatelessComponent class]] ? [component description]: NSStringFromClass([component class]);
}


static NSString *CKComponentBacktraceDescription(NSArray<CKComponent *> *componentBacktrace, BOOL nested, BOOL compactDescription) noexcept
{
  NSMutableString *const description = [NSMutableString string];
  [componentBacktrace enumerateObjectsWithOptions:NSEnumerationReverse
                                       usingBlock:^(CKComponent * _Nonnull component, NSUInteger index, BOOL * _Nonnull stop) {
                                         const NSInteger depth = componentBacktrace.count - index - 1;
                                         if (depth != 0) {
                                           [description appendString:@"\n"];
                                         }
                                         if (nested) {
                                           [description appendString:[@"" stringByPaddingToLength:depth withString:@" " startingAtIndex:0]];
                                         }
                                         NSString *componentDescription = compactDescription ? componentCompactDescription(component) : componentDescriptionOrClass(component);
                                         [description appendString:componentDescription];
                                       }];
  return description;
}

NSString *CKComponentBacktraceDescription(NSArray<CKComponent *> *componentBacktrace) noexcept
{
  return CKComponentBacktraceDescription(componentBacktrace, YES, NO);
}

NSString *CKComponentBacktraceStackDescription(NSArray<CKComponent *> *componentBacktrace) noexcept
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
    CKComponent *child = childIter->layout.component;
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
