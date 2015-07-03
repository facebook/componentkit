/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKComponentScopeRoot.h>

@class CKComponentController;
@class CKComponent;

@interface CKComponentScopeRoot ()

/**
 Mutates the root to add references to controllers that override any "announceable events."
 This must only be called during the process of creating the root. It exists only for efficiency reasons.
 */
- (void)registerAnnounceableEventsForController:(CKComponentController *)controller;

/**
 Mutates the root to add a reference to a component that overrides boundsAnimationFromPreviousComponent:.
 This must only be called during the process of creating the root. It exists only for efficiency reasons.
 */
- (void)registerBoundsAnimationComponent:(CKComponent *)component;

@end
