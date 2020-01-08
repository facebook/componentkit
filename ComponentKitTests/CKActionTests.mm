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

#import <ComponentKit/CKBuildComponent.h>
#import <ComponentKit/CKAction.h>
#import <ComponentKit/CKCompositeComponent.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKComponentScopeRootFactory.h>
#import <ComponentKit/CKComponentController.h>
#import <ComponentKit/CKThreadLocalComponentScope.h>

@interface CKComponentActionTestAssertionHandler : NSAssertionHandler
@end

@implementation CKComponentActionTestAssertionHandler

- (void)handleFailureInFunction:(NSString *)functionName
                           file:(NSString *)fileName
                     lineNumber:(NSInteger)line
                    description:(NSString *)format, ...
{}

@end

@interface CKTestScopeActionComponent : CKComponent

+ (instancetype)newWithBlock:(void(^)(CKComponent *sender, id context))block;
+ (instancetype)newWithBlock:(void(^)(CKComponent *sender, id context))block
        useComponentAsTarget:(BOOL)useComponentAsTarget;

- (void)triggerAction:(id)context;

@end

@implementation CKTestScopeActionComponent
{
  CKAction<id> _action;
  void (^_block)(CKComponent *, id);
}

+ (instancetype)newWithBlock:(void(^)(CKComponent *sender, id context))block
{
  return [self newWithBlock:block useComponentAsTarget:NO];
}

+ (instancetype)newWithBlock:(void (^)(CKComponent *, id))block
        useComponentAsTarget:(BOOL)useComponentAsTarget
{
  CKComponentScope scope(self);

  CKTestScopeActionComponent *c = [super newWithView:{} size:{}];
  if (c) {
    if (useComponentAsTarget) {
      c->_action = {c, @selector(actionMethod:context:)};
    } else {
      c->_action = {scope, @selector(actionMethod:context:)};
    }
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
+ (instancetype)newWithBlock:(void(^)(CKComponent *sender, id context))block
        useComponentAsTarget:(BOOL)useComponentAsTarget;

- (void(^)(CKComponent *sender, id context))block;

- (void)triggerAction:(id)context;

@end

@interface CKTestControllerScopeActionComponentController : CKComponentController<CKTestControllerScopeActionComponent *>
@end

@implementation CKTestControllerScopeActionComponent
{
  CKAction<id> _action;
  void (^_block)(CKComponent *, id);
}

+ (instancetype)newWithBlock:(void(^)(CKComponent *sender, id context))block
{
  return [self newWithBlock:block useComponentAsTarget:NO];
}

+ (instancetype)newWithBlock:(void (^)(CKComponent *, id))block
        useComponentAsTarget:(BOOL)useComponentAsTarget
{
  CKComponentScope scope(self);

  CKTestControllerScopeActionComponent *c = [super newWithView:{} size:{}];
  if (c) {
    if (useComponentAsTarget) {
      c->_action = {c, @selector(actionMethod:context:)};
    } else {
      c->_action = {scope, @selector(actionMethod:context:)};
    }
    c->_block = block;
  }
  return c;
}

+ (Class<CKComponentControllerProtocol>)controllerClass
{
  return [CKTestControllerScopeActionComponentController class];
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

@implementation CKTestControllerScopeActionComponentController
- (void)actionMethod:(CKComponent *)sender context:(id)context
{
  self.component.block(sender, context);
}
@end

@interface CKActionTests : XCTestCase
@end

@implementation CKActionTests

- (void)testSendActionIncludesSenderComponent
{
  __block CKComponent *actionSender = nil;

  CKComponent *innerComponent = [CKComponent new];
  CKTestActionComponent *outerComponent =
  [CKTestActionComponent
   newWithSingleArgumentBlock:^(CKComponent *sender, id context){ actionSender = sender; }
   secondArgumentBlock:^(CKComponent *sender, id obj1, id obj2) { XCTFail(@"Should not be called."); }
   primitiveArgumentBlock:^(CKComponent *sender, int value) { XCTFail(@"Should not be called."); }
   noArgumentBlock:^(CKComponent *sender) { XCTFail(@"Should not be called."); }
   component:innerComponent];

  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView, nil, nil).mountedComponents;

  CKActionSend(@selector(testAction:context:), innerComponent, nil);

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
   noArgumentBlock:^(CKComponent *sender) { XCTFail(@"Should not be called."); }
   component:innerComponent];

  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView, nil, nil).mountedComponents;

  id context = @"context";

  CKActionSend(@selector(testAction:context:), innerComponent, context);

  XCTAssert(actionContext == context, @"Context should match what was passed to CKActionSend");

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
   noArgumentBlock:^(CKComponent *sender) { XCTFail(@"Should not be called."); }
   component:innerComponent];

  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView, nil, nil).mountedComponents;

  id context = @"context";
  id context2 = @"context2";

  CKAction<id, id> action = { @selector(testAction2:context1:context2:) };
  action.send(innerComponent, context, context2);

  XCTAssert(actionContext == context && actionContext2 == context2, @"Contexts should match what was passed to CKActionSend");

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
   noArgumentBlock:^(CKComponent *sender) { XCTFail(@"Should not be called."); }
   component:innerComponent];

  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView, nil, nil).mountedComponents;

  int integer = 1337;

  CKAction<int> action = { @selector(testPrimitive:integer:) };
  action.send(innerComponent, integer);

  XCTAssert(actionInteger == integer, @"Contexts should match what was passed to CKActionSend");

  [mountedComponents makeObjectsPerformSelector:@selector(unmount)];
}

