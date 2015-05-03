/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKOptimisticViewMutations.h"

#import <objc/runtime.h>

#import <ComponentKit/CKAssert.h>

const char kOptimisticViewMutationOriginalValuesAssociatedObjectKey = ' ';

void CKPerformOptimisticViewMutation(UIView *view, NSString *keyPath, id value)
{
  CKCAssertMainThread();
  CKCAssertNotNil(view, @"Must have a non-nil view");
  CKCAssertNotNil(keyPath, @"Must have a non-nil keyPath");

  NSMutableDictionary *originalValues = objc_getAssociatedObject(view, &kOptimisticViewMutationOriginalValuesAssociatedObjectKey);
  if (originalValues == nil) {
    originalValues = [NSMutableDictionary dictionary];
    objc_setAssociatedObject(view, &kOptimisticViewMutationOriginalValuesAssociatedObjectKey, originalValues, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }

  if (originalValues[keyPath] == nil) {
    // First mutation for this keypath; store the old value.
    originalValues[keyPath] = [view valueForKeyPath:keyPath] ?: [NSNull null];
  }

  [view setValue:value forKeyPath:keyPath];
}

void CKResetOptimisticMutationsForView(UIView *view)
{
  NSDictionary *originalValues = objc_getAssociatedObject(view, &kOptimisticViewMutationOriginalValuesAssociatedObjectKey);
  if (originalValues) {
    for (NSString *keyPath in originalValues) {
      id value = originalValues[keyPath];
      [view setValue:(value == [NSNull null] ? nil : value) forKeyPath:keyPath];
    }
    objc_setAssociatedObject(view, &kOptimisticViewMutationOriginalValuesAssociatedObjectKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
}
