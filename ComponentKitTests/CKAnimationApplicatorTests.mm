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

#import <ComponentKit/CKAnimationApplicator.h>
#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentAnimationsController.h>

#import "CKAnimationSpy.h"
#import "CKComponentAnimationsEquality.h"
#import "TransactionProviderSpy.h"

@interface CKAnimationApplicatorTests : XCTestCase
@end

@implementation CKAnimationApplicatorTests {
  CKComponentAnimations testAnimations;
  std::vector<std::shared_ptr<CKAnimationSpy>> allSpies;
  std::shared_ptr<TransactionProviderSpy> transactionSpy;
  std::unique_ptr<CK::AnimationApplicator<TransactionProviderSpy>> applicator;
}

- (void)setUp
{
  [super setUp];
  // Shared pointers are used to keep instances of CKAnimationSpy that have been
  // captured by CKComponentAnimation hooks alive, otherwise they will capture references
  // to temporaries
  auto spiesForInitialAnimations = std::vector<std::shared_ptr<CKAnimationSpy>> {
    std::make_shared<CKAnimationSpy>(),
    std::make_shared<CKAnimationSpy>(),
  };
  auto spiesForChangeAnimations = std::vector<std::shared_ptr<CKAnimationSpy>> {
    std::make_shared<CKAnimationSpy>(),
    std::make_shared<CKAnimationSpy>(),
  };
  const auto initialAnimationsPairs = CK::map(spiesForInitialAnimations, [](auto s){
    return std::make_pair([CKComponent new], std::vector<CKComponentAnimation> {s->makeAnimation()});
  });
  const auto changeAnimationsPairs = CK::map(spiesForChangeAnimations, [](auto s){
    return std::make_pair([CKComponent new], std::vector<CKComponentAnimation> {s->makeAnimation()});
  });
  testAnimations = CKComponentAnimations {
    CKComponentAnimations::AnimationsByComponentMap(initialAnimationsPairs.begin(), initialAnimationsPairs.end()),
    CKComponentAnimations::AnimationsByComponentMap(changeAnimationsPairs.begin(), changeAnimationsPairs.end()),
    {},
  };
  allSpies = CK::chain(spiesForInitialAnimations, spiesForChangeAnimations);
  auto const factory = [](const CKComponentAnimations &as){
    return std::make_unique<CK::ComponentAnimationsController>(as);
  };
  transactionSpy = std::make_shared<TransactionProviderSpy>();
  applicator = std::make_unique<CK::AnimationApplicator<TransactionProviderSpy>>(factory, transactionSpy);
}

- (void)test_WhenThereAreNoAnimationsToApply_PerformsMount
{
  // We explicitly test with null pointer to make sure "no animations" case can be safely handled
  // even if we don't have an applicator in place
  applicator = nullptr;
  __block auto performedMount = false;

  applicator->runAnimationsWhenMounting({}, ^{
    performedMount = true;
    return [NSSet new];
  });

  XCTAssert(performedMount);
}

- (void)test_WhenThereAreNoAnimationsToApply_DoesNotInvokeControllerFactory
{
  auto factoryWasInvoked = false;
  auto const factory = [&factoryWasInvoked](const CKComponentAnimations &as){
    factoryWasInvoked = true;
    return std::make_unique<CK::ComponentAnimationsController>(as);
  };
  applicator = std::make_unique<CK::AnimationApplicator<TransactionProviderSpy>>(factory);

  applicator->runAnimationsWhenMounting({}, ^{ return [NSSet new]; });

  XCTAssertFalse(factoryWasInvoked);
}

- (void)test_WhenHasAnimationsToApply_InvokesControllerFactoryWithThem
{
  auto animations = CKComponentAnimations {};
  auto const factory = [&animations](const CKComponentAnimations &as){
    animations = as;
    return std::make_unique<CK::ComponentAnimationsController>(as);
  };
  applicator = std::make_unique<CK::AnimationApplicator<TransactionProviderSpy>>(factory);

  applicator->runAnimationsWhenMounting(testAnimations, ^{ return [NSSet new]; });

  XCTAssert(animations == testAnimations);
}

- (void)test_WhenHasAnimationsToApply_PerformsMountAfterCollectingPendingAnimations
{
  __block auto performedMount = false;

  applicator->runAnimationsWhenMounting(testAnimations, ^{
    [self assertWillRemountHooksWereCalled];
    performedMount = true;
    return [NSSet new];
  });

  XCTAssert(performedMount);
}