- (void)testActionWithCppArgs
{
  __block std::vector<std::string> actionVec;

  CKComponent *innerComponent = [CKComponent new];
  CKTestActionComponent *outerComponent =
  [CKTestActionComponent
   newWithCppArgumentBlock:^(CKComponent *sender, std::vector<std::string> vec) { actionVec = vec; }
   component:innerComponent];

  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView, nil, nil).mountedComponents;

  std::vector<std::string> cppThing = {"hummus", "chips", "salad"};
  CKAction<const std::vector<std::string> &> action = { @selector(testCppArgumentAction:vector:) };
  action.send(innerComponent, cppThing);

  XCTAssert(actionVec == cppThing, @"Contexts should match what was passed to CKActionSend");

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
   noArgumentBlock:^(CKComponent *sender) { calledNoArgumentBlock = YES; }
   component:innerComponent];

  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView, nil, nil).mountedComponents;

  CKAction<> action = { @selector(testNoArgumentAction:) };
  action.send(innerComponent);

  XCTAssert(calledNoArgumentBlock, @"Contexts should match what was passed to CKActionSend");

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
   noArgumentBlock:^(CKComponent *sender) { calledNoArgumentBlock = YES; }
   component:innerComponent];

  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView, nil, nil).mountedComponents;

  CKAction<id> action = { @selector(testNoArgumentAction:) };
  action.send(innerComponent, @"hello");

  XCTAssert(calledNoArgumentBlock, @"Contexts should match what was passed to CKActionSend");

  [mountedComponents makeObjectsPerformSelector:@selector(unmount)];
}

static CKAction<> createDemotedWithReference(void (^callback)(CKComponent*, int), int value) {
  int& ref = value;
  auto action = CKAction<int>::actionFromBlock(callback);
  auto demoted = CKAction<>::demotedFrom(action, ref);
  return demoted;
}

