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

#import <ComponentKitTestLib/CKComponentTestRootScope.h>

#import "CKComponent.h"
#import "CKComponentController.h"
#import "CKComponentLifecycleManager.h"
#import "CKComponentProvider.h"
#import "CKComponentScope.h"
#import "CKComponentSubclass.h"
#import "CKComponentViewInterface.h"

@interface CKComponentControllerTests : XCTestCase <CKComponentProvider>
@end

@interface CKFooComponentController : CKComponentController
@property (nonatomic, assign) BOOL calledDidAcquireView;
@property (nonatomic, assign) BOOL calledWillRelinquishView;
@property (nonatomic, assign) BOOL calledDidUpdateComponent;
@end

@interface CKFooComponent : CKComponent
@property (nonatomic, weak) CKFooComponentController *controller;
- (void)updateStateToIncludeNewAttribute;
@end

@implementation CKComponentControllerTests

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [CKFooComponent new];
}

- (void)testThatCreatingComponentDoesNotInstantiateItsController
{
  CKComponentTestRootScope scope;

  CKFooComponent *fooComponent = [CKFooComponent new];
  XCTAssertNil(fooComponent.controller, @"Didn't expect creating a component to create a controller");
}

- (void)testThatAttachingManagerInstantiatesComponentController
{
  CKComponentLifecycleManager *clm = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class]];
  CKComponentLifecycleManagerState state = [clm prepareForUpdateWithModel:nil constrainedSize:{{0,0}, {100, 100}} context:nil];
  [clm updateWithState:state];

  UIView *view = [[UIView alloc] init];
  [clm attachToView:view];

  CKFooComponent *fooComponent = (CKFooComponent *)state.layout.component;
  XCTAssertNotNil(fooComponent.controller, @"Expected mounting a component to create controller");
}

- (void)testThatRemountingUnchangedComponentDoesNotCallDidUpdateComponent
{
  CKComponentLifecycleManager *clm = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class]];
  CKComponentLifecycleManagerState state = [clm prepareForUpdateWithModel:nil constrainedSize:{{0,0}, {100, 100}} context:nil];
  [clm updateWithState:state];

  UIView *view = [[UIView alloc] init];
  [clm attachToView:view];

  CKFooComponent *fooComponent = (CKFooComponent *)state.layout.component;
  CKFooComponentController *controller = fooComponent.controller;

  [clm detachFromView];
  controller.calledDidUpdateComponent = NO; // Reset to NO
  [clm attachToView:view];
  XCTAssertFalse(controller.calledDidUpdateComponent, @"Component did not update so should not call didUpdateComponent");
}

- (void)testThatUpdatingManagerUpdatesComponentController
{
  CKComponentLifecycleManager *clm = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class]];
  UIView *view = [[UIView alloc] init];

  CKComponentLifecycleManagerState state1 = [clm prepareForUpdateWithModel:nil constrainedSize:{{0,0}, {100, 100}} context:nil];
  [clm updateWithState:state1];
  [clm attachToView:view];
  CKFooComponent *fooComponent1 = (CKFooComponent *)state1.layout.component;

  CKComponentLifecycleManagerState state2 = [clm prepareForUpdateWithModel:nil constrainedSize:{{0,0}, {100, 100}} context:nil];
  [clm updateWithState:state2];
  CKFooComponent *fooComponent2 = (CKFooComponent *)state1.layout.component;

  XCTAssertTrue(fooComponent1.controller == fooComponent2.controller,
                @"Expected controller %@ to match %@",
                fooComponent1.controller, fooComponent2.controller);
}

- (void)testThatAttachingManagerCallsDidAcquireView
{
  CKComponentLifecycleManager *clm = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class]];
  CKComponentLifecycleManagerState state = [clm prepareForUpdateWithModel:nil constrainedSize:{{0,0}, {100, 100}} context:nil];
  [clm updateWithState:state];

  UIView *view = [[UIView alloc] init];
  [clm attachToView:view];

  CKFooComponent *fooComponent = (CKFooComponent *)state.layout.component;
  XCTAssertTrue(fooComponent.controller.calledDidAcquireView, @"Expected mounting to acquire view");
  XCTAssertNotNil(fooComponent.controller.view, @"Expected mounting to acquire view");
}

