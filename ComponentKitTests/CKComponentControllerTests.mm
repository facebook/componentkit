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

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentController.h>
#import <ComponentKit/CKComponentControllerEvents.h>
#import <ComponentKit/CKComponentControllerHelper.h>
#import <ComponentKit/CKComponentScope.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKComponentHostingView.h>
#import <ComponentKit/CKThreadLocalComponentScope.h>
#import <ComponentKit/CKComponentControllerInternal.h>

#import <ComponentKitTestHelpers/CKComponentLifecycleTestHelper.h>
#import <ComponentKitTestHelpers/CKComponentTestRootScope.h>
#import <ComponentKitTestHelpers/CKLifecycleTestComponent.h>

using namespace CKComponentControllerHelper;

// Used for testing component controller that doesn't have lifecycle methods implemented.
@interface CKEmptyComponentController: CKComponentController
@end

@interface CKComponentControllerTests : XCTestCase
@end

@implementation CKComponentControllerTests

static CKComponent *componentProvider(id<NSObject> model, id<NSObject>context)
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
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:componentProvider
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
                                                                      initWithComponentProvider:componentProvider
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
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:componentProvider
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
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:componentProvider
                                                                                                                             sizeRangeProvider:nil];
  const CKComponentLifecycleTestHelperState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                    constrainedSize:{{0,0}, {100, 100}}
                                                                                                            context:nil];
  [componentLifecycleTestController updateWithState:state];

  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];

  CKLifecycleTestComponent *fooComponent = (CKLifecycleTestComponent *)state.componentLayout.component;
  XCTAssertTrue(fooComponent.controller.counts.didAcquireView > 0, @"Expected mounting to acquire view");
  XCTAssertNotNil(fooComponent.controller.view, @"Expected mounting to acquire view");
}

- (void)testThatDetachingManagerCallsDidRelinquishView
{
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:componentProvider
                                                                                                                             sizeRangeProvider:nil];
  const CKComponentLifecycleTestHelperState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                    constrainedSize:{{0,0}, {100, 100}}
                                                                                                            context:nil];
  [componentLifecycleTestController updateWithState:state];

  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];

  CKLifecycleTestComponent *fooComponent = (CKLifecycleTestComponent *)state.componentLayout.component;
  XCTAssertFalse(fooComponent.controller.counts.willRelinquishView > 0, @"Did not expect view to be released before detach");

  [componentLifecycleTestController detachFromView];
  XCTAssertTrue(fooComponent.controller.counts.willRelinquishView > 0, @"Expected detach to call release view");
  XCTAssertNil(fooComponent.controller.view, @"Expected detach to release view");
}

- (void)testThatUpdatingStateWhileAttachedRelinquishesOldViewAndAcquiresNewOne
{
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:componentProvider
                                                                                                                             sizeRangeProvider:nil];
  const CKComponentLifecycleTestHelperState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                    constrainedSize:{{0,0}, {100, 100}}
                                                                                                            context:nil];
  [componentLifecycleTestController updateWithState:state];

  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];

  CKLifecycleTestComponent *fooComponent = (CKLifecycleTestComponent *)state.componentLayout.component;
  XCTAssertTrue(fooComponent.controller.counts.didAcquireView > 0, @"Expected mounting to acquire view");
  XCTAssertNotNil(fooComponent.controller.view, @"Expected mounting to acquire view");
  UIView *originalView = fooComponent.controller.view;

  fooComponent.controller.counts = {}; // reset

  [fooComponent updateStateToIncludeNewAttribute];
  XCTAssertTrue(fooComponent.controller.counts.willRelinquishView > 0, @"Expected state update to relinquish old view");
  XCTAssertTrue(fooComponent.controller.counts.didAcquireView > 0, @"Expected state update to relinquish old view");
  XCTAssertTrue(originalView != fooComponent.controller.view, @"Expected different view");
}

