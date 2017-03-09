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

#import <ComponentKitTestHelpers/CKComponentLifecycleTestController.h>
#import <ComponentKitTestHelpers/CKComponentTestRootScope.h>

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentController.h>
#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/CKComponentScope.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKThreadLocalComponentScope.h>

@interface CKComponentControllerTests : XCTestCase <CKComponentProvider>
@end

@interface CKFooComponentController : CKComponentController
@property (nonatomic, assign) BOOL calledDidAcquireView;
@property (nonatomic, assign) BOOL calledWillRelinquishView;
@property (nonatomic, assign) BOOL calledComponentTreeWillAppear;
@property (nonatomic, assign) BOOL calledComponentTreeDidDisappear;
@property (nonatomic, assign) BOOL calledDidUpdateComponent;
@end

@interface CKFooComponent : CKComponent
+ (void)setShouldEarlyReturnNew:(BOOL)shouldEarlyReturnNew;
- (CKFooComponentController *)controller;
- (void)updateStateToIncludeNewAttribute;
@end

@implementation CKComponentControllerTests

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [CKFooComponent new];
}

- (void)testThatCreatingComponentCreatesAController
{
  CKComponentTestRootScope scope;
  CKFooComponent *fooComponent = [CKFooComponent new];
  XCTAssertNotNil(fooComponent.controller);
}

- (void)testThatAttachingManagerInstantiatesComponentController
{
  CKComponentLifecycleTestController *componentLifecycleTestController = [[CKComponentLifecycleTestController alloc] initWithComponentProvider:[self class]
                                                                                                                             sizeRangeProvider:nil];
  const CKComponentLifecycleTestControllerState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                    constrainedSize:{{0,0}, {100, 100}}
                                                                                                            context:nil];
  [componentLifecycleTestController updateWithState:state];

  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];

  CKFooComponent *fooComponent = (CKFooComponent *)state.componentLayout.component;
  XCTAssertNotNil(fooComponent.controller, @"Expected mounting a component to create controller");
}

- (void)testThatRemountingUnchangedComponentDoesNotCallDidUpdateComponent
{
  CKComponentLifecycleTestController *componentLifecycleTestController = [[CKComponentLifecycleTestController alloc] initWithComponentProvider:[self class]
                                                                                                                             sizeRangeProvider:nil];
  const CKComponentLifecycleTestControllerState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                    constrainedSize:{{0,0}, {100, 100}}
                                                                                                            context:nil];
  [componentLifecycleTestController updateWithState:state];

  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];

  CKFooComponent *fooComponent = (CKFooComponent *)state.componentLayout.component;
  CKFooComponentController *controller = fooComponent.controller;

  [componentLifecycleTestController detachFromView];
  controller.calledDidUpdateComponent = NO; // Reset to NO
  [componentLifecycleTestController attachToView:view];
  XCTAssertFalse(controller.calledDidUpdateComponent, @"Component did not update so should not call didUpdateComponent");
}

- (void)testThatUpdatingManagerUpdatesComponentController
{
  CKComponentLifecycleTestController *componentLifecycleTestController = [[CKComponentLifecycleTestController alloc] initWithComponentProvider:[self class]
                                                                                                                             sizeRangeProvider:nil];
  UIView *view = [UIView new];

  const CKComponentLifecycleTestControllerState state1 = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                     constrainedSize:{{0,0}, {100, 100}}
                                                                                                             context:nil];
  [componentLifecycleTestController updateWithState:state1];
  [componentLifecycleTestController attachToView:view];
  CKFooComponent *fooComponent1 = (CKFooComponent *)state1.componentLayout.component;

  const CKComponentLifecycleTestControllerState state2 = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                     constrainedSize:{{0,0}, {100, 100}}
                                                                                                             context:nil];
  [componentLifecycleTestController updateWithState:state2];
  CKFooComponent *fooComponent2 = (CKFooComponent *)state1.componentLayout.component;

  XCTAssertTrue(fooComponent1.controller == fooComponent2.controller,
                @"Expected controller %@ to match %@",
                fooComponent1.controller, fooComponent2.controller);
}

