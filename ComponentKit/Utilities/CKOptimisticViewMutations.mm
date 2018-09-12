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

#import <ComponentKit/CKAssert.h>
#import <ComponentKit/ComponentUtilities.h>
#import <ComponentKit/ComponentViewManager.h>

void CKPerformOptimisticViewMutation(UIView *view,
                                     CKOptimisticViewMutationGetter getter,
                                     CKOptimisticViewMutationSetter setter,
                                     id value,
                                     id context)
{
  CKCAssertMainThread();
  CKCAssertNotNil(view, @"Must have a non-nil view");
  CKCAssertNotNil(getter, @"Must have a non-nil getter");
  CKCAssertNotNil(setter, @"Must have a non-nil setter");
  if (view == nil || getter == nil || setter == nil) {
    return;
  }

  id oldValue = getter(view, context);
  CK::Component::AttributeApplicator::addOptimisticViewMutationTeardown(view, ^(UIView *v) {
    setter(v, oldValue, context);
    CKCAssert(CKObjectIsEqual(getter(v, context), oldValue), @"Setter failed to restore old value");
  });
  setter(view, value, context);
  CKCAssert(CKObjectIsEqual(getter(view, context), value), @"Setter failed to apply new value");
}

static id keyPathGetter(UIView *view, id keyPath)
{
  return [view valueForKeyPath:keyPath];
}

static void keyPathSetter(UIView *view, id value, id keyPath)
{
  [view setValue:value forKey:keyPath];
}

void CKPerformOptimisticViewMutation(UIView *view, NSString *keyPath, id value)
{
  CKCAssertNotNil(keyPath, @"Must have a non-nil keyPath");
  CKPerformOptimisticViewMutation(view, &keyPathGetter, &keyPathSetter, value, keyPath);
}