- (void)testThatDetachingManagerCallsDidRelinquishView
{
  CKComponentLifecycleManager *clm = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class]];
  CKComponentLifecycleManagerState state = [clm prepareForUpdateWithModel:nil constrainedSize:{{0,0}, {100, 100}} context:nil];
  [clm updateWithState:state];

  UIView *view = [[UIView alloc] init];
  [clm attachToView:view];

  CKFooComponent *fooComponent = (CKFooComponent *)state.layout.component;
  XCTAssertFalse(fooComponent.controller.calledWillRelinquishView, @"Did not expect view to be released before detach");

  [clm detachFromView];
  XCTAssertTrue(fooComponent.controller.calledWillRelinquishView, @"Expected detach to call release view");
  XCTAssertNil(fooComponent.controller.view, @"Expected detach to release view");
}

- (void)testThatUpdatingStateWhileAttachedRelinquishesOldViewAndAcquiresNewOne
{
  CKComponentLifecycleManager *clm = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class]];
  CKComponentLifecycleManagerState state = [clm prepareForUpdateWithModel:nil constrainedSize:{{0,0}, {100, 100}} context:nil];
  [clm updateWithState:state];

  UIView *view = [[UIView alloc] init];
  [clm attachToView:view];

  CKFooComponent *fooComponent = (CKFooComponent *)state.layout.component;
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
  CKComponentLifecycleManager *clm = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class]];
  CKComponentLifecycleManagerState state = [clm prepareForUpdateWithModel:nil constrainedSize:{{0,0}, {100, 100}} context:nil];
  [clm updateWithState:state];

  UIView *view = [[UIView alloc] init];
  [clm attachToView:view];

  CKFooComponent *fooComponent = (CKFooComponent *)state.layout.component;
  XCTAssertEqualObjects([fooComponent nextResponder], fooComponent.controller,
                       @"Component's nextResponder should be component controller");
  XCTAssertEqualObjects([fooComponent.controller nextResponder], view,
                       @"Root component's controller's nextResponder should be root view");
}

- (void)testThatResponderChainTargetsCorrectResponder
{
  CKComponentLifecycleManager *clm = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class]];
  CKComponentLifecycleManagerState state = [clm prepareForUpdateWithModel:nil constrainedSize:{{0,0}, {100, 100}} context:nil];
  [clm updateWithState:state];
  
  UIView *view = [[UIView alloc] init];
  [clm attachToView:view];
  
  CKFooComponent *fooComponent = (CKFooComponent *)state.layout.component;
  XCTAssertEqualObjects([fooComponent targetForAction:nil withSender:fooComponent], fooComponent, @"Component should respond to this action");
  XCTAssertEqualObjects([fooComponent targetForAction:nil withSender:nil], fooComponent.controller, @"Component's controller should respond to this action");
}

@end


@implementation CKFooComponent

+ (id)initialState
{
  return @NO;
}

+ (instancetype)new
{
  CKComponentScope scope(self); // components with controllers must have a scope
  CKViewComponentAttributeValueMap attrs;
  if ([scope.state() boolValue]) {
    attrs.insert({@selector(setBackgroundColor:), [UIColor redColor]});
  }
  return [super newWithView:{[UIView class], std::move(attrs)} size:{}];
}

- (void)updateStateToIncludeNewAttribute
{
  [self updateState:^(id oldState){
    return @YES;
  }];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
  if (sender == self)
    return YES;
  return NO;
}

@end

@implementation CKFooComponentController

- (void)didUpdateComponent
{
  [super didUpdateComponent];
  ((CKFooComponent *)self.component).controller = self;
  _calledDidUpdateComponent = YES;
}

- (void)componentWillRelinquishView
{
  [super componentWillRelinquishView];
  _calledWillRelinquishView = YES;
}

- (void)componentDidAcquireView
{
  [super componentDidAcquireView];
  _calledDidAcquireView = YES;
}

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
  return YES;
}

@end