- (void)testThatAttachingManagerCallsDidAcquireView
{
  CKComponentLifecycleTestController *componentLifecycleTestController = [[CKComponentLifecycleTestController alloc] initWithComponentProvider:[self class]
                                                                                                                             sizeRangeProvider:nil];
  const CKComponentLifecycleTestControllerState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                    constrainedSize:{{0,0}, {100, 100}}
                                                                                                            context:nil];
  [componentLifecycleTestController updateWithState:state];

  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];

  CKFooComponent *fooComponent = (CKFooComponent *)state.componentLayout.component;
  XCTAssertTrue(fooComponent.controller.calledDidAcquireView, @"Expected mounting to acquire view");
  XCTAssertNotNil(fooComponent.controller.view, @"Expected mounting to acquire view");
}

- (void)testThatDetachingManagerCallsDidRelinquishView
{
  CKComponentLifecycleTestController *componentLifecycleTestController = [[CKComponentLifecycleTestController alloc] initWithComponentProvider:[self class]
                                                                                                                             sizeRangeProvider:nil];
  const CKComponentLifecycleTestControllerState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                    constrainedSize:{{0,0}, {100, 100}}
                                                                                                            context:nil];
  [componentLifecycleTestController updateWithState:state];

  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];

  CKFooComponent *fooComponent = (CKFooComponent *)state.componentLayout.component;
  XCTAssertFalse(fooComponent.controller.calledWillRelinquishView, @"Did not expect view to be released before detach");

  [componentLifecycleTestController detachFromView];
  XCTAssertTrue(fooComponent.controller.calledWillRelinquishView, @"Expected detach to call release view");
  XCTAssertNil(fooComponent.controller.view, @"Expected detach to release view");
}

- (void)testThatUpdatingStateWhileAttachedRelinquishesOldViewAndAcquiresNewOne
{
  CKComponentLifecycleTestController *componentLifecycleTestController = [[CKComponentLifecycleTestController alloc] initWithComponentProvider:[self class]
                                                                                                                             sizeRangeProvider:nil];
  const CKComponentLifecycleTestControllerState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                    constrainedSize:{{0,0}, {100, 100}}
                                                                                                            context:nil];
  [componentLifecycleTestController updateWithState:state];

  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];

  CKFooComponent *fooComponent = (CKFooComponent *)state.componentLayout.component;
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
  CKComponentLifecycleTestController *componentLifecycleTestController = [[CKComponentLifecycleTestController alloc] initWithComponentProvider:[self class]
                                                                                                                             sizeRangeProvider:nil];
  const CKComponentLifecycleTestControllerState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                    constrainedSize:{{0,0}, {100, 100}}
                                                                                                            context:nil];
  [componentLifecycleTestController updateWithState:state];

  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];

  CKFooComponent *fooComponent = (CKFooComponent *)state.componentLayout.component;
  XCTAssertEqualObjects([fooComponent nextResponder], fooComponent.controller,
                       @"Component's nextResponder should be component controller");
  XCTAssertEqualObjects([fooComponent.controller nextResponder], view,
                       @"Root component's controller's nextResponder should be root view");
}

- (void)testThatResponderChainTargetsCorrectResponder
{
  CKComponentLifecycleTestController *componentLifecycleTestController = [[CKComponentLifecycleTestController alloc] initWithComponentProvider:[self class]
                                                                                                                             sizeRangeProvider:nil];
  const CKComponentLifecycleTestControllerState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                    constrainedSize:{{0,0}, {100, 100}}
                                                                                                            context:nil];
  [componentLifecycleTestController updateWithState:state];
  
  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];
  
  CKFooComponent *fooComponent = (CKFooComponent *)state.componentLayout.component;
  XCTAssertEqualObjects([fooComponent targetForAction:nil withSender:fooComponent], fooComponent, @"Component should respond to this action");
  XCTAssertEqualObjects([fooComponent targetForAction:nil withSender:nil], fooComponent.controller, @"Component's controller should respond to this action");
}