- (void)testSendActionWithObjectArgumentsWithDemotedActionWithoutArguments
{
  __block id actionContext = nil;
  __block id actionContext2 = nil;

  CKComponent *innerComponent = [CKComponent new];
  CKTestActionComponent *outerComponent =
  [CKTestActionComponent
   newWithSingleArgumentBlock:^(CKComponent *sender, id context){ XCTFail(@"Should not be called."); }
   secondArgumentBlock:^(CKComponent *sender, id obj1, id obj2) { actionContext = obj1; actionContext2 = obj2; }
   primitiveArgumentBlock:^(CKComponent *sender, int value) { XCTFail(@"Should not be called."); }
   noArgumentBlock:^(CKComponent *sender) { XCTFail(@"Should not be called."); }
   component:innerComponent];

  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView, nil, nil).mountedComponents;

  id context = @"hello";
  id context2 = @"morty";

  CKAction<id, id> action = { @selector(testAction2:context1:context2:) };
  CKAction<> demotedAction = CKAction<>::demotedFrom(action, context, context2);
  demotedAction.send(innerComponent);

  __block int value;
  int expectedValue = 5;
  createDemotedWithReference(^(CKComponent *sender, int b) {
    value = b;
  }, expectedValue).send(innerComponent);

  XCTAssert(actionContext == context && actionContext2 == context2 && value == expectedValue, @"Contexts should match what was passed to CKActionSend");

  [mountedComponents makeObjectsPerformSelector:@selector(unmount)];
}

- (void)testSendActionWithObjectArgumentsWithPromotedActionWithObjectArguments
{
  __block id actionContext = nil;
  __block id actionContext2 = nil;

  CKComponent *innerComponent = [CKComponent new];
  CKTestActionComponent *outerComponent =
  [CKTestActionComponent
   newWithSingleArgumentBlock:^(CKComponent *sender, id context){ XCTFail(@"Should not be called."); }
   secondArgumentBlock:^(CKComponent *sender, id obj1, id obj2) { actionContext = obj1; actionContext2 = obj2; }
   primitiveArgumentBlock:^(CKComponent *sender, int value) { XCTFail(@"Should not be called."); }
   noArgumentBlock:^(CKComponent *sender) { XCTFail(@"Should not be called."); }
   component:innerComponent];

  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView, nil, nil).mountedComponents;

  id context = @"hello";
  id context2 = @"morty";

  CKAction<id, id> action = { @selector(testAction2:context1:context2:) };
  CKAction<id, id, id> promotedAction = CKAction<id, id>::promotedFrom<id>(action);
  promotedAction.send(innerComponent, context, context2, @"rick");

  XCTAssert(actionContext == context && actionContext2 == context2, @"Contexts should match what was passed to CKActionSend");

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
   noArgumentBlock:^(CKComponent *sender) { XCTFail(@"Should not be called."); }
   component:[CKComponent new]];

  CKTestActionComponent *outerComponent =
  [CKTestActionComponent
   newWithSingleArgumentBlock:^(CKComponent *sender, id context){ outerReceivedTestAction = YES; }
   secondArgumentBlock:^(CKComponent *sender, id obj1, id obj2) { XCTFail(@"Should not be called."); }
   primitiveArgumentBlock:^(CKComponent *sender, int value) { XCTFail(@"Should not be called."); }
   noArgumentBlock:^(CKComponent *sender) { XCTFail(@"Should not be called."); }
   component:innerComponent];

  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView, nil, nil).mountedComponents;

  CKActionSend(@selector(testAction:context:), innerComponent, nullptr);

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
   noArgumentBlock:^(CKComponent *sender) { XCTFail(@"Should not be called."); }
   component:[CKComponent new]];

  CKTestActionComponent *outerComponent =
  [CKTestActionComponent
   newWithSingleArgumentBlock:^(CKComponent *sender, id context){ outerReceivedTestAction = YES; }
   secondArgumentBlock:^(CKComponent *sender, id obj1, id obj2) { XCTFail(@"Should not be called."); }
   primitiveArgumentBlock:^(CKComponent *sender, int value) { XCTFail(@"Should not be called."); }
   noArgumentBlock:^(CKComponent *sender) { XCTFail(@"Should not be called."); }
   component:innerComponent];

  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView, nil, nil).mountedComponents;

  CKActionSend(@selector(testAction:context:), innerComponent, nil, CKActionSendBehaviorStartAtSender);

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
   noArgumentBlock:^(CKComponent *sender) { XCTFail(@"Should not be called."); }
   component:innerComponent];

  CKAction<id> action { outerComponent, @selector(testAction:context:) };
  action.send(innerComponent, CKActionSendBehaviorStartAtSender, @"hello");

  XCTAssertTrue(calledBlock, @"Outer component should have received the action, even though the components are not mounted.");
}

