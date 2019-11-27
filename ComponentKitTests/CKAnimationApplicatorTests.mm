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
#import <ComponentKit/CKFunctionalHelpers.h>

#import "CKAnimationSpy.h"
#import "CKComponentAnimationsEquality.h"
#import "TransactionProviderSpy.h"

@interface CKAnimationApplicatorTests : XCTestCase
@end

@implementation CKAnimationApplicatorTests {
  CKComponentAnimations testAnimations;
  std::vector<std::shared_ptr<CKAnimationSpy>> allSpies;
  TransactionProviderSpy *transactionSpy;
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
  auto __transactionSpy = std::make_unique<TransactionProviderSpy>();
  transactionSpy = __transactionSpy.get();
  applicator = std::make_unique<CK::AnimationApplicator<TransactionProviderSpy>>(std::move(__transactionSpy));
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

- (void)test_WhenHasAnimationsToApply_WrapsThenIntoIndividualTransactions
{
  applicator->runAnimationsWhenMounting(testAnimations, ^{ return [NSSet new]; });

  XCTAssertEqual(transactionSpy->transactions().size(), allSpies.size());
}

- (void)test_WhenHasAnimationsToApplyAndTransactionCompletes_CleansUpAnimationsAndPassesContextFromApplicationStage
{
  applicator->runAnimationsWhenMounting(testAnimations, ^{ return [NSSet new]; });

  transactionSpy->runAllTransactions();
  transactionSpy->runAllCompletions();
  [self assertCleanupHooksWereCalledWithContextFromDidRemountHook];
}

- (void)test_WhenControllerIsDeallocated_CallingTransactionCompletionDoesNotCrash
{
  applicator->runAnimationsWhenMounting(testAnimations, ^{ return [NSSet new]; });
  auto spy = CKAnimationSpy {};
  auto const newAnimations = CKComponentAnimations {
    {
      {[CKComponent new], {spy.makeAnimation()}}
    },
    {},
    {}
  };
  transactionSpy->runAllTransactions();
  // This deallocates the previous animation controller
  applicator->runAnimationsWhenMounting(newAnimations, ^{ return [NSSet new]; });

  transactionSpy->runAllCompletions();
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

- (void)assertCleanupHooksWereCalledWithContextFromDidRemountHook
{
  const auto actualDidRemountCtxs = CK::map(allSpies, [](const auto &s){ return s->actualDidRemountCtx; });
  const auto didRemountCtxs = CK::map(allSpies, [](const auto &s){ return s->didRemountCtx; });
  XCTAssert(actualDidRemountCtxs == didRemountCtxs);
}

@end

@interface CKAnimationApplicatorTests_Cleanup : XCTestCase
@end

@implementation CKAnimationApplicatorTests_Cleanup {
  CKComponent *c1;
  CKAnimationSpy as1;
  CKAnimationSpy as2;
  CKAnimationSpy as3;
  TransactionProviderSpy *transactionSpy;
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
  auto __transactionSpy = std::make_unique<TransactionProviderSpy>();
  transactionSpy = __transactionSpy.get();
  applicator = std::make_unique<CK::AnimationApplicator<TransactionProviderSpy>>(std::move(__transactionSpy));
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

- (void)test_WhenHasAnimationsToApply_CleansUpOnlyAnimationsThatHaveNotBeenCleanedUpAlready
{
  applicator->runAnimationsWhenMounting(testAnimations, ^{ return [NSSet new]; });
  transactionSpy->runAllTransactions();
  transactionSpy->completions()[0](); // Completes the animation for c1
  auto spy = CKAnimationSpy {};
  auto const newAnimations = CKComponentAnimations {
    {
      {[CKComponent new], {spy.makeAnimation()}}
    },
    {},
    {}
  };
  applicator->runAnimationsWhenMounting(newAnimations, ^{ return [NSSet setWithObject:c1]; });

  XCTAssertEqual(as1.cleanupCallCount, 1);
}

- (void)test_WhenTransactionCompletesForAnimationThatWasAlreadyCleanedUp_DoesNothing
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

  transactionSpy->runAllCompletions();

  XCTAssertEqual(as1.cleanupCallCount, 1);
}

@end
