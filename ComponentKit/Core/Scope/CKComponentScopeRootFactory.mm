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
#import "CKComponentEvents.h"

CKComponentScopeRoot *CKComponentScopeRootWithDefaultPredicates(id<CKComponentStateListener> stateListener,
                                                                id<CKAnalyticsListener> analyticsListener,
                                                                BOOL includeAnimationPredicates)
{
  auto componentPredicates = std::unordered_set<CKComponentScopePredicate> {
    &CKComponentBoundsAnimationPredicate,
    &CKComponentDidPrepareLayoutForComponentToControllerPredicate,
  };
  if (includeAnimationPredicates) {
    componentPredicates.insert(&CKComponentHasAnimationsOnInitialMountPredicate);
    componentPredicates.insert(&CKComponentHasAnimationsFromPreviousComponentPredicate);
  }
  return [CKComponentScopeRoot
          rootWithListener:stateListener
          analyticsListener:analyticsListener
          componentPredicates:componentPredicates
          componentControllerPredicates:{
            &CKComponentControllerAppearanceEventPredicate,
            &CKComponentControllerDisappearanceEventPredicate,
            &CKComponentControllerInvalidateEventPredicate
          }];
}

CKComponentScopeRoot *CKComponentScopeRootWithPredicates(id<CKComponentStateListener> stateListener,
                                                         id<CKAnalyticsListener> analyticsListener,
                                                         const std::unordered_set<CKComponentScopePredicate> &componentPredicates,
                                                         const std::unordered_set<CKComponentControllerScopePredicate> &componentControllerPredicates,
                                                         BOOL includeAnimationPredicates)
{
  std::unordered_set<CKComponentScopePredicate> componentPredicatesUnion = {
    &CKComponentBoundsAnimationPredicate,
    &CKComponentDidPrepareLayoutForComponentToControllerPredicate
  };

  std::unordered_set<CKComponentControllerScopePredicate> componentControllerPredicatesUnion = {
    &CKComponentControllerAppearanceEventPredicate,
    &CKComponentControllerDisappearanceEventPredicate,
    &CKComponentControllerInvalidateEventPredicate
  };

  componentPredicatesUnion.insert(componentPredicates.begin(), componentPredicates.end());
  if (includeAnimationPredicates) {
    componentPredicatesUnion.insert(&CKComponentHasAnimationsOnInitialMountPredicate);
    componentPredicatesUnion.insert(&CKComponentHasAnimationsFromPreviousComponentPredicate);
  }
  componentControllerPredicatesUnion.insert(componentControllerPredicates.begin(), componentControllerPredicates.end());

  return [CKComponentScopeRoot
          rootWithListener:stateListener
          analyticsListener:analyticsListener
          componentPredicates:componentPredicatesUnion
          componentControllerPredicates:componentControllerPredicatesUnion];
}
