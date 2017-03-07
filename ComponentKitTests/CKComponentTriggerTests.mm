/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <XCTest/XCTest.h>

#import <ComponentKit/CKComponentTrigger.h>
#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKComponentController.h>
#import <ComponentKit/CKComponentSubclass.h>

@interface CKTriggerTestComponentController : CKComponentController
- (void)triggerMethodOnController;
@property (nonatomic, assign, readonly) BOOL invokedTrigger;
@end

@interface CKTriggerTestComponent : CKComponent

+ (instancetype)newWithUnTypedTrigger:(const CKComponentTrigger &)trigger;

+ (instancetype)newWithBoolTrigger:(const CKTypedComponentTrigger<BOOL> &)trigger;

+ (instancetype)newWithControllerTrigger:(const CKComponentTrigger &)trigger;

@property (nonatomic, assign, readonly) BOOL invokedUnTypedTrigger;
@property (nonatomic, assign, readonly) BOOL invokedBoolTrigger;

@end

@implementation CKTriggerTestComponent

+ (instancetype)newWithUnTypedTrigger:(const CKComponentTrigger &)trigger
{
  CKComponentScope scope(self);
  trigger.resolve(scope, @selector(invokedUnTypedTriggerWithSender:));
  return [super newWithView:{} size:{}];
}

- (void)invokedUnTypedTriggerWithSender:(CKComponent *)sender
{
  _invokedUnTypedTrigger = YES;
}

+ (instancetype)newWithBoolTrigger:(const CKTypedComponentTrigger<BOOL> &)trigger
{
  CKComponentScope scope(self);
  trigger.resolve(scope, @selector(invokedBoolTriggerWithSender:value:));
  return [super newWithView:{} size:{}];
}

- (void)invokedBoolTriggerWithSender:(CKComponent *)sender value:(BOOL)value
{
  _invokedBoolTrigger = YES;
}

+ (instancetype)newWithControllerTrigger:(const CKComponentTrigger &)trigger
{
  CKComponentScope scope(self);
  trigger.resolve(scope, @selector(triggerMethodOnController));
  return [super newWithView:{} size:{}];
}

@end

@implementation CKTriggerTestComponentController

- (void)triggerMethodOnController
{
  _invokedTrigger = YES;
}

@end

@interface CKComponentTriggerTests : XCTestCase

@end

@implementation CKComponentTriggerTests

- (void)test_unacquiredTrigger_noOpsOnInvocation
{
  CKTypedComponentTrigger<BOOL> trigger;
  trigger.invoke(nil, YES);
}

- (void)test_acquiredTrigger_invokesMethod_onInvocation
{
  CKComponentTrigger trigger = CKComponentTriggerAcquire();

  CKBuildComponentResult result = CKBuildComponent([CKComponentScopeRoot rootWithListener:nil], {}, ^CKComponent *{
    return [CKTriggerTestComponent newWithUnTypedTrigger:trigger];
  });

  CKTriggerTestComponent *c = (CKTriggerTestComponent *)result.component;

  trigger.invoke(nil);

  XCTAssert(c.invokedUnTypedTrigger);
}

- (void)test_acquiredTrigger_invokesTypedMethod_onInvocation
{
  CKTypedComponentTrigger<BOOL> trigger = CKComponentTriggerAcquire<BOOL>();

  CKBuildComponentResult result = CKBuildComponent([CKComponentScopeRoot rootWithListener:nil], {}, ^CKComponent *{
    return [CKTriggerTestComponent newWithBoolTrigger:trigger];
  });

  CKTriggerTestComponent *c = (CKTriggerTestComponent *)result.component;

  trigger.invoke(nil, YES);

  XCTAssert(c.invokedBoolTrigger);
}

- (void)test_acquiredTrigger_invokesControllerMethod_onInvocation
{
  CKComponentTrigger trigger = CKComponentTriggerAcquire();

  CKBuildComponentResult result = CKBuildComponent([CKComponentScopeRoot rootWithListener:nil], {}, ^CKComponent *{
    return [CKTriggerTestComponent newWithControllerTrigger:trigger];
  });

  CKTriggerTestComponent *c = (CKTriggerTestComponent *)result.component;
  CKTriggerTestComponentController *controller = (CKTriggerTestComponentController *)c.controller;

  trigger.invoke(nil);

  XCTAssert(controller.invokedTrigger);
}

@end
