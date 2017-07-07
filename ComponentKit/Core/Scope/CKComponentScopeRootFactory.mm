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

#import "CKComponentControllerAppearanceEvents.h"
#import "CKComponentBoundsAnimationPredicates.h"

CKComponentScopeRoot *CKComponentScopeRootWithDefaultPredicates(id<CKComponentStateListener> listener)
{
  return [CKComponentScopeRoot
          rootWithListener:listener
          componentPredicates:{
            &CKComponentBoundsAnimationPredicate
          }
          componentControllerPredicates:{
            &CKComponentControllerAppearanceEventPredicate,
            &CKComponentControllerDisappearanceEventPredicate
          }];
}

CKComponentScopeRoot *CKComponentScopeRootWithPredicates(id<CKComponentStateListener> listener,
                                                         const std::unordered_set<CKComponentScopePredicate> &componentPredicates,
                                                         const std::unordered_set<CKComponentControllerScopePredicate> &componentControllerPredicates)
{
  std::unordered_set<CKComponentScopePredicate> componentPredicatesUnion = {
    &CKComponentBoundsAnimationPredicate
  };

  std::unordered_set<CKComponentControllerScopePredicate> componentControllerPredicatesUnion = {
    &CKComponentControllerAppearanceEventPredicate,
    &CKComponentControllerDisappearanceEventPredicate
  };

  componentPredicatesUnion.insert(componentPredicates.begin(), componentPredicates.end());
  componentControllerPredicatesUnion.insert(componentControllerPredicates.begin(), componentControllerPredicates.end());

  return [CKComponentScopeRoot
          rootWithListener:listener
          componentPredicates:componentPredicatesUnion
          componentControllerPredicates:componentControllerPredicatesUnion];
}
