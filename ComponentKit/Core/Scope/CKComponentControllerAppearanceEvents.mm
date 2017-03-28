//
//  CKComponentControllerAppearanceEvents.m
//  ComponentKit
//
//  Created by Oliver Rickard on 3/27/17.
//
//

#import "CKComponentControllerAppearanceEvents.h"

#import "CKInternalHelpers.h"
#import "CKComponentController.h"
#import "CKScopedComponentController.h"

BOOL CKComponentControllerAppearanceEventPredicate(id<CKScopedComponentController> controller)
{
  return CKSubclassOverridesSelector([CKComponentController class], [controller class], @selector(componentTreeWillAppear));
}

BOOL CKComponentControllerDisappearanceEventPredicate(id<CKScopedComponentController> controller)
{
  return CKSubclassOverridesSelector([CKComponentController class], [controller class], @selector(componentTreeDidDisappear));
}

void CKComponentControllerAnnounceAppearance(CKComponentScopeRoot *scopeRoot)
{
  [scopeRoot enumerateComponentControllersMatchingPredicate:&CKComponentControllerAppearanceEventPredicate block:^(id<CKScopedComponentController> scopedController) {
    CKComponentController *controller = (CKComponentController *)scopedController;
    [controller componentTreeWillAppear];
  }];
}

void CKComponentControllerAnnounceDisappearance(CKComponentScopeRoot *scopeRoot)
{
  [scopeRoot enumerateComponentControllersMatchingPredicate:&CKComponentControllerDisappearanceEventPredicate block:^(id<CKScopedComponentController> scopedController) {
    CKComponentController *controller = (CKComponentController *)scopedController;
    [controller componentTreeDidDisappear];
  }];
}
