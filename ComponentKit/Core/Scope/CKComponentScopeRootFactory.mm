//
//  CKComponentScopeRootFactory.m
//  ComponentKit
//
//  Created by Oliver Rickard on 3/28/17.
//
//

#import "CKComponentScopeRootFactory.h"

#import "CKComponentControllerAppearanceEvents.h"
#import "CKComponentBoundsAnimationPredicates.h"

CKComponentScopeRoot *CKComponentScopeRootWithListener(id<CKComponentStateListener> listener)
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