- (void)testThatEarlyReturnNew_fromFirstComponent_allowsComponentCreation_whenNotEarlyReturning_onStateUpdate
{
  CKComponentLifecycleTestController *componentLifecycleTestController = [[CKComponentLifecycleTestController alloc] initWithComponentProvider:[self class]
                                                                                                                             sizeRangeProvider:nil];
  UIView *view = [UIView new];

  [CKFooComponent setShouldEarlyReturnNew:YES];

  const CKComponentLifecycleTestControllerState state1 = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                     constrainedSize:{{0,0}, {100, 100}}
                                                                                                             context:nil];
  [componentLifecycleTestController updateWithState:state1];
  [componentLifecycleTestController attachToView:view];

  [CKFooComponent setShouldEarlyReturnNew:NO];

  const CKComponentLifecycleTestControllerState state2 = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                     constrainedSize:{{0,0}, {100, 100}}
                                                                                                             context:nil];
  [componentLifecycleTestController updateWithState:state2];
  CKFooComponent *fooComponent2 = (CKFooComponent *)state2.componentLayout.component;

  XCTAssertTrue([fooComponent2.controller isKindOfClass:[CKFooComponentController class]],
                @"Expected controller %@ to exist and be of type CKFooComponentController",
                fooComponent2.controller);
}

- (void)testThatComponentControllerReceivesComponentTreeWillAppearEvent
{
  CKComponentLifecycleTestController *componentLifecycleTestController = [[CKComponentLifecycleTestController alloc] initWithComponentProvider:[self class]
                                                                                                                             sizeRangeProvider:nil];
  const CKComponentLifecycleTestControllerState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                    constrainedSize:{{0,0}, {100, 100}}
                                                                                                            context:nil];
  [componentLifecycleTestController attachToView:[UIView new]];
  [componentLifecycleTestController updateWithState:state];
  [[componentLifecycleTestController state].scopeRoot announceEventToControllers:CKComponentAnnouncedEventTreeWillAppear];
  CKFooComponent *fooComponent = (CKFooComponent *)[componentLifecycleTestController state].componentLayout.component;
  XCTAssertTrue(fooComponent.controller.calledComponentTreeWillAppear,
                @"Expected controller %@ to have received component tree will appear event", fooComponent.controller);
}

- (void)testThatComponentControllerReceivesComponentTreeDidDisappearEvent
{
  CKComponentLifecycleTestController *componentLifecycleTestController = [[CKComponentLifecycleTestController alloc] initWithComponentProvider:[self class]
                                                                                                                             sizeRangeProvider:nil];
  const CKComponentLifecycleTestControllerState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                    constrainedSize:{{0,0}, {100, 100}}
                                                                                                            context:nil];
  [componentLifecycleTestController attachToView:[UIView new]];
  [componentLifecycleTestController updateWithState:state];
  [[componentLifecycleTestController state].scopeRoot announceEventToControllers:CKComponentAnnouncedEventTreeWillAppear];
  [componentLifecycleTestController detachFromView];
  [[componentLifecycleTestController state].scopeRoot announceEventToControllers:CKComponentAnnouncedEventTreeDidDisappear];
  CKFooComponent *fooComponent = (CKFooComponent *)[componentLifecycleTestController state].componentLayout.component;
  XCTAssertTrue(fooComponent.controller.calledComponentTreeDidDisappear,
                @"Expected controller %@ to have received component tree did disappear event", fooComponent.controller);
}