- (void)testScopeActionCallsMethodOnScopedComponent
{
  __block BOOL calledAction = NO;

  // We have to use build component here to ensure the scopes are properly configured.
  CKTestScopeActionComponent *component = (CKTestScopeActionComponent *)CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, ^{
    return [CKTestScopeActionComponent
            newWithBlock:^(CKComponent *sender, id context) {
              calledAction = YES;
            }];
  }).component;

  [component triggerAction:nil];

  XCTAssertTrue(calledAction, @"Should have called the action on the test component");
}

- (void)testComponentAsTargetActionCallsMethodOnComponent
{
  __block BOOL calledAction = NO;

  // We have to use build component here to ensure the scopes are properly configured.
  CKTestScopeActionComponent *component = (CKTestScopeActionComponent *)CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, ^{
    return [CKTestScopeActionComponent
            newWithBlock:^(CKComponent *sender, id context) {
              calledAction = YES;
            } useComponentAsTarget:YES];
  }).component;

  [component triggerAction:nil];

  XCTAssertTrue(calledAction, @"Should have called the action on the test component");
}

- (void)testScopeActionCallsMethodOnScopedComponentWithCorrectContext
{
  __block id actionContext = nil;

  // We have to use build component here to ensure the scopes are properly configured.
  CKTestScopeActionComponent *component = (CKTestScopeActionComponent *)CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, ^{
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
  CKTestControllerScopeActionComponent *component = (CKTestControllerScopeActionComponent *)CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, ^{
    return [CKTestControllerScopeActionComponent
            newWithBlock:^(CKComponent *sender, id context) {
              calledAction = YES;
            }];
  }).component;

  [component triggerAction:nil];

  XCTAssertTrue(calledAction, @"Should have called the action on the test component");
}

- (void)testComponentAsTargetActionCallsMethodOnComponentControllerIfNotImplementedOnComponent
{
  __block BOOL calledAction = NO;

  // We have to use build component here to ensure the scopes are properly configured.
  CKTestControllerScopeActionComponent *component = (CKTestControllerScopeActionComponent *)CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, ^{
    return [CKTestControllerScopeActionComponent
            newWithBlock:^(CKComponent *sender, id context) {
              calledAction = YES;
            } useComponentAsTarget:YES];
  }).component;

  [component triggerAction:nil];

  XCTAssertTrue(calledAction, @"Should have called the action on the test component");
}

- (void)testTargetSelectorActionCallsOnNormalNSObject
{
  CKTestObjectTarget *target = [CKTestObjectTarget new];
  CKAction<> action = {target, @selector(someMethod)};
  action.send([CKComponent new]);

  XCTAssertTrue(target.calledSomeMethod, @"Should have called the method on target");
}

- (void)testImpIsNilWhenSelectorIsNil
{
  XCTAssert(!CKActionFind(nil, nil).imp);
}

- (void)testImpIsNilWhenTargetIsNil
{
  XCTAssert(!CKActionFind(@selector(triggerAction:), nil).imp);
}

- (void)testResponderIsNilWhenSelectorIsNil
{
  XCTAssertNil(CKActionFind(nil, nil).responder);
}

- (void)testResponderIsNilWhenTargetIsNil
{
  XCTAssertNil(CKActionFind(@selector(triggerAction:), nil).responder);
}

- (void)testBlockActionFires
{
  __block BOOL firedAction = NO;
  CKAction<> action = CKAction<>::actionFromBlock(^(CKComponent *) {
    firedAction = YES;
  });

  action.send([CKComponent new]);

  XCTAssertTrue(firedAction);
}

