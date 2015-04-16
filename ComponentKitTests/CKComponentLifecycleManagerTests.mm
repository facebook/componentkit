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

#import "CKComponent.h"
#import "CKComponentAnimation.h"
#import "CKComponentController.h"
#import "CKComponentLifecycleManager.h"
#import "CKComponentProvider.h"
#import "CKComponentScope.h"
#import "CKComponentViewInterface.h"
#import "CKCompositeComponent.h"

static BOOL notified;

@interface CKCoolComponent : CKCompositeComponent
@property (readwrite, nonatomic, weak) CKComponentController *controller;
+ (instancetype)newCoolComponentWithModel:(id<NSObject>)model;
@end

@implementation CKCoolComponent
+ (instancetype)newCoolComponentWithModel:(id<NSObject>)model
{
  CKComponentScope scope(self);
  return [super newWithComponent:
          [CKComponent
           newWithView:{[UIView class], {{@selector(setBackgroundColor:), (UIColor *)model}}}
           size:{}]];
}
@end

@interface CKCoolComponentController : CKComponentController
@end

@implementation CKCoolComponentController
- (void)componentTreeWillAppear
{
  [super componentTreeWillAppear];
  notified = YES;
}

- (void)didUpdateComponent
{
  [super didUpdateComponent];
  ((CKCoolComponent *)self.component).controller = self;
}

@end

@interface CKComponentLifecycleManagerTests : XCTestCase <CKComponentProvider, CKComponentLifecycleManagerDelegate>
@end

@implementation CKComponentLifecycleManagerTests {
  BOOL _calledLifecycleManagerSizeDidChange;
}

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [CKCoolComponent newCoolComponentWithModel:model];
}

static const CKSizeRange size = {{40, 40}, {40, 40}};

- (void)tearDown
{
  _calledLifecycleManagerSizeDidChange = NO;
  [super tearDown];
}

- (void)testRepeatedPrepareForUpdateWithoutMountingConstructsNewComponents
{
  NSObject *model = [UIColor clearColor];
  CKComponentLifecycleManager *lifeManager = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class]];

  CKComponentLifecycleManagerState stateA = [lifeManager prepareForUpdateWithModel:model constrainedSize:size context:nil];
  CKCoolComponent *componentA = (CKCoolComponent *)stateA.layout.component;

  CKComponentLifecycleManagerState stateB = [lifeManager prepareForUpdateWithModel:model constrainedSize:size context:nil];
  CKCoolComponent *componentB = (CKCoolComponent *)stateB.layout.component;

  XCTAssertTrue(componentA != componentB);
}

- (void)testRepeatedPrepareForUpdateWithoutMountingUsesPreviouslyComputedState
{
  NSObject *model = [UIColor clearColor];
  CKComponentLifecycleManager *lifeManager = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class]];

  CKComponentLifecycleManagerState stateA = [lifeManager prepareForUpdateWithModel:model constrainedSize:size context:nil];
  CKCoolComponent *componentA = (CKCoolComponent *)stateA.layout.component;
  CKComponentController *controllerA = componentA.controller;

  CKComponentLifecycleManagerState stateB = [lifeManager prepareForUpdateWithModel:model constrainedSize:size context:nil];
  CKCoolComponent *componentB = (CKCoolComponent *)stateB.layout.component;
  CKComponentController *controllerB = componentB.controller;

  XCTAssertTrue(controllerA == controllerB);
}

- (void)testAttachingManagerInsertsComponentViewInHierarchy
{
  NSObject *model = [UIColor clearColor];
  CKComponentLifecycleManager *lifeManager = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class]];
  [lifeManager updateWithState:[lifeManager prepareForUpdateWithModel:model constrainedSize:size context:nil]];

  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 40.0, 40.0)];

  XCTAssertTrue([view.subviews count] == 0, @"Expect an empty view before mounting");
  [lifeManager attachToView:view];
  XCTAssertTrue([view.subviews count] > 0, @"Does not expect an empty view after mounting");
}

- (void)testIsAttachedToView
{
  NSObject *model = [UIColor clearColor];
  CKComponentLifecycleManager *lifeManager = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class]];
  [lifeManager updateWithState:[lifeManager prepareForUpdateWithModel:model constrainedSize:size context:nil]];

  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 40.0, 40.0)];
  XCTAssertFalse([lifeManager isAttachedToView], @"Expect -isAttachedToView to be false before mounting.");
  [lifeManager attachToView:view];
  XCTAssertTrue([lifeManager isAttachedToView], @"Expect -isAttachedToView to be true after mounting.");
}

