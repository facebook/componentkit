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

#import <ComponentKitTestHelpers/CKComponentLifecycleTestHelper.h>
#import <ComponentKitTestHelpers/CKComponentTestRootScope.h>
#import <ComponentKitTestHelpers/CKLifecycleTestComponent.h>

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentController.h>
#import <ComponentKit/CKComponentControllerEvents.h>
#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/CKComponentScope.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKComponentHostingView.h>
#import <ComponentKit/CKThreadLocalComponentScope.h>

@interface CKComponentControllerTests : XCTestCase <CKComponentProvider>
@end

@implementation CKComponentControllerTests

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [CKLifecycleTestComponent new];
}

- (void)testThatCreatingComponentCreatesAController
{
  CKComponentTestRootScope scope;
  CKLifecycleTestComponent *fooComponent = [CKLifecycleTestComponent new];
  XCTAssertNotNil(fooComponent.controller);
}

- (void)testThatAttachingManagerInstantiatesComponentController
{
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:[self class]
                                                                                                                             sizeRangeProvider:nil];
  const CKComponentLifecycleTestHelperState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                    constrainedSize:{{0,0}, {100, 100}}
                                                                                                            context:nil];
  [componentLifecycleTestController updateWithState:state];

  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];

  CKLifecycleTestComponent *fooComponent = (CKLifecycleTestComponent *)state.componentLayout.component;
  XCTAssertNotNil(fooComponent.controller, @"Expected mounting a component to create controller");
}

- (void)testThatRemountingUnchangedComponentDoesNotCallDidUpdateComponent
{
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc]
                                                                      initWithComponentProvider:[self class]
                                                                              sizeRangeProvider:nil];
  const CKComponentLifecycleTestHelperState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                constrainedSize:{{0,0}, {100, 100}}
                                                                                                        context:nil];
  [componentLifecycleTestController updateWithState:state];

  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];

  CKLifecycleTestComponent *fooComponent = (CKLifecycleTestComponent *)state.componentLayout.component;
  CKLifecycleTestComponentController *controller = fooComponent.controller;

  [componentLifecycleTestController detachFromView];
  controller.calledDidUpdateComponent = NO; // Reset to NO
  [componentLifecycleTestController attachToView:view];
  XCTAssertFalse(controller.calledDidUpdateComponent, @"Component did not update so should not call didUpdateComponent");
}

- (void)testThatUpdatingManagerUpdatesComponentController
{
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:[self class]
                                                                                                                             sizeRangeProvider:nil];
  UIView *view = [UIView new];

  const CKComponentLifecycleTestHelperState state1 = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                     constrainedSize:{{0,0}, {100, 100}}
                                                                                                             context:nil];
  [componentLifecycleTestController updateWithState:state1];
  [componentLifecycleTestController attachToView:view];
  CKLifecycleTestComponent *fooComponent1 = (CKLifecycleTestComponent *)state1.componentLayout.component;

  const CKComponentLifecycleTestHelperState state2 = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                     constrainedSize:{{0,0}, {100, 100}}
                                                                                                             context:nil];
  [componentLifecycleTestController updateWithState:state2];
  CKLifecycleTestComponent *fooComponent2 = (CKLifecycleTestComponent *)state1.componentLayout.component;

  XCTAssertTrue(fooComponent1.controller == fooComponent2.controller,
                @"Expected controller %@ to match %@",
                fooComponent1.controller, fooComponent2.controller);
}

- (void)testThatAttachingManagerCallsDidAcquireView
{
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:[self class]
                                                                                                                             sizeRangeProvider:nil];
  const CKComponentLifecycleTestHelperState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                    constrainedSize:{{0,0}, {100, 100}}
                                                                                                            context:nil];
  [componentLifecycleTestController updateWithState:state];

  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];

  CKLifecycleTestComponent *fooComponent = (CKLifecycleTestComponent *)state.componentLayout.component;
  XCTAssertTrue(fooComponent.controller.calledDidAcquireView, @"Expected mounting to acquire view");
  XCTAssertNotNil(fooComponent.controller.view, @"Expected mounting to acquire view");
}

- (void)testThatDetachingManagerCallsDidRelinquishView
{
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:[self class]
                                                                                                                             sizeRangeProvider:nil];
  const CKComponentLifecycleTestHelperState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                    constrainedSize:{{0,0}, {100, 100}}
                                                                                                            context:nil];
  [componentLifecycleTestController updateWithState:state];

  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];

  CKLifecycleTestComponent *fooComponent = (CKLifecycleTestComponent *)state.componentLayout.component;
  XCTAssertFalse(fooComponent.controller.calledWillRelinquishView, @"Did not expect view to be released before detach");

  [componentLifecycleTestController detachFromView];
  XCTAssertTrue(fooComponent.controller.calledWillRelinquishView, @"Expected detach to call release view");
  XCTAssertNil(fooComponent.controller.view, @"Expected detach to release view");
}

