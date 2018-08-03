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
#import <ComponentKit/CKBuildComponent.h>
#import <ComponentKit/CKComponentScopeTypes.h>

@class CKComponent;
@class CKComponentScopeRoot;

@protocol CKAnalyticsListener <NSObject>

/**
 Called before/after building component tree

 @param scopRoot Scope root for component tree. Use that to identify tree between will/didBuild
 @param component Root component for created tree
 */
- (void)willBuildComponentTreeWithScopeRoot:(CKComponentScopeRoot *)scopeRoot buildTrigger:(BuildTrigger)buildTrigger;
- (void)didBuildComponentTreeWithScopeRoot:(CKComponentScopeRoot *)scopeRoot component:(CKComponent *)component;

/**
 Called before/after mounting component tree

 @param component Root component for mounted tree
 */

- (void)willMountComponentTreeWithRootComponent:(CKComponent *)component;
- (void)didMountComponentTreeWithRootComponent:(CKComponent *)component;

/**
 Called before/after component tree layout

 @param component Root component for laid out tree

 @discussion Please not that this callback can be called on the same component from different threads in undefined order, for instance:
             ThreadA, willLayout Component1
             ThreadB, willLayout Component1
             ThreadA, didLayout Component1
             ThreadB, didLayout Component1
             To identify matching will/didLayout events between callbacks, please use Thread id and Component id
 */

- (void)willLayoutComponentTreeWithRootComponent:(CKComponent *)component;
- (void)didLayoutComponentTreeWithRootComponent:(CKComponent *)component;

@end
