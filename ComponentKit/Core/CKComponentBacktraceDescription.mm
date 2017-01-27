/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentBacktraceDescription.h"

#import "CKComponent.h"

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
                                         [description appendString:NSStringFromClass([component class])];
                                         [description appendString:@": "];
                                         [description appendString:[component description]];
                                       }];
  return description;
}