- (void)testThatUpdatingStateWhileAttachedRelinquishesOldViewAndAcquiresNewOne
{
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:[self class]
                                                                                                                             sizeRangeProvider:nil];
  const CKComponentLifecycleTestHelperState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                    constrainedSize:{{0,0}, {100, 100}}
                                                                                                            context:nil];
  [componentLifecycleTestController updateWithState:state];

  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];

  CKLifecycleTestComponent *fooComponent = (CKLifecycleTestComponent *)state.componentLayout.component;
  XCTAssertTrue(fooComponent.controller.calledDidAcquireView, @"Expected mounting to acquire view");
  XCTAssertNotNil(fooComponent.controller.view, @"Expected mounting to acquire view");
  UIView *originalView = fooComponent.controller.view;

  fooComponent.controller.calledDidAcquireView = NO; // reset

  [fooComponent updateStateToIncludeNewAttribute];
  XCTAssertTrue(fooComponent.controller.calledWillRelinquishView, @"Expected state update to relinquish old view");
  XCTAssertTrue(fooComponent.controller.calledDidAcquireView, @"Expected state update to relinquish old view");
  XCTAssertTrue(originalView != fooComponent.controller.view, @"Expected different view");
}

- (void)testThatResponderChainIsInOrderComponentThenControllerThenRootView
{
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:[self class]
                                                                                                                             sizeRangeProvider:nil];
  const CKComponentLifecycleTestHelperState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                    constrainedSize:{{0,0}, {100, 100}}
                                                                                                            context:nil];
  [componentLifecycleTestController updateWithState:state];

  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];

  CKLifecycleTestComponent *fooComponent = (CKLifecycleTestComponent *)state.componentLayout.component;
  XCTAssertEqualObjects([fooComponent nextResponder], fooComponent.controller,
                       @"Component's nextResponder should be component controller");
  XCTAssertEqualObjects([fooComponent.controller nextResponder], view,
                       @"Root component's controller's nextResponder should be root view");
}

- (void)testThatResponderChainTargetsCorrectResponder
{
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:[self class]
                                                                                                                             sizeRangeProvider:nil];
  const CKComponentLifecycleTestHelperState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                    constrainedSize:{{0,0}, {100, 100}}
                                                                                                            context:nil];
  [componentLifecycleTestController updateWithState:state];
  
  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];
  
  CKLifecycleTestComponent *fooComponent = (CKLifecycleTestComponent *)state.componentLayout.component;
  XCTAssertEqualObjects([fooComponent targetForAction:nil withSender:fooComponent], fooComponent, @"Component should respond to this action");
  XCTAssertEqualObjects([fooComponent targetForAction:nil withSender:nil], fooComponent.controller, @"Component's controller should respond to this action");
}

- (void)testThatEarlyReturnNew_fromFirstComponent_allowsComponentCreation_whenNotEarlyReturning_onStateUpdate
{
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:[self class]
                                                                                                                             sizeRangeProvider:nil];
  UIView *view = [UIView new];

  [CKLifecycleTestComponent setShouldEarlyReturnNew:YES];

  const CKComponentLifecycleTestHelperState state1 = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                     constrainedSize:{{0,0}, {100, 100}}
                                                                                                             context:nil];
  [componentLifecycleTestController updateWithState:state1];
  [componentLifecycleTestController attachToView:view];

  [CKLifecycleTestComponent setShouldEarlyReturnNew:NO];

  const CKComponentLifecycleTestHelperState state2 = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                     constrainedSize:{{0,0}, {100, 100}}
                                                                                                             context:nil];
  [componentLifecycleTestController updateWithState:state2];
  CKLifecycleTestComponent *fooComponent2 = (CKLifecycleTestComponent *)state2.componentLayout.component;

  XCTAssertTrue([fooComponent2.controller isKindOfClass:[CKLifecycleTestComponentController class]],
                @"Expected controller %@ to exist and be of type CKLifecycleTestComponentController",
                fooComponent2.controller);
}

