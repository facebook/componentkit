/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

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
