//
//  CKBuildComponent.m
//  ComponentKit
//
//  Created by Oliver Rickard on 3/28/17.
//
//

#import "CKBuildComponent.h"

#import "CKComponentBoundsAnimation.h"
#import "CKComponentBoundsAnimationPredicates.h"
#import "CKComponentInternal.h"
#import "CKComponentScopeRoot.h"
#import "CKComponentSubclass.h"
#import "CKThreadLocalComponentScope.h"

static CKComponentBoundsAnimation boundsAnimationFromPreviousScopeRoot(CKComponentScopeRoot *newRoot, CKComponentScopeRoot *previousRoot)
{
  NSMapTable *scopeFrameTokenToOldComponent = [NSMapTable strongToStrongObjectsMapTable];
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

CKBuildComponentResult CKBuildComponent(CKComponentScopeRoot *previousRoot,
                                        const CKComponentStateUpdateMap &stateUpdates,
                                        CKComponent *(^function)(void))
{
  CKThreadLocalComponentScope threadScope(previousRoot, stateUpdates);
  // Order of operations matters, so first store into locals and then return a struct.
  CKComponent *component = function();
  return {
    .component = component,
    .scopeRoot = threadScope.newScopeRoot,
    .boundsAnimation = boundsAnimationFromPreviousScopeRoot(threadScope.newScopeRoot, previousRoot)
  };
}

