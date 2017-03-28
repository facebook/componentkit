//
//  CKComponentControllerAppearanceEvents.h
//  ComponentKit
//
//  Created by Oliver Rickard on 3/27/17.
//
//

#import <Foundation/Foundation.h>

#import <ComponentKit/CKComponentScopeRoot.h>

BOOL CKComponentControllerAppearanceEventPredicate(id<CKScopedComponentController> controller);
BOOL CKComponentControllerDisappearanceEventPredicate(id<CKScopedComponentController> controller);

void CKComponentControllerAnnounceAppearance(CKComponentScopeRoot *scopeRoot);
void CKComponentControllerAnnounceDisappearance(CKComponentScopeRoot *scopeRoot);
