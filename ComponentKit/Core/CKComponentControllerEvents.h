/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <Foundation/Foundation.h>

#import <ComponentKit/CKComponentScopeRoot.h>

/**
 These predicates are passed to the scope root in its initializer so that they can be run on every component
 controller as they are initialized to identify which component controllers respond to appearance events. The results of
 the predicate are cached, which allows us to avoid traversing the full component hierarchy every time a component
 appears on the screen.
 
 You should never use these predicates directly. They are built to work with CKComponentScopeRoot.
 */
#if !defined(NO_PROTOCOLS_IN_OBJCPP)
BOOL CKComponentControllerAppearanceEventPredicate(id<CKComponentControllerProtocol> controller);
BOOL CKComponentControllerDisappearanceEventPredicate(id<CKComponentControllerProtocol> controller);
BOOL CKComponentControllerInvalidateEventPredicate(id<CKComponentControllerProtocol> controller);
#else
BOOL CKComponentControllerAppearanceEventPredicate(id controller);
BOOL CKComponentControllerDisappearanceEventPredicate(id controller);
BOOL CKComponentControllerInvalidateEventPredicate(id controller);
#endif

/**
 Called by the infrastructure when cells appear or disappear. These functions announce to all component controllers
 in the hierarchy that matched the above predicates.
 */
void CKComponentScopeRootAnnounceControllerAppearance(CKComponentScopeRoot *scopeRoot);
void CKComponentScopeRootAnnounceControllerDisappearance(CKComponentScopeRoot *scopeRoot);
void CKComponentScopeRootAnnounceControllerInvalidation(CKComponentScopeRoot *scopeRoot);
