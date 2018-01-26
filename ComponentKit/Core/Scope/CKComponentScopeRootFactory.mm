/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentScopeRootFactory.h"

#import "CKComponentControllerEvents.h"
#import "CKComponentBoundsAnimationPredicates.h"

CKComponentScopeRoot *CKComponentScopeRootWithDefaultPredicates(id<CKComponentStateListener> listener)
{
  return CKComponentScopeRootWithDefaultPredicates(listener, nil);
}

CKComponentScopeRoot *CKComponentScopeRootWithDefaultPredicates(id<CKComponentStateListener> listener, id<CKAnalyticsListener> analyticsListener)
{
  return [CKComponentScopeRoot
          rootWithListener:listener
          analyticsListener:analyticsListener
          componentPredicates:{
            &CKComponentBoundsAnimationPredicate
          }
          componentControllerPredicates:{
            &CKComponentControllerAppearanceEventPredicate,
            &CKComponentControllerDisappearanceEventPredicate,
            &CKComponentControllerInvalidateEventPredicate
          }];
}

CKComponentScopeRoot *CKComponentScopeRootWithPredicates(id<CKComponentStateListener> listener,
                                                         id<CKAnalyticsListener> analyticsListener,
                                                         const std::unordered_set<CKComponentScopePredicate> &componentPredicates,
                                                         const std::unordered_set<CKComponentControllerScopePredicate> &componentControllerPredicates)
{
  std::unordered_set<CKComponentScopePredicate> componentPredicatesUnion = {
    &CKComponentBoundsAnimationPredicate
  };

  std::unordered_set<CKComponentControllerScopePredicate> componentControllerPredicatesUnion = {
    &CKComponentControllerAppearanceEventPredicate,
    &CKComponentControllerDisappearanceEventPredicate,
    &CKComponentControllerInvalidateEventPredicate
  };

  componentPredicatesUnion.insert(componentPredicates.begin(), componentPredicates.end());
  componentControllerPredicatesUnion.insert(componentControllerPredicates.begin(), componentControllerPredicates.end());

  return [CKComponentScopeRoot
          rootWithListener:listener
          analyticsListener:analyticsListener
          componentPredicates:componentPredicatesUnion
          componentControllerPredicates:componentControllerPredicatesUnion];
}