- (void)testThatComponentControllerReceivesComponentTreeWillAppearEventAfterAdditionalStateUpdates
{
  CKComponentLifecycleTestController *componentLifecycleTestController = [[CKComponentLifecycleTestController alloc] initWithComponentProvider:[self class]
                                                                                                                             sizeRangeProvider:nil];
  const CKComponentLifecycleTestControllerState state1 = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                     constrainedSize:{{0,0}, {100, 100}}
                                                                                                             context:nil];
  const CKComponentLifecycleTestControllerState state2 = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                     constrainedSize:{{0,0}, {100, 100}}
                                                                                                             context:nil];
  [componentLifecycleTestController attachToView:[UIView new]];
  [componentLifecycleTestController updateWithState:state1];
  [componentLifecycleTestController updateWithState:state2];
  [[componentLifecycleTestController state].scopeRoot announceEventToControllers:CKComponentAnnouncedEventTreeWillAppear];
  CKFooComponent *fooComponent = (CKFooComponent *)[componentLifecycleTestController state].componentLayout.component;
  XCTAssertTrue(fooComponent.controller.calledComponentTreeWillAppear,
                @"Expected controller %@ to have received component tree will appear event", fooComponent.controller);
}

- (void)testThatComponentControllerReceivesComponentTreeDidDisappearEventAfterAdditionalStateUpdates
{
  CKComponentLifecycleTestController *componentLifecycleTestController = [[CKComponentLifecycleTestController alloc] initWithComponentProvider:[self class]
                                                                                                                             sizeRangeProvider:nil];
  const CKComponentLifecycleTestControllerState state1 = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                     constrainedSize:{{0,0}, {100, 100}}
                                                                                                             context:nil];
  const CKComponentLifecycleTestControllerState state2 = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                     constrainedSize:{{0,0}, {100, 100}}
                                                                                                             context:nil];
  [componentLifecycleTestController attachToView:[UIView new]];
  [componentLifecycleTestController updateWithState:state1];
  [componentLifecycleTestController updateWithState:state2];
  [[componentLifecycleTestController state].scopeRoot announceEventToControllers:CKComponentAnnouncedEventTreeWillAppear];
  [componentLifecycleTestController detachFromView];
  [[componentLifecycleTestController state].scopeRoot announceEventToControllers:CKComponentAnnouncedEventTreeDidDisappear];
  CKFooComponent *fooComponent = (CKFooComponent *)[componentLifecycleTestController state].componentLayout.component;
  XCTAssertTrue(fooComponent.controller.calledComponentTreeDidDisappear,
                @"Expected controller %@ to have received component tree did disappear event", fooComponent.controller);
}

@end

@implementation CKFooComponent

static BOOL _shouldEarlyReturnNew = NO;

+ (void)setShouldEarlyReturnNew:(BOOL)shouldEarlyReturnNew
{
  _shouldEarlyReturnNew = shouldEarlyReturnNew;
}

+ (id)initialState
{
  return @NO;
}

+ (instancetype)new
{
  CKComponentScope scope(self); // components with controllers must have a scope
  if (_shouldEarlyReturnNew) {
    return nil;
  }
  CKViewComponentAttributeValueMap attrs;
  if ([scope.state() boolValue]) {
    attrs.insert({@selector(setBackgroundColor:), [UIColor redColor]});
  }
  return [super newWithView:{[UIView class], std::move(attrs)} size:{}];
}

- (CKFooComponentController *)controller
{
  // We provide this convenience method here to avoid having all the casts in the tests above.
  return (CKFooComponentController *)[super controller];
}

- (void)updateStateToIncludeNewAttribute
{
  [self updateState:^(id oldState){
    return @YES;
  } mode:CKUpdateModeSynchronous];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
  return (sender == self);
}

@end

@implementation CKFooComponentController

- (void)componentDidAcquireView
{
  [super componentDidAcquireView];
  _calledDidAcquireView = YES;
}

- (void)componentWillRelinquishView
{
  [super componentWillRelinquishView];
  _calledWillRelinquishView = YES;
}

- (void)componentTreeWillAppear
{
  [super componentTreeWillAppear];
  _calledComponentTreeWillAppear = YES;
}

- (void)componentTreeDidDisappear
{
  [super componentTreeDidDisappear];
  _calledComponentTreeDidDisappear = YES;
}

- (void)didUpdateComponent
{
  [super didUpdateComponent];
  _calledDidUpdateComponent = YES;
}

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
  return YES;
}

@end
