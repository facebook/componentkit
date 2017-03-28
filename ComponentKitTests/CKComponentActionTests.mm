/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <ComponentKitTestHelpers/CKTestActionComponent.h>

#import <ComponentKit/CKComponentAction.h>
#import <ComponentKit/CKCompositeComponent.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKComponentController.h>

@interface CKTestScopeActionComponent : CKComponent

+ (instancetype)newWithBlock:(void(^)(CKComponent *sender, id context))block;

- (void)triggerAction:(id)context;

@end

@implementation CKTestScopeActionComponent
{
  CKTypedComponentAction<id> _action;
  void (^_block)(CKComponent *, id);
}

+ (instancetype)newWithBlock:(void (^)(CKComponent *, id))block
{
  CKComponentScope scope(self);

  CKTestScopeActionComponent *c = [super newWithView:{} size:{}];
  if (c) {
    c->_action = {scope, @selector(actionMethod:context:)};
    c->_block = block;
  }
  return c;
}

- (void)actionMethod:(CKComponent *)sender context:(id)context
{
  _block(sender, context);
}

- (void)triggerAction:(id)context
{
  _action.send(self, context);
}

@end

@interface CKTestControllerScopeActionComponent : CKComponent

+ (instancetype)newWithBlock:(void(^)(CKComponent *sender, id context))block;

- (void(^)(CKComponent *sender, id context))block;

- (void)triggerAction:(id)context;

@end

@implementation CKTestControllerScopeActionComponent
{
  CKTypedComponentAction<id> _action;
  void (^_block)(CKComponent *, id);
}

+ (instancetype)newWithBlock:(void (^)(CKComponent *, id))block
{
  CKComponentScope scope(self);

  CKTestControllerScopeActionComponent *c = [super newWithView:{} size:{}];
  if (c) {
    c->_action = {scope, @selector(actionMethod:context:)};
    c->_block = block;
  }
  return c;
}

- (void (^)(CKComponent *, id))block
{
  return _block;
}

- (void)triggerAction:(id)context
{
  _action.send(self, context);
}

@end

@interface CKTestObjectTarget : NSObject

- (void)someMethod;

@property (nonatomic, assign, readonly) BOOL calledSomeMethod;

@end
@implementation CKTestObjectTarget

- (void)someMethod
{
  _calledSomeMethod = YES;
}

@end

@interface CKTestControllerScopeActionComponentController : CKComponentController<CKTestControllerScopeActionComponent *>
@end

@implementation CKTestControllerScopeActionComponentController
- (void)actionMethod:(CKComponent *)sender context:(id)context
{
  self.component.block(sender, context);
}
@end

@interface CKComponentActionTests : XCTestCase
@end

@implementation CKComponentActionTests

- (void)testSendActionIncludesSenderComponent
{
  __block CKComponent *actionSender = nil;

  CKComponent *innerComponent = [CKComponent new];
  CKTestActionComponent *outerComponent =
  [CKTestActionComponent
   newWithSingleArgumentBlock:^(CKComponent *sender, id context){ actionSender = sender; }
   secondArgumentBlock:^(CKComponent *sender, id obj1, id obj2) { XCTFail(@"Should not be called."); }
   primitiveArgumentBlock:^(CKComponent *sender, int value) { XCTFail(@"Should not be called."); }
   noArgumentBlock:^{ XCTFail(@"Should not be called."); }
   component:innerComponent];

  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView, nil, nil);

  CKComponentActionSend(@selector(testAction:context:), innerComponent);

  XCTAssert(actionSender == innerComponent, @"Sender should be inner component");

  [mountedComponents makeObjectsPerformSelector:@selector(unmount)];
}