- (void)testThatComponentControllerReceivesComponentTreeWillAppearEvent
{
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:[self class]
                                                                                                                             sizeRangeProvider:nil];
  const CKComponentLifecycleTestHelperState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                    constrainedSize:{{0,0}, {100, 100}}
                                                                                                            context:nil];
  [componentLifecycleTestController attachToView:[UIView new]];
  [componentLifecycleTestController updateWithState:state];
  CKComponentScopeRootAnnounceControllerAppearance([componentLifecycleTestController state].scopeRoot);
  CKLifecycleTestComponent *fooComponent = (CKLifecycleTestComponent *)[componentLifecycleTestController state].componentLayout.component;
  XCTAssertTrue(fooComponent.controller.calledComponentTreeWillAppear,
                @"Expected controller %@ to have received component tree will appear event", fooComponent.controller);
}

- (void)testThatComponentControllerReceivesComponentTreeDidDisappearEvent
{
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:[self class]
                                                                                                                             sizeRangeProvider:nil];
  const CKComponentLifecycleTestHelperState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                    constrainedSize:{{0,0}, {100, 100}}
                                                                                                            context:nil];
  [componentLifecycleTestController attachToView:[UIView new]];
  [componentLifecycleTestController updateWithState:state];
  CKComponentScopeRootAnnounceControllerAppearance([componentLifecycleTestController state].scopeRoot);
  [componentLifecycleTestController detachFromView];
  CKComponentScopeRootAnnounceControllerDisappearance([componentLifecycleTestController state].scopeRoot);
  CKLifecycleTestComponent *fooComponent = (CKLifecycleTestComponent *)[componentLifecycleTestController state].componentLayout.component;
  XCTAssertTrue(fooComponent.controller.calledComponentTreeDidDisappear,
                @"Expected controller %@ to have received component tree did disappear event", fooComponent.controller);
}

- (void)testThatComponentControllerReceivesComponentTreeWillAppearEventAfterAdditionalStateUpdates
{
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:[self class]
                                                                                                                             sizeRangeProvider:nil];
  const CKComponentLifecycleTestHelperState state1 = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                     constrainedSize:{{0,0}, {100, 100}}
                                                                                                             context:nil];
  const CKComponentLifecycleTestHelperState state2 = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                     constrainedSize:{{0,0}, {100, 100}}
                                                                                                             context:nil];
  [componentLifecycleTestController attachToView:[UIView new]];
  [componentLifecycleTestController updateWithState:state1];
  [componentLifecycleTestController updateWithState:state2];
  CKComponentScopeRootAnnounceControllerAppearance([componentLifecycleTestController state].scopeRoot);
  CKLifecycleTestComponent *fooComponent = (CKLifecycleTestComponent *)[componentLifecycleTestController state].componentLayout.component;
  XCTAssertTrue(fooComponent.controller.calledComponentTreeWillAppear,
                @"Expected controller %@ to have received component tree will appear event", fooComponent.controller);
}

- (void)testThatComponentControllerReceivesComponentTreeDidDisappearEventAfterAdditionalStateUpdates
{
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:[self class]
                                                                                                                             sizeRangeProvider:nil];
  const CKComponentLifecycleTestHelperState state1 = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                     constrainedSize:{{0,0}, {100, 100}}
                                                                                                             context:nil];
  const CKComponentLifecycleTestHelperState state2 = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                     constrainedSize:{{0,0}, {100, 100}}
                                                                                                             context:nil];
  [componentLifecycleTestController attachToView:[UIView new]];
  [componentLifecycleTestController updateWithState:state1];
  [componentLifecycleTestController updateWithState:state2];
  CKComponentScopeRootAnnounceControllerAppearance([componentLifecycleTestController state].scopeRoot);
  [componentLifecycleTestController detachFromView];
  CKComponentScopeRootAnnounceControllerDisappearance([componentLifecycleTestController state].scopeRoot);
  CKLifecycleTestComponent *fooComponent = (CKLifecycleTestComponent *)[componentLifecycleTestController state].componentLayout.component;
  XCTAssertTrue(fooComponent.controller.calledComponentTreeDidDisappear,
                @"Expected controller %@ to have received component tree did disappear event", fooComponent.controller);
}

- (void)testComponentControllerReceivesInvalidateEvent
{
  CKComponentLifecycleTestHelper *componentLifecycleTestController =
    [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:[self class] sizeRangeProvider:nil];
  const CKComponentLifecycleTestHelperState state =
    [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                constrainedSize:{{0,0}, {100, 100}}
                                                        context:nil];
  [componentLifecycleTestController attachToView:[UIView new]];
  [componentLifecycleTestController updateWithState:state];
  [componentLifecycleTestController detachFromView];
  CKComponentScopeRootAnnounceControllerInvalidation([componentLifecycleTestController state].scopeRoot);
  CKLifecycleTestComponent *fooComponent = (CKLifecycleTestComponent *)state.componentLayout.component;
  XCTAssertTrue(fooComponent.controller.calledInvalidateController,
                @"Expected component controller to get invalidation event");
}

@end
