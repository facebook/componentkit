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

#import "CKComponent.h"

static NSString *componentDescriptionOrClass(CKComponent *component)
{
  return [component description] ?: NSStringFromClass([component class]);
}

NSString *CKComponentBacktraceDescription(NSArray<CKComponent *> *componentBacktrace) noexcept
{
  NSMutableString *const description = [NSMutableString string];
  [componentBacktrace enumerateObjectsWithOptions:NSEnumerationReverse
                                       usingBlock:^(CKComponent * _Nonnull component, NSUInteger index, BOOL * _Nonnull stop) {
                                         const NSInteger depth = componentBacktrace.count - index - 1;
                                         if (depth != 0) {
                                           [description appendString:@"\n"];
                                         }
                                         [description appendString:[@"" stringByPaddingToLength:depth withString:@" " startingAtIndex:0]];
                                         [description appendString:componentDescriptionOrClass(component)];
                                       }];
  return description;
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