- (void)testSendActionIncludesContext
{
  __block id actionContext = nil;

  CKComponent *innerComponent = [CKComponent new];
  CKTestActionComponent *outerComponent =
  [CKTestActionComponent
   newWithSingleArgumentBlock:^(CKComponent *sender, id context){ actionContext = context; }
   secondArgumentBlock:^(CKComponent *sender, id obj1, id obj2) { XCTFail(@"Should not be called."); }
   primitiveArgumentBlock:^(CKComponent *sender, int value) { XCTFail(@"Should not be called."); }
   noArgumentBlock:^{ XCTFail(@"Should not be called."); }
   component:innerComponent];

  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView, nil, nil);

  id context = @"context";

  CKComponentActionSend(@selector(testAction:context:), innerComponent, context);

  XCTAssert(actionContext == context, @"Context should match what was passed to CKComponentActionSend");

  [mountedComponents makeObjectsPerformSelector:@selector(unmount)];
}

- (void)testSendActionIncludesMultipleContextObjects
{
  __block id actionContext = nil;
  __block id actionContext2 = nil;

  CKComponent *innerComponent = [CKComponent new];
  CKTestActionComponent *outerComponent =
  [CKTestActionComponent
   newWithSingleArgumentBlock:^(CKComponent *sender, id context){ XCTFail(@"Should not be called."); }
   secondArgumentBlock:^(CKComponent *sender, id obj1, id obj2) { actionContext = obj1; actionContext2 = obj2; }
   primitiveArgumentBlock:^(CKComponent *sender, int value) { XCTFail(@"Should not be called."); }
   noArgumentBlock:^{ XCTFail(@"Should not be called."); }
   component:innerComponent];

  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView, nil, nil);

  id context = @"context";
  id context2 = @"context2";

  CKTypedComponentAction<id, id> action = { @selector(testAction2:context1:context2:) };
  action.send(innerComponent, context, context2);

  XCTAssert(actionContext == context && actionContext2 == context2, @"Contexts should match what was passed to CKComponentActionSend");

  [mountedComponents makeObjectsPerformSelector:@selector(unmount)];
}

- (void)testSendActionIncludingPrimitiveValue
{
  __block int actionInteger = 0;

  CKComponent *innerComponent = [CKComponent new];
  CKTestActionComponent *outerComponent =
  [CKTestActionComponent
   newWithSingleArgumentBlock:^(CKComponent *sender, id context){ XCTFail(@"Should not be called."); }
   secondArgumentBlock:^(CKComponent *sender, id obj1, id obj2) { XCTFail(@"Should not be called."); }
   primitiveArgumentBlock:^(CKComponent *sender, int value) { actionInteger = value; }
   noArgumentBlock:^{ XCTFail(@"Should not be called."); }
   component:innerComponent];

  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView, nil, nil);

  int integer = 1337;

  CKTypedComponentAction<int> action = { @selector(testPrimitive:integer:) };
  action.send(innerComponent, integer);

  XCTAssert(actionInteger == integer, @"Contexts should match what was passed to CKComponentActionSend");

  [mountedComponents makeObjectsPerformSelector:@selector(unmount)];
}

- (void)testSendActionWithNoArguments
{
  __block BOOL calledNoArgumentBlock = NO;

  CKComponent *innerComponent = [CKComponent new];
  CKTestActionComponent *outerComponent =
  [CKTestActionComponent
   newWithSingleArgumentBlock:^(CKComponent *sender, id context){ XCTFail(@"Should not be called."); }
   secondArgumentBlock:^(CKComponent *sender, id obj1, id obj2) { XCTFail(@"Should not be called."); }
   primitiveArgumentBlock:^(CKComponent *sender, int value) { XCTFail(@"Should not be called."); }
   noArgumentBlock:^{ calledNoArgumentBlock = YES; }
   component:innerComponent];

  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView, nil, nil);

  CKTypedComponentAction<> action = { @selector(testNoArgumentAction) };
  action.send(innerComponent);

  XCTAssert(calledNoArgumentBlock, @"Contexts should match what was passed to CKComponentActionSend");

  [mountedComponents makeObjectsPerformSelector:@selector(unmount)];
}

