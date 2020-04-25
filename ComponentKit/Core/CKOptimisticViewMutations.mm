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
#import <ComponentKit/CKGlobalConfig.h>
#import <ComponentKit/ComponentUtilities.h>
#import <ComponentKit/ComponentViewManager.h>

void CKPerformOptimisticViewMutation(UIView *view,
                                     CKOptimisticViewMutationGetter getter,
                                     CKOptimisticViewMutationSetter setter,
                                     id value,
                                     id context)
{
  CKPerformOptimisticViewMutation(view, 0, getter, setter, value, context);
}

void CKPerformOptimisticViewMutation(UIView *view,
                                     CFTimeInterval persistTime,
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

  if (CKReadGlobalConfig().useNewStyleOptimisticMutations) {
    __block int loadCount = 0;
    __block id oldValue = nil;
    __block CKOptimisticMutationToken token = CKOptimisticMutationTokenNull;
    
    auto undo = ^(UIView *v) {
      if (!CKObjectIsEqual(getter(v, context), oldValue)) {
        setter(v, oldValue, context);
        CKCAssert(CKObjectIsEqual(getter(v, context), oldValue), @"Setter failed to undo to old value");
      }
    };
    
    auto load = persistTime == 0 ?
      ^(UIView *v) {
        if (loadCount++ == 0) {
          oldValue = getter(view, context);
        } else {
          oldValue = getter(view, context);
          CK::Component::AttributeApplicator::removeOptimisticViewMutation(token);
          token = CKOptimisticMutationTokenNull;
        }
      } :
      ^(UIView *v) {
        oldValue = getter(view, context);
      };
    
    auto apply = ^(UIView *v) {
      if (!CKObjectIsEqual(getter(v, context), value)) {
        setter(v, value, context);
        CKCAssert(CKObjectIsEqual(getter(view, context), value), @"Setter failed to redo to new value");
      }
    };
    
    if (persistTime != 0) {
      const auto dispatchTime = dispatch_time(DISPATCH_TIME_NOW, int64_t(NSEC_PER_SEC * persistTime));
      
      dispatch_after(dispatchTime, dispatch_get_main_queue(), ^{
        CK::Component::AttributeApplicator::removeOptimisticViewMutation(token);
        token = CKOptimisticMutationTokenNull;
      });
    }
  
    token = CK::Component::AttributeApplicator::addOptimisticViewMutation(view, undo, apply, load);
  } else {
    id oldValue = getter(view, context);
    CK::Component::AttributeApplicator::addOptimisticViewMutationTeardown_Old(view, ^(UIView *v) {
      setter(v, oldValue, context);
      CKCAssert(CKObjectIsEqual(getter(v, context), oldValue), @"Setter failed to restore old value");
    });
    setter(view, value, context);
    CKCAssert(CKObjectIsEqual(getter(view, context), value), @"Setter failed to apply new value");
  }
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
  CKPerformOptimisticViewMutation(view, 0.0, keyPath, value);
}

void CKPerformOptimisticViewMutation(UIView *view, CFTimeInterval persistTime, NSString *keyPath, id value)
{
  CKCAssertNotNil(keyPath, @"Must have a non-nil keyPath");
  CKPerformOptimisticViewMutation(view, persistTime, &keyPathGetter, &keyPathSetter, value, keyPath);
}