- (void)testThatAttachingWithDifferentViewRelinquishesOldViewAndAcquiresNewOne
{
  const auto componentLifecycleTestController =
  [[CKComponentLifecycleTestHelper alloc]
   initWithComponentProvider:componentProvider
   sizeRangeProvider:nil];
  const auto state =
  [componentLifecycleTestController
   prepareForUpdateWithModel:nil
   constrainedSize:{{0,0}, {100, 100}}
   context:nil];
  [componentLifecycleTestController updateWithState:state];

  const auto view1 = [UIView new];
  [componentLifecycleTestController attachToView:view1];

  const auto fooComponent = (CKLifecycleTestComponent *)state.componentLayout.component;

  // Attaching first view should only trigger `didAcquireView` because there is no previous view
  // to be relinquished.
  XCTAssertEqual(fooComponent.controller.counts.willRelinquishView, 0);
  XCTAssertEqual(fooComponent.controller.counts.didAcquireView, 1);

  const auto view2 = [UIView new];
  [componentLifecycleTestController attachToView:view2];

  // Attaching second view should trigger both `willRelinquishView` and `didAcquireView` because
  // we need to relinquish the previous view it acquired.
  XCTAssertEqual(fooComponent.controller.counts.willRelinquishView, 1);
  XCTAssertEqual(fooComponent.controller.counts.didAcquireView, 2);
}

- (void)testThatAttachingWithDifferentViewAfterUpdatingStateRelinquishesOldViewAndAcquiresNewOne
{
  const auto componentLifecycleTestController =
  [[CKComponentLifecycleTestHelper alloc]
   initWithComponentProvider:componentProvider
   sizeRangeProvider:nil];
  const auto state =
  [componentLifecycleTestController
   prepareForUpdateWithModel:nil
   constrainedSize:{{0,0}, {100, 100}}
   context:nil];
  [componentLifecycleTestController updateWithState:state];

  const auto view1 = [UIView new];
  [componentLifecycleTestController attachToView:view1];

  const auto fooComponent = (CKLifecycleTestComponent *)state.componentLayout.component;

  // Attaching first view should only trigger `didAcquireView` because there is no previous view
  // to be relinquished.
  XCTAssertEqual(fooComponent.controller.counts.willRelinquishView, 0);
  XCTAssertEqual(fooComponent.controller.counts.didAcquireView, 1);

  [fooComponent updateState:^id(id currentState) {
    return @NO;
  } mode:CKUpdateModeSynchronous];

  const auto view2 = [UIView new];
  [componentLifecycleTestController attachToView:view2];

  // Attaching second view should trigger both `willRelinquishView` and `didAcquireView` because
  // we need to relinquish the previous view it acquired.
  XCTAssertEqual(fooComponent.controller.counts.willRelinquishView, 1);
  XCTAssertEqual(fooComponent.controller.counts.didAcquireView, 2);
}

- (void)testThatAttachingWithSameViewAfterUpdatingStateDoesNotRelinquishesOldView
{
  const auto componentLifecycleTestController =
  [[CKComponentLifecycleTestHelper alloc]
   initWithComponentProvider:componentProvider
   sizeRangeProvider:nil];
  const auto state =
  [componentLifecycleTestController
   prepareForUpdateWithModel:nil
   constrainedSize:{{0,0}, {100, 100}}
   context:nil];
  [componentLifecycleTestController updateWithState:state];

  const auto view = [UIView new];
  [componentLifecycleTestController attachToView:view];

  const auto fooComponent = (CKLifecycleTestComponent *)state.componentLayout.component;

  // Attaching first view should only trigger `didAcquireView` because there is no previous view
  // to be relinquished.
  XCTAssertEqual(fooComponent.controller.counts.willRelinquishView, 0);
  XCTAssertEqual(fooComponent.controller.counts.didAcquireView, 1);

  [fooComponent updateState:^id(id currentState) {
    return @NO;
  } mode:CKUpdateModeSynchronous];

  [componentLifecycleTestController attachToView:view];

  // Attaching the same view should not trigger `willRelinquishView` or `didAcquireView` after
  // state of component is updated.
  XCTAssertEqual(fooComponent.controller.counts.willRelinquishView, 0);
  XCTAssertEqual(fooComponent.controller.counts.didAcquireView, 1);
}