- (void)testSendActionWithNoArgumentsWithAnActionThatExpectsObjectArguments
{
  __block BOOL calledNoArgumentBlock = NO;

  CKComponent *innerComponent = [CKComponent new];
  CKTestActionComponent *outerComponent =
  [CKTestActionComponent
   newWithSingleArgumentBlock:^(CKComponent *sender, id context){ XCTFail(@"Should not be called."); }
   secondArgumentBlock:^(CKComponent *sender, id obj1, id obj2) { XCTFail(@"Should not be called."); }
   primitiveArgumentBlock:^(CKComponent *sender, int value) { XCTFail(@"Should not be called."); }
   noArgumentBlock:^{ calledNoArgumentBlock = YES; }
   component:innerComponent];

  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView, nil, nil);

  CKTypedComponentAction<id> action = { @selector(testNoArgumentAction) };
  action.send(innerComponent, @"hello");

  XCTAssert(calledNoArgumentBlock, @"Contexts should match what was passed to CKComponentActionSend");

  [mountedComponents makeObjectsPerformSelector:@selector(unmount)];
}

- (void)testSendActionStartingAtSenderNextResponderReachesParentComponent
{
  __block BOOL outerReceivedTestAction = NO;
  __block BOOL innerReceivedTestAction = NO;

  CKTestActionComponent *innerComponent =
  [CKTestActionComponent
   newWithSingleArgumentBlock:^(CKComponent *sender, id context){ innerReceivedTestAction = YES; }
   secondArgumentBlock:^(CKComponent *sender, id obj1, id obj2) { XCTFail(@"Should not be called."); }
   primitiveArgumentBlock:^(CKComponent *sender, int value) { XCTFail(@"Should not be called."); }
   noArgumentBlock:^{ XCTFail(@"Should not be called."); }
   component:[CKComponent new]];

  CKTestActionComponent *outerComponent =
  [CKTestActionComponent
   newWithSingleArgumentBlock:^(CKComponent *sender, id context){ outerReceivedTestAction = YES; }
   secondArgumentBlock:^(CKComponent *sender, id obj1, id obj2) { XCTFail(@"Should not be called."); }
   primitiveArgumentBlock:^(CKComponent *sender, int value) { XCTFail(@"Should not be called."); }
   noArgumentBlock:^{ XCTFail(@"Should not be called."); }
   component:innerComponent];

  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView, nil, nil);

  CKComponentActionSend(@selector(testAction:context:), innerComponent);

  XCTAssertTrue(outerReceivedTestAction, @"Outer component should have received action sent by inner component");
  XCTAssertFalse(innerReceivedTestAction, @"Inner component should not have received action sent from it");

  [mountedComponents makeObjectsPerformSelector:@selector(unmount)];
}

- (void)testSendActionStartingAtSenderDoesNotReachParentComponent
{
  __block BOOL outerReceivedTestAction = NO;
  __block BOOL innerReceivedTestAction = NO;

  CKTestActionComponent *innerComponent =
  [CKTestActionComponent
   newWithSingleArgumentBlock:^(CKComponent *sender, id context){ innerReceivedTestAction = YES; }
   secondArgumentBlock:^(CKComponent *sender, id obj1, id obj2) { XCTFail(@"Should not be called."); }
   primitiveArgumentBlock:^(CKComponent *sender, int value) { XCTFail(@"Should not be called."); }
   noArgumentBlock:^{ XCTFail(@"Should not be called."); }
   component:[CKComponent new]];

  CKTestActionComponent *outerComponent =
  [CKTestActionComponent
   newWithSingleArgumentBlock:^(CKComponent *sender, id context){ outerReceivedTestAction = YES; }
   secondArgumentBlock:^(CKComponent *sender, id obj1, id obj2) { XCTFail(@"Should not be called."); }
   primitiveArgumentBlock:^(CKComponent *sender, int value) { XCTFail(@"Should not be called."); }
   noArgumentBlock:^{ XCTFail(@"Should not be called."); }
   component:innerComponent];

  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView, nil, nil);

  CKComponentActionSend(@selector(testAction:context:), innerComponent, nil, CKComponentActionSendBehaviorStartAtSender);

  XCTAssertFalse(outerReceivedTestAction, @"Outer component should not have received action since inner component did");
  XCTAssertTrue(innerReceivedTestAction, @"Inner component should have received action");

  [mountedComponents makeObjectsPerformSelector:@selector(unmount)];
}