- (void)test_WhenHasAnimationsToApply_AppliesPendingAnimationsAfterPerformingMount
{
  applicator->runAnimationsWhenMounting(testAnimations, ^{
    [self assertDidRemountHooksWereNotCalled];
    return [NSSet new];
  });
  transactionSpy->runAllTransactions();

  [self assertDidRemountHooksWereCalledWithContextFromWillRemountHooks];
}

- (void)assertWillRemountHooksWereCalled
{
  const auto willRemountWasCalled = CK::map(allSpies, [](const auto &s){ return s->willRemountWasCalled; });
  XCTAssert(std::all_of(willRemountWasCalled.begin(),
                        willRemountWasCalled.end(),
                        [](bool x){ return x; }));
}

- (void)assertDidRemountHooksWereNotCalled
{
  const auto actualWillRemountCtxs = CK::map(allSpies, [](const auto &s){ return s->actualWillRemountCtx; });
  XCTAssert(std::all_of(actualWillRemountCtxs.begin(),
                        actualWillRemountCtxs.end(),
                        [](const id ctx){ return ctx == nil; }));
}

- (void)assertDidRemountHooksWereCalledWithContextFromWillRemountHooks
{
  const auto actualWillRemountCtxs = CK::map(allSpies, [](const auto &s){ return s->actualWillRemountCtx; });
  const auto willRemountCtxs = CK::map(allSpies, [](const auto &s){ return s->willRemountCtx; });
  XCTAssert(actualWillRemountCtxs == willRemountCtxs);
}

@end

@interface CKAnimationApplicatorTests_Cleanup : XCTestCase
@end

@implementation CKAnimationApplicatorTests_Cleanup {
  CKComponent *c1;
  CKAnimationSpy as1;
  CKAnimationSpy as2;
  CKAnimationSpy as3;
  std::shared_ptr<TransactionProviderSpy> transactionSpy;
  std::unique_ptr<CK::AnimationApplicator<TransactionProviderSpy>> applicator;
  CKComponentAnimations testAnimations;
}

- (void)setUp
{
  [super setUp];

  c1 = [CKComponent new];
  const auto animationsOnInitialMount = CKComponentAnimations::AnimationsByComponentMap {
    {c1, {as1.makeAnimation()}},
    {[CKComponent new], {as2.makeAnimation()}},
  };
  // Currently, situations like this shouldn't be possible because what this essentially means is that
  // `c1` did simultaneously appear and update. It still may be useful to define behaviour in that case.
  const auto animationsFromPreviousComponent = CKComponentAnimations::AnimationsByComponentMap {
    {c1, {as3.makeAnimation()}},
  };
  transactionSpy = std::make_shared<TransactionProviderSpy>();
  auto const factory = [](const CKComponentAnimations &as){
    return std::make_unique<CK::ComponentAnimationsController>(as);
  };
  applicator = std::make_unique<CK::AnimationApplicator<TransactionProviderSpy>>(factory, transactionSpy);
  testAnimations = CKComponentAnimations {
    animationsOnInitialMount,
    animationsFromPreviousComponent,
    {}
  };
}

- (void)test_WhenHasAnimationsToApply_CleansUpPreviouslyAppliedAnimationsForUnmountedComponents
{
  applicator->runAnimationsWhenMounting(testAnimations, ^{ return [NSSet new]; });
  transactionSpy->runAllTransactions();

  auto spy = CKAnimationSpy {};
  auto const newAnimations = CKComponentAnimations {
    {
      {[CKComponent new], {spy.makeAnimation()}}
    },
    {},
    {}
  };
  applicator->runAnimationsWhenMounting(newAnimations, ^{ return [NSSet setWithObject:c1]; });

  XCTAssertEqualObjects(as1.actualDidRemountCtx, as1.didRemountCtx);
  XCTAssertNil(as2.actualDidRemountCtx);
  XCTAssertEqualObjects(as3.actualDidRemountCtx, as3.didRemountCtx);
}

// Justifies the nil check for previousController
- (void)test_WhenHasAnimationsToApplyAndComponentsAreUnmountedImmediately_DoesNotCrash
{
  applicator->runAnimationsWhenMounting(testAnimations, ^{ return [NSSet setWithObject:[CKComponent new]]; });
}

@end