- (void)testBlockActionFiresAndDeliversComponentAsSender
{
  __block BOOL equalComponents = NO;
  CKComponent *c = [CKComponent new];
  CKAction<> action = CKAction<>::actionFromBlock(^(CKComponent *passedComponent) {
    equalComponents = (passedComponent == c);
  });

  action.send(c);

  XCTAssertTrue(equalComponents);
}

- (void)testBlockActionFiresAndDeliversAdditionalParameterAsArgument
{
  __block BOOL equalArguments = NO;
  NSObject *arg = [NSObject new];
  CKAction<NSObject *> action = CKAction<NSObject *>::actionFromBlock(^(CKComponent *c, NSObject *passedArgument) {
    equalArguments = (passedArgument == arg);
  });

  action.send([CKComponent new], arg);
  XCTAssertTrue(equalArguments);
}

- (void)testThatScopeActionWithSameSelectorHaveUniqueIdentifiers
{
  CKThreadLocalComponentScope threadScope(CKComponentScopeRootWithDefaultPredicates(nil, nil), {});

  CKComponentScope scope([CKTestScopeActionComponent class], @"moose");
  const CKAction<> action1 = {scope, @selector(triggerAction:)};

  CKComponentScope scope2([CKTestScopeActionComponent class], @"cat");
  const CKAction<> action2 = {scope2, @selector(triggerAction:)};

  XCTAssertNotEqual(action1.identifier(), action2.identifier());
}

- (void)testThatBlockActionsWithDistinctBlocksHaveUniqueIdentifiers
{
  const CKAction<> action1 = CKAction<>::actionFromBlock(^(CKComponent *sender){
    exit(1);
  });
  const CKAction<> action2 = CKAction<>::actionFromBlock(^(CKComponent *sender){
    exit(2);
  });
  XCTAssertNotEqual(action1.identifier(), action2.identifier());
}

#pragma mark - Action Params Validation

- (BOOL)checkSelector:(SEL)sel typeEncodings:(const std::vector<const char *> &)typeEncodings {
  Method method = class_getInstanceMethod([self class], sel);
  return checkMethodSignatureAgainstTypeEncodings(sel, method, typeEncodings);
}

- (void)testActionNoParamValidation
{
  const SEL selector = @selector(triggerActionWithComponent:);
  std::vector<const char *> encodings;
  CKActionTypeVectorBuild(encodings, CKActionTypelist<>{});
  XCTAssertTrue(([self checkSelector:selector typeEncodings:encodings]));
}

- (void)triggerActionWithComponent:(id)sender {}

- (void)testActionPrimitiveParamValidation
{
  const SEL selector = @selector(triggerActionWithComponent:value:);
  std::vector<const char *> encodings;
  CKActionTypeVectorBuild(encodings, CKActionTypelist<int>{});
  XCTAssertTrue(([self checkSelector:selector typeEncodings:encodings]));
}

- (void)triggerActionWithComponent:(id)sender value:(int)val {}

- (void)testActionObjectAndPrimitiveParamValidation
{
  const SEL selector = @selector(triggerActionWithComponent:value:value:);
  std::vector<const char *> encodings;
  CKActionTypeVectorBuild(encodings, CKActionTypelist<NSString *, char>{});
  XCTAssertTrue(([self checkSelector:selector typeEncodings:encodings]));
}

- (void)triggerActionWithComponent:(id)sender value:(NSString *)obj value:(char)val {}

- (void)testActionCppParamsValidation
{
  const SEL selector = @selector(triggerActionWithComponent:vector:constVector:constValVector:vectorRef:vectorRval:);
  std::vector<const char *> encodings;
  CKActionTypeVectorBuild(encodings,
                          CKActionTypelist<
                          std::vector<int>,
                          const std::vector<int>,
                          std::vector<const int>,
                          std::vector<int> &,
                          std::vector<int> &&
                          >{});
  XCTAssertTrue(([self checkSelector:selector typeEncodings:encodings]));
}

