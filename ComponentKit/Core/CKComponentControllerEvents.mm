/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentControllerEvents.h"

#import <ComponentKit/CKInternalHelpers.h>

#import "CKComponentController.h"
#import "CKComponentControllerProtocol.h"

BOOL CKComponentControllerAppearanceEventPredicate(id<CKComponentControllerProtocol> controller)
{
  return CKSubclassOverridesInstanceMethod([CKComponentController class], [controller class], @selector(componentTreeWillAppear));
}

BOOL CKComponentControllerDisappearanceEventPredicate(id<CKComponentControllerProtocol> controller)
{
  return CKSubclassOverridesInstanceMethod([CKComponentController class], [controller class], @selector(componentTreeDidDisappear));
}

BOOL CKComponentControllerInitializeEventPredicate(id<CKComponentControllerProtocol> controller)
{
  return CKSubclassOverridesInstanceMethod([CKComponentController class], [controller class], @selector(didInit));
}

BOOL CKComponentControllerInvalidateEventPredicate(id<CKComponentControllerProtocol> controller)
{
  return CKSubclassOverridesInstanceMethod([CKComponentController class], [controller class], @selector(invalidateController));
}

void CKComponentScopeRootAnnounceControllerAppearance(CKComponentScopeRoot *scopeRoot)
{
  [scopeRoot enumerateComponentControllersMatchingPredicate:&CKComponentControllerAppearanceEventPredicate block:^(id<CKComponentControllerProtocol> scopedController) {
    CKComponentController *controller = (CKComponentController *)scopedController;
    [controller componentTreeWillAppear];
  }];
}

void CKComponentScopeRootAnnounceControllerDisappearance(CKComponentScopeRoot *scopeRoot)
{
  [scopeRoot enumerateComponentControllersMatchingPredicate:&CKComponentControllerDisappearanceEventPredicate block:^(id<CKComponentControllerProtocol> scopedController) {
    CKComponentController *controller = (CKComponentController *)scopedController;
    [controller componentTreeDidDisappear];
  }];
}

void CKComponentScopeRootAnnounceControllerInitialization(CKComponentScopeRoot *scopeRoot)
{
  [scopeRoot enumerateComponentControllersMatchingPredicate:&CKComponentControllerInitializeEventPredicate block:^(id<CKComponentControllerProtocol> scopedController) {
    CKComponentController *controller = (CKComponentController *)scopedController;
    [controller didInit];
  }];
}

void CKComponentScopeRootAnnounceControllerInvalidation(CKComponentScopeRoot *scopeRoot)
{
  [scopeRoot enumerateComponentControllersMatchingPredicate:&CKComponentControllerInvalidateEventPredicate block:^(id<CKComponentControllerProtocol> scopedController) {
    CKComponentController *controller = (CKComponentController *)scopedController;
    [controller invalidateController];
  }];
}