- (void)testAttachingManagerToViewAlreadyAttachedToAnotherManagerChangesViewManagerToNewManager
{
  CKComponentLifecycleManager *firstLifeManager = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class]];
  [firstLifeManager updateWithState:[firstLifeManager prepareForUpdateWithModel:[UIColor redColor] constrainedSize:size context:nil]];
  CKComponentLifecycleManager *secondLifeManager = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class]];
  [secondLifeManager updateWithState:[secondLifeManager prepareForUpdateWithModel:[UIColor blueColor] constrainedSize:size context:nil]];

  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 40.0, 40.0)];
  [firstLifeManager attachToView:view];
  [secondLifeManager attachToView:view];
  XCTAssertEqualObjects(view.ck_componentLifecycleManager, secondLifeManager, @"Expect ck_componentLifecycleManager to point to previous manager");
}

- (void)testAttachingManagerToViewAlreadyAttachedToAnotherManagerMountsTheCorrectComponent
{
  NSObject *firstModel = [UIColor redColor];
  NSObject *secondModel = [UIColor blueColor];
  CKComponentLifecycleManager *firstLifeManager = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class]];
  [firstLifeManager updateWithState:[firstLifeManager prepareForUpdateWithModel:firstModel constrainedSize:size context:nil]];
  CKComponentLifecycleManager *secondLifeManager = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class]];
  [secondLifeManager updateWithState:[secondLifeManager prepareForUpdateWithModel:secondModel constrainedSize:size context:nil]];

  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 40.0, 40.0)];

  [firstLifeManager attachToView:view];
  [secondLifeManager attachToView:view];
  XCTAssertEqualObjects([[view.subviews firstObject] backgroundColor], secondModel, @"Expect the last component mounted to be rendered in the view");
}

- (void)testUpdatingAManagerDetachedByNewManagerDoesNotUpdateViewAttachedToNewManager
{
  CKComponentLifecycleManager *firstLifeManager = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class]];
  [firstLifeManager updateWithState:[firstLifeManager prepareForUpdateWithModel:[UIColor redColor] constrainedSize:size context:nil]];
  CKComponentLifecycleManager *secondLifeManager = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class]];
  [secondLifeManager updateWithState:[secondLifeManager prepareForUpdateWithModel:[UIColor blueColor] constrainedSize:size context:nil]];

  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 40.0, 40.0)];
  [firstLifeManager attachToView:view];
  [secondLifeManager attachToView:view];

  [firstLifeManager updateWithState:[firstLifeManager prepareForUpdateWithModel:[UIColor greenColor] constrainedSize:size context:nil]];
  XCTAssertEqualObjects([[view.subviews firstObject] backgroundColor], [UIColor blueColor],
                        @"Expect the last manager attached to the view to be controlling color, not the first manager");
}

- (void)testUpdatingAManagerAfterDetachDoesNotUpdateView
{
  CKComponentLifecycleManager *lifeManager = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class]];
  [lifeManager updateWithState:[lifeManager prepareForUpdateWithModel:[UIColor redColor] constrainedSize:size context:nil]];

  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 40.0, 40.0)];
  [lifeManager attachToView:view];
  [lifeManager detachFromView];

  [lifeManager updateWithState:[lifeManager prepareForUpdateWithModel:[UIColor greenColor] constrainedSize:size context:nil]];
  XCTAssertEqualObjects([[view.subviews firstObject] backgroundColor], [UIColor redColor],
                        @"Expect the manager to leave view untouched after detach");
}

- (void)testCallingUpdateWithStateTriggersSizeDidChangeCallback
{
  CKComponentLifecycleManager *lifeManager = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class]];
  [lifeManager setDelegate:self];
  [lifeManager updateWithState:[lifeManager prepareForUpdateWithModel:[UIColor redColor] constrainedSize:size context:nil]];
  XCTAssertTrue(_calledLifecycleManagerSizeDidChange, @"Expect the manager to be notified when the size changes as a result of a call to -updateWithState:");
}

- (void)testCallingUpdateWithStateWithoutMountingDoesNotTriggerSizeDidChangeCallback
{
  CKComponentLifecycleManager *lifeManager = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class]];
  [lifeManager setDelegate:self];
  [lifeManager updateWithStateWithoutMounting:[lifeManager prepareForUpdateWithModel:[UIColor redColor] constrainedSize:size context:nil]];

  // It is important that that -componentLifecycleManager:sizeDidChangeWithAnimation: is not called when calling
  // -updateWithStateWithoutMounting:, because this would result in nested -beginUpdates/-endUpdates
  // calls inside CKComponentDataSource.
  XCTAssertFalse(_calledLifecycleManagerSizeDidChange, @"Expect the manager to NOT be notified of size changes as a result of a call to -updateWithStateWithoutMounting:");
}

#pragma mark - CKComponentLifecycleManagerDelegate

- (void)componentLifecycleManager:(CKComponentLifecycleManager *)manager
       sizeDidChangeWithAnimation:(const CKComponentBoundsAnimation &)animation
{
  _calledLifecycleManagerSizeDidChange = YES;
}

@end