- (void)testThatResponderChainIsInOrderComponentThenControllerThenRootView
{
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:componentProvider
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
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:componentProvider
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
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:componentProvider
                                                                                                                             sizeRangeProvider:nil];
  UIView *view = [UIView new];

  CKLifecycleTestComponentSetShouldEarlyReturnNew(YES);

  const CKComponentLifecycleTestHelperState state1 = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                     constrainedSize:{{0,0}, {100, 100}}
                                                                                                             context:nil];
  [componentLifecycleTestController updateWithState:state1];
  [componentLifecycleTestController attachToView:view];

  CKLifecycleTestComponentSetShouldEarlyReturnNew(NO);

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
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:componentProvider
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
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:componentProvider
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
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:componentProvider
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
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:componentProvider
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

- (void)testComponentControllerReceivesDidInitEvent
{
  CKComponentLifecycleTestHelper *componentLifecycleTestController =
    [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:componentProvider sizeRangeProvider:nil];
  const CKComponentLifecycleTestHelperState state =
    [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                constrainedSize:{{0,0}, {100, 100}}
                                                        context:nil];

  [componentLifecycleTestController attachToView:[UIView new]];
  [componentLifecycleTestController updateWithState:state];
  CKComponentScopeRootAnnounceControllerInitialization([componentLifecycleTestController state].scopeRoot);
  CKLifecycleTestComponent *fooComponent = (CKLifecycleTestComponent *)state.componentLayout.component;
  XCTAssertTrue(fooComponent.controller.calledDidInit,
                @"Expected component controller to get did init event");
}

