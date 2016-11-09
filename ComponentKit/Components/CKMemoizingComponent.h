/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKCompositeComponent.h>

/**
 A memoizing component should be present in the component hierarchy above components that wish to use memoization. It
 configures thread-local state so that memoization of components and component layouts can be successful. If a
 memoizing component is not present, memoization operations will silently fail and components will be rebuilt and
 re-laid out on every call.
 */
@interface CKMemoizingComponent : CKComponent

+ (instancetype)newWithComponentBlock:(CKComponent *(^)())block;

@end