- (void)triggerActionWithComponent:(id)sender
                            vector:(std::vector<int>)val
                       constVector:(const std::vector<int>)conVal
                    constValVector:(std::vector<const int>)conValVec
                         vectorRef:(std::vector<int> &)vecRef
                        vectorRval:(std::vector<int> &&)vecRval {}

- (void)testActionParamsFailedValidation
{
  // We need to set an assertion handler as `checkMethodSignatureAgainstTypeEncodings` throws `CKCFailAssert` in case it fails.
  auto const assertionHandler = [CKComponentActionTestAssertionHandler new];
  [[[NSThread currentThread] threadDictionary] setValue:assertionHandler forKey:NSAssertionHandlerKey];

  const SEL selector = @selector(triggerActionWithComponent:vector:object:primitive:);
  std::vector<const char *> encodings;

  // wrong c++ type
  CKActionTypeVectorBuild(encodings, CKActionTypelist<std::vector<NSURL *>, NSObject *, BOOL>{});
  XCTAssertFalse(([self checkSelector:selector typeEncodings:encodings]));

  // wrong object
  CKActionTypeVectorBuild(encodings, CKActionTypelist<std::vector<int>, NSInteger, BOOL>{});
  XCTAssertFalse(([self checkSelector:selector typeEncodings:encodings]));

  // wrong primitive
  CKActionTypeVectorBuild(encodings, CKActionTypelist<std::vector<int>, NSObject *, char >{});
  XCTAssertFalse(([self checkSelector:selector typeEncodings:encodings]));
}

- (void)triggerActionWithComponent:(id)sender
                            vector:(std::vector<int>)val
                            object:(NSObject *)conVal
                         primitive:(BOOL)prim {}

#pragma mark - Equality.

- (void)testRawSelectorEquality
{
  const SEL selector = @selector(triggerAction:);
  const CKUntypedComponentAction action1 = {selector};
  const CKUntypedComponentAction action2 = {selector};
  XCTAssertTrue(action1 == action2);

  const CKUntypedComponentAction unequalAction = {@selector(stringWithFormat:)};
  XCTAssertFalse(action1 == unequalAction);
}

- (void)testTargetSelectorActionEquality
{
  NSMutableArray *const target = [NSMutableArray new];
  const SEL selector = @selector(removeLastObject);
  const CKAction<> action1 = {target, selector};
  const CKAction<> action2 = {target, selector};
  XCTAssertTrue(action1 == action2);

  const CKAction<> actionWithUnequalTarget = {[NSMutableArray new], selector};
  XCTAssertFalse(action1 == actionWithUnequalTarget);

  const CKAction<> actionWithUnequalSelector = {target, @selector(removeAllObjects)};
  XCTAssertFalse(action1 == actionWithUnequalSelector);
}

- (void)testBlockActionEquality
{
  void (^block)(CKComponent *c, NSObject *passedArgument) {};
  const CKAction<NSObject *> action = CKAction<NSObject *>::actionFromBlock(block);
  XCTAssertTrue(action == CKAction<NSObject *>::actionFromBlock(block));
  XCTAssertFalse(action == CKAction<NSObject *>::actionFromBlock(^(CKComponent *, NSObject *__strong) {}));
}

- (void)testScopedActionEquality
{
  CKThreadLocalComponentScope threadScope(CKComponentScopeRootWithDefaultPredicates(nil, nil), {});

  const SEL selector = @selector(triggerAction:);
  CKComponentScope scope([CKTestScopeActionComponent class], @"Marty McFly");
  const CKAction<> action1 = {scope, selector};
  const CKAction<> action2 = {scope, selector};
  XCTAssertTrue(action1 == action2);

  CKComponentScope scope2([CKTestScopeActionComponent class], @"Biff Tannon");
  const CKAction<> unequalAction = {scope2, selector};
  XCTAssertFalse(action1 == unequalAction);
}

@end