- (void)testTargetSelectorActionCallsOnTargetWithoutMounting
{
  __block BOOL calledBlock = NO;

  CKComponent *innerComponent = [CKComponent new];
  CKTestActionComponent *outerComponent =
  [CKTestActionComponent
   newWithSingleArgumentBlock:^(CKComponent *sender, id context){ calledBlock = YES; }
   secondArgumentBlock:^(CKComponent *sender, id obj1, id obj2) { XCTFail(@"Should not be called."); }
   primitiveArgumentBlock:^(CKComponent *sender, int value) { XCTFail(@"Should not be called."); }
   noArgumentBlock:^{ XCTFail(@"Should not be called."); }
   component:innerComponent];

  CKTypedComponentAction<id> action { outerComponent, @selector(testAction:context:) };
  action.send(innerComponent, CKComponentActionSendBehaviorStartAtSender, @"hello");

  XCTAssertTrue(calledBlock, @"Outer component should have received the action, even though the components are not mounted.");
}

- (void)testScopeActionCallsMethodOnScopedComponent
{
  __block BOOL calledAction = NO;

  // We have to use build component here to ensure the scopes are properly configured.
  CKTestScopeActionComponent *component = (CKTestScopeActionComponent *)CKBuildComponent([CKComponentScopeRoot rootWithListener:nil], {}, ^{
    return [CKTestScopeActionComponent
            newWithBlock:^(CKComponent *sender, id context) {
              calledAction = YES;
            }];
  }).component;

  [component triggerAction:nil];

  XCTAssertTrue(calledAction, @"Should have called the action on the test component");
}

- (void)testScopeActionCallsMethodOnScopedComponentWithCorrectContext
{
  __block id actionContext = nil;

  // We have to use build component here to ensure the scopes are properly configured.
  CKTestScopeActionComponent *component = (CKTestScopeActionComponent *)CKBuildComponent([CKComponentScopeRoot rootWithListener:nil], {}, ^{
    return [CKTestScopeActionComponent
            newWithBlock:^(CKComponent *sender, id context) {
              actionContext = context;
            }];
  }).component;

  id context = @"hello";

  [component triggerAction:context];

  XCTAssertTrue(actionContext == context, @"Context should have been passed to scope component action call");
}

- (void)testScopeActionCallsMethodOnScopedComponentControllerIfNotImplementedOnComponent
{
  __block BOOL calledAction = NO;

  // We have to use build component here to ensure the scopes are properly configured.
  CKTestControllerScopeActionComponent *component = (CKTestControllerScopeActionComponent *)CKBuildComponent([CKComponentScopeRoot rootWithListener:nil], {}, ^{
    return [CKTestControllerScopeActionComponent
            newWithBlock:^(CKComponent *sender, id context) {
              calledAction = YES;
            }];
  }).component;

  [component triggerAction:nil];

  XCTAssertTrue(calledAction, @"Should have called the action on the test component");
}

- (void)testDemotedTargetSelectorActionCallsMethodOnScopedComponent
{
  __block BOOL calledAction = NO;

  // We have to use build component here to ensure the scopes are properly configured.
  CKTestScopeActionComponent *component = (CKTestScopeActionComponent *)CKBuildComponent([CKComponentScopeRoot rootWithListener:nil], {}, ^{
    return [CKTestScopeActionComponent
            newWithBlock:^(CKComponent *sender, id context) {
              calledAction = YES;
            }];
  }).component;

  CKComponentAction action = CKComponentAction(CKTypedComponentAction<id>(component, @selector(actionMethod:context:)));
  action.send(component);

  XCTAssertTrue(calledAction, @"Should have called the action on the test component");
}

- (void)testTargetSelectorActionCallsOnNormalNSObject
{
  CKTestObjectTarget *target =[CKTestObjectTarget new];
  CKComponentAction action = CKComponentAction(CKTypedComponentAction<>(target, @selector(someMethod)));
  action.send([CKComponent new]);

  XCTAssertTrue(target.calledSomeMethod, @"Should have called the method on target");
}

- (void)testInvocationIsNilWhenSelectorIsNil
{
  XCTAssertNil(CKComponentActionSendResponderInvocationPrepare(nil, nil, nil));
}

@end
