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
#import <ComponentKit/CKComponentGenerator.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKitTestHelpers/CKTestRunLoopRunning.h>
#import <ComponentKitTestHelpers/CKRenderComponentTestHelpers.h>

@interface CKComponentGeneratorTests : XCTestCase <CKComponentGeneratorDelegate>

@end

@interface CKTestStateComponent : CKCompositeComponent

+ (instancetype)new;

@property (nonatomic, readonly, strong) id state;

@end

@implementation CKComponentGeneratorTests
{
  CKBuildComponentResult _asyncComponentGenerationResult;
  BOOL _didReceiveComponentStateUpdate;
}

- (void)testUpdateModelAndContext_ModelAndContextAreUsedInComponentProvider
{
  const auto model = [NSObject new];
  const auto context = [NSObject new];
  __block BOOL modelVerified = NO;
  __block BOOL contextVerified = NO;
  const auto componentGenerator =
  [[CKComponentGenerator alloc]
   initWithOptions:{
     .delegate = CK::makeNonNull(self),
     .componentProvider = CK::makeNonNull(^(id<NSObject> m, id<NSObject> c) {
       modelVerified = model == m;
       contextVerified = context == c;
       return CK::ComponentBuilder()
                  .build();
     }),
   }];
  [componentGenerator updateModel:model];
  [componentGenerator updateContext:context];
  [componentGenerator generateComponentSynchronously];
  XCTAssertTrue(modelVerified);
  XCTAssertTrue(contextVerified);
}

- (void)testGenerateComponentSynchronously_ComponentResultIsReturned
{
  const auto componentGenerator = [self createComponentGenerator];
  const auto result = [componentGenerator generateComponentSynchronously];
  XCTAssertNotNil(result.component, @"Component is not generated after calling `generateComponentSynchronously`");
}

- (void)testGenerateComponentAynchronously_ComponentResultIsReturnedInDelegate
{
  const auto componentGenerator = [self createComponentGenerator];
  [componentGenerator generateComponentAsynchronously];
  CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _asyncComponentGenerationResult.component != nil;
  });
}

- (void)testIgnoreComponentReuseInNextGeneration_ComponentIsNotReused
{
  const auto componentGenerator = [self createComponentGenerator];
  const auto result1 = [componentGenerator generateComponentSynchronously];
  XCTAssertFalse(((CKTestRenderComponent *)result1.component).didReuseComponent);
  const auto result2 = [componentGenerator generateComponentSynchronously];
  XCTAssertTrue(((CKTestRenderComponent *)result2.component).didReuseComponent);
  [componentGenerator ignoreComponentReuseInNextGeneration];
  const auto result3 = [componentGenerator generateComponentSynchronously];
  XCTAssertFalse(((CKTestRenderComponent *)result3.component).didReuseComponent);
}

- (void)testComponentStateUpdate_StateUpdateIsReceivedInDelegate
{
  const auto componentGenerator =
  [[CKComponentGenerator alloc]
   initWithOptions:{
     .delegate = CK::makeNonNull(self),
     .componentProvider = CK::makeNonNull(^(id<NSObject> m, id<NSObject> c) {
       return [CKTestStateComponent new];
     }),
   }];
  const auto result1 = [componentGenerator generateComponentSynchronously];
  XCTAssertFalse(_didReceiveComponentStateUpdate);
  XCTAssertNil(((CKTestStateComponent *)result1.component).state, @"State should be nil before triggering state update");
  const auto state = [NSObject new];
  [result1.component updateState:^(id currentState) { return state; } mode:CKUpdateModeSynchronous];
  XCTAssertTrue(_didReceiveComponentStateUpdate);
  const auto result2 = [componentGenerator generateComponentSynchronously];
  XCTAssertEqual(state, ((CKTestStateComponent *)result2.component).state);
}

#pragma mark - Helpers

- (CKComponentGenerator *)createComponentGenerator
{
  return
  [[CKComponentGenerator alloc]
   initWithOptions:{
     .delegate = CK::makeNonNull(self),
     .componentProvider = CK::makeNonNull(^(id<NSObject> m, id<NSObject> c) {
       return [CKTestRenderComponent newWithProps:{}];
     }),
   }];
}

#pragma mark - CKComponentGeneratorDelegate

- (BOOL)componentGeneratorShouldApplyAsynchronousGenerationResult:(CKComponentGenerator *)componentGenerator
{
  return YES;
}

- (void)componentGenerator:(CKComponentGenerator *)componentGenerator didReceiveComponentStateUpdateWithMode:(CKUpdateMode)mode
{
  _didReceiveComponentStateUpdate = YES;
}

- (void)componentGenerator:(CKComponentGenerator *)componentGenerator didAsynchronouslyGenerateComponentResult:(CKBuildComponentResult)result
{
  _asyncComponentGenerationResult = result;
}

@end

@implementation CKTestStateComponent

+ (instancetype)new
{
  CKComponentScope scope(self);
  const auto c = [super newWithComponent:CK::ComponentBuilder()
                                             .build()];
  if (c) {
    c->_state = scope.state();
  }
  return c;
}

@end
