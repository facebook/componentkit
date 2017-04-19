/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentBoundsAnimationPredicates.h"

#import "CKComponentInternal.h"
#import "CKComponentSubclass.h"
#import "CKInternalHelpers.h"

BOOL CKComponentBoundsAnimationPredicate(id<CKScopedComponent> component)
{
  return CKSubclassOverridesSelector([CKComponent class], [component class], @selector(boundsAnimationFromPreviousComponent:));
}

CKComponentBoundsAnimation CKComponentBoundsAnimationFromPreviousScopeRoot(CKComponentScopeRoot *newRoot, CKComponentScopeRoot *previousRoot)
{
  NSMapTable *const scopeFrameTokenToOldComponent = [NSMapTable strongToStrongObjectsMapTable];
  [previousRoot
   enumerateComponentsMatchingPredicate:&CKComponentBoundsAnimationPredicate
   block:^(id<CKScopedComponent> component) {
     CKComponent *oldComponent = (CKComponent *)component;
     id scopeFrameToken = [oldComponent scopeFrameToken];
     if (scopeFrameToken) {
       [scopeFrameTokenToOldComponent setObject:oldComponent forKey:scopeFrameToken];
     }
   }];

  __block CKComponentBoundsAnimation boundsAnimation {};
  [newRoot
   enumerateComponentsMatchingPredicate:&CKComponentBoundsAnimationPredicate
   block:^(id<CKScopedComponent> component) {
     CKComponent *newComponent = (CKComponent *)component;
     id scopeFrameToken = [newComponent scopeFrameToken];
     if (scopeFrameToken) {
       CKComponent *oldComponent = [scopeFrameTokenToOldComponent objectForKey:scopeFrameToken];
       if (oldComponent) {
         const CKComponentBoundsAnimation ba = [newComponent boundsAnimationFromPreviousComponent:oldComponent];
         if (ba.duration != 0) {
           boundsAnimation = ba;
         }
       }
     }
   }];
  return boundsAnimation;
}