- (void)testComponentControllerReceivesInvalidateEvent
{
  CKComponentLifecycleTestHelper *componentLifecycleTestController =
    [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:componentProvider sizeRangeProvider:nil];
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

- (void)testRemovedComponentControllersFromPreviousScopeRootMatchingPredicate
{
  // `CKLifecycleTestComponentController` has `invalidateController` implemented.
  const auto componentController1 = [[CKLifecycleTestComponentController alloc] initWithComponent:nil];
  const auto componentController2 = [[CKLifecycleTestComponentController alloc] initWithComponent:nil];

  const auto previousScopeRoot =
  [CKComponentScopeRoot
   rootWithListener:nil
   analyticsListener:nil
   componentPredicates:{}
   componentControllerPredicates:{&CKComponentControllerInvalidateEventPredicate}];
  [previousScopeRoot registerComponentController:componentController1];
  [previousScopeRoot registerComponentController:componentController2];
  const auto newScopeRoot = [previousScopeRoot newRoot];
  [newScopeRoot registerComponentController:componentController1];

  // New scope root doesn't have `componentController2` registered.
  const auto removedComponentControllers =
  removedControllersFromPreviousScopeRootMatchingPredicate(newScopeRoot,
                                                           previousScopeRoot,
                                                           &CKComponentControllerInvalidateEventPredicate);
  XCTAssertEqual(removedComponentControllers[0], componentController2);
}

- (void)testRemovedComponentControllersAreEmptyFromPreviousScopeRootMatchingPredicate
{
  // `CKLifecycleTestComponentController` has `invalidateController` implemented.
  const auto componentController1 = [[CKLifecycleTestComponentController alloc] initWithComponent:nil];
  const auto componentController2 = [[CKLifecycleTestComponentController alloc] initWithComponent:nil];

  const auto previousScopeRoot =
  [CKComponentScopeRoot
   rootWithListener:nil
   analyticsListener:nil
   componentPredicates:{}
   componentControllerPredicates:{&CKComponentControllerInvalidateEventPredicate}];
  [previousScopeRoot registerComponentController:componentController1];
  [previousScopeRoot registerComponentController:componentController2];
  const auto newScopeRoot = [previousScopeRoot newRoot];
  [newScopeRoot registerComponentController:componentController1];
  [newScopeRoot registerComponentController:componentController2];

  // Both component controllers are presented in new scope root.
  const auto removedComponentControllers =
  removedControllersFromPreviousScopeRootMatchingPredicate(newScopeRoot,
                                                           previousScopeRoot,
                                                           &CKComponentControllerInvalidateEventPredicate);
  XCTAssertTrue(removedComponentControllers.empty());
}

- (void)testRemovedComponentControllersAreEmptyWhenPreviousScopeRootIsNil
{
  const auto scopeRoot =
  [CKComponentScopeRoot
   rootWithListener:nil
   analyticsListener:nil
   componentPredicates:{}
   componentControllerPredicates:{&CKComponentControllerInvalidateEventPredicate}];

  const auto removedComponentControllers =
  removedControllersFromPreviousScopeRootMatchingPredicate(scopeRoot,
                                                           nil,
                                                           &CKComponentControllerInvalidateEventPredicate);
  XCTAssertTrue(removedComponentControllers.empty());
}

- (void)testRemovedComponentControllersFromPreviousScopeRootNotMatchingPredicate
{
  const auto componentController = [[CKEmptyComponentController alloc] initWithComponent:nil];

  const auto previousScopeRoot =
  [CKComponentScopeRoot
   rootWithListener:nil
   analyticsListener:nil
   componentPredicates:{}
   componentControllerPredicates:{&CKComponentControllerInvalidateEventPredicate}];
  [previousScopeRoot registerComponentController:componentController];
  const auto newScopeRoot = [previousScopeRoot newRoot];

  // `componentController` doesn't match predicate.
  const auto removedComponentControllers =
  removedControllersFromPreviousScopeRootMatchingPredicate(newScopeRoot,
                                                           previousScopeRoot,
                                                           &CKComponentControllerInvalidateEventPredicate);
  XCTAssertTrue(removedComponentControllers.empty());
}

- (void)testDidUpdateComponentIsCalledOnMountIfCommponentIsNotUpdatedWithSetter
{
  const auto component1 = [CKLifecycleTestComponent new];
  const auto component2 = [CKLifecycleTestComponent new];
  const auto controller = [[CKLifecycleTestComponentController alloc] initWithComponent:component1];
  XCTAssertEqual(controller.calledWillUpdateComponent, 0);
  XCTAssertEqual(controller.calledDidUpdateComponent, 0);
  [controller componentWillMount:component2];
  XCTAssertEqual(controller.calledWillUpdateComponent, 1);
  XCTAssertEqual(controller.calledDidUpdateComponent, 0);
  [controller componentDidMount:component2];
  XCTAssertEqual(controller.calledWillUpdateComponent, 1);
  XCTAssertEqual(controller.calledDidUpdateComponent, 1);
}

- (void)testDidUpdateComponentIsCalledOnMountIfCommponentIsUpdatedWithSetter
{
  const auto component1 = [CKLifecycleTestComponent new];
  const auto component2 = [CKLifecycleTestComponent new];
  const auto controller = [[CKLifecycleTestComponentController alloc] initWithComponent:component1];
  XCTAssertEqual(controller.calledWillUpdateComponent, 0);
  XCTAssertEqual(controller.calledDidUpdateComponent, 0);
  controller.latestComponent = component2;
  XCTAssertEqual(controller.calledWillUpdateComponent, 1);
  XCTAssertEqual(controller.calledDidUpdateComponent, 0);
  [controller componentWillMount:component2];
  XCTAssertEqual(controller.calledWillUpdateComponent, 1);
  XCTAssertEqual(controller.calledDidUpdateComponent, 0);
  [controller componentDidMount:component2];
  XCTAssertEqual(controller.calledWillUpdateComponent, 1);
  XCTAssertEqual(controller.calledDidUpdateComponent, 1);
}

@end

@implementation CKEmptyComponentController
@end
