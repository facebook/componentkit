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
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKIdValueWrapper.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKDelayedInitialisationWrapper.h>
#import <ComponentKit/CKThreadLocalComponentScope.h>
#import <ComponentKitTestHelpers/CKAnalyticsListenerSpy.h>
#import <ComponentKitTestHelpers/CKTestRunLoopRunning.h>
#import <ComponentKitTestHelpers/CKRenderComponentTestHelpers.h>

@interface CKComponentGeneratorTests : XCTestCase <CKComponentGeneratorDelegate>

@end

@interface CKTestStateComponent : CKCompositeComponent

+ (instancetype)new;

@property (nonatomic, readonly, strong) id state;

@end

@interface VerificationModel : NSObject
@property (nonatomic, readwrite) BOOL verified;
@end

@implementation VerificationModel
@end

@implementation CKComponentGeneratorTests
{
  CK::Optional<CKBuildComponentResult> _asyncComponentGenerationResult;
  BOOL _didReceiveComponentStateUpdate;
}

static CKComponent *verificationComponentProvider(id<NSObject> m, id<NSObject> c)
{
  VerificationModel *model = (VerificationModel *)m;
  model.verified = YES;

  VerificationModel *context = (VerificationModel *)c;
  context.verified = YES;
  return CK::ComponentBuilder()
                  .build();
}

- (void)testUpdateModelAndContext_ModelAndContextAreUsedInComponentProvider
{
  const auto model = [VerificationModel new];
  const auto context = [VerificationModel new];
  const auto componentGenerator =
  [[CKComponentGenerator alloc]
   initWithOptions:{
     .delegate = CK::makeNonNull(self),
     .componentProvider = CK::makeNonNull(verificationComponentProvider),
   }];
  [componentGenerator updateModel:model];
  [componentGenerator updateContext:context];
  [componentGenerator generateComponentSynchronously];
  XCTAssertTrue(model.verified);
  XCTAssertTrue(context.verified);
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
    return _asyncComponentGenerationResult.hasValue();
  });
}

- (void)testIgnoreComponentReuseInNextGeneration_ComponentIsNotReused
{
  const auto componentGenerator = [self createComponentGenerator];
  const auto result1 = [componentGenerator generateComponentSynchronously];
  XCTAssertFalse(((CKTestRenderComponent *)result1.component).didReuseComponent);
  const auto result2 = [componentGenerator generateComponentSynchronously];
  XCTAssertTrue(((CKTestRenderComponent *)result2.component).didReuseComponent);
  [componentGenerator forceReloadInNextGeneration];
  const auto result3 = [componentGenerator generateComponentSynchronously];
  XCTAssertFalse(((CKTestRenderComponent *)result3.component).didReuseComponent);
}

- (void)testComponentStateUpdate_StateUpdateIsReceivedInDelegate
{
  const auto componentGenerator =
  [[CKComponentGenerator alloc]
   initWithOptions:{
     .delegate = CK::makeNonNull(self),
     .componentProvider = CK::makeNonNull([](id<NSObject> m, id<NSObject> c) -> CKComponent *{
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

- (void)test_WhenReceivesStateUpdate_ReportsToAnalyticsListener
{
  const auto analyticsListenerSpy = [CKAnalyticsListenerSpy new];
  const auto componentGenerator =
  [[CKComponentGenerator alloc] initWithOptions:{
    .delegate = CK::makeNonNull(self),
    .componentProvider = CK::makeNonNull([](id<NSObject> m, id<NSObject> c) -> CKComponent *{
      return [CKTestStateComponent new];
    }),
    .analyticsListener = analyticsListenerSpy
  }];
  const auto result1 = [componentGenerator generateComponentSynchronously];

  [result1.component updateState:^(id currentState) { return currentState; } mode:CKUpdateModeSynchronous];

  const auto event = analyticsListenerSpy.events.front();
  event.match([&](CK::AnalyticsListenerSpy::DidReceiveStateUpdate drsu){
    XCTAssertEqual(drsu.handle, result1.component.scopeHandle);
    XCTAssertEqual(drsu.rootID, [result1.scopeRoot globalIdentifier]);
  });
}

- (void)test_WhenReceivedPropsUpdateAndStateUpdate_BuildTriggerShouldBePropsUpdate
{
  const auto componentGenerator =
  [[CKComponentGenerator alloc] initWithOptions:{
    .delegate = CK::makeNonNull(self),
    .componentProvider = CK::makeNonNull([](id<NSObject> m, id<NSObject> c) -> CKComponent *{
      if (m != [NSNull null]) {
        auto& model = CKIdValueWrapperGet<CKBuildTrigger>(m);
        model = CKThreadLocalComponentScope::currentScope()->buildTrigger;
      }
      return CK::ComponentBuilder().build();
    }),
  }];

  // NewTree
  [componentGenerator updateModel:[NSNull null]];
  [componentGenerator updateContext:@1];
  [componentGenerator generateComponentSynchronously];

  // State Update + Props Update
  auto modelWrapper = CKIdValueWrapperNonEquatableCreate(CKBuildTrigger{});
  [componentGenerator updateModel:modelWrapper];
  const auto stateUpdateListenner = (id<CKComponentStateListener>)componentGenerator;
  [stateUpdateListenner componentScopeHandle:nil
                              rootIdentifier:42
                       didReceiveStateUpdate:^id(id) {
    return nil;
  } metadata:{} mode:CKUpdateModeAsynchronous];
  [componentGenerator generateComponentSynchronously];

  const auto buildTrigger = CKIdValueWrapperGet<CKBuildTrigger>(modelWrapper);
  XCTAssertEqual(buildTrigger, CKBuildTriggerPropsUpdate | CKBuildTriggerStateUpdate);
}

#pragma mark - Helpers

- (CKComponentGenerator *)createComponentGenerator
{
  return
  [[CKComponentGenerator alloc]
   initWithOptions:{
     .delegate = CK::makeNonNull(self),
     .componentProvider = CK::makeNonNull(
       [](id<NSObject> m, id<NSObject> c) -> CKComponent * {
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
