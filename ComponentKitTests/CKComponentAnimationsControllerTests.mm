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
#import <ComponentKit/CKComponentAnimationsController.h>
#import <ComponentKit/ComponentUtilities.h>

@interface CKComponentAnimationsControllerTests : XCTestCase
@end

struct CKAnimationSpy {
  auto makeAnimation() {
    return CKComponentAnimation({
      .willRemount = ^{
        willRemountWasCalled = true;
        return willRemountCtx;
      },
      .didRemount = ^(id context){
        actualWillRemountCtx = context;
        return didRemountCtx;
      },
      .cleanup = ^(id context){
        cleanupCallCount++;
        actualDidRemountCtx = context;
      },
    });
  }

  const id willRemountCtx = [NSObject new];
  id actualWillRemountCtx = nil;
  bool willRemountWasCalled = false;
  const id didRemountCtx = [NSObject new];
  id actualDidRemountCtx = nil;
  int cleanupCallCount = 0;
};

struct TransactionProviderSpy {
  using TransactionBlock = void (^)(void);
  using CompletionBlock = void (^)(void);

  auto inTransaction(TransactionBlock t, CompletionBlock c)
  {
    _transactions.push_back(t);
    _completions.push_back(c);
  }

  auto runAllTransactions() const
  {
    for (const auto &t : _transactions) {
      t();
    }
  }

  auto runAllCompletions() const
  {
    for (const auto &c : _completions) {
      c();
    }
  }

  const auto &transactions() const { return _transactions; }
  const auto &completions() const { return _completions; };

private:
  std::vector<TransactionBlock> _transactions;
  std::vector<CompletionBlock> _completions;
};

@implementation CKComponentAnimationsControllerTests {
  std::vector<std::shared_ptr<CKAnimationSpy>> allSpies;
  // Unique pointer just to allow delayed initialisation
  std::unique_ptr<CK::ComponentAnimationsController> controller;
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
  controller = std::make_unique<CK::ComponentAnimationsController>(CKComponentAnimations {
    CKComponentAnimations::AnimationsByComponentMap(initialAnimationsPairs.begin(), initialAnimationsPairs.end()),
    CKComponentAnimations::AnimationsByComponentMap(changeAnimationsPairs.begin(), changeAnimationsPairs.end()),
    {},
  });
  allSpies = CK::chain(spiesForInitialAnimations, spiesForChangeAnimations);
}

- (void)test_WhenCollectingAnimations_DoesNotApplyThem
{
  controller->collectPendingAnimations();

  [self assertDidRemountHooksWereNotCalled];
}

- (void)test_WhenCollectingAnimations_CollectsInitialContexts
{
  controller->collectPendingAnimations();

  [self assertWillRemountHooksWereCalled];
}

- (void)test_WhenApplyingAnimations_DoesItOnlyInsideTransaction
{
  controller->collectPendingAnimations();
  auto transactionSpy = TransactionProviderSpy {};
  controller->applyPendingAnimations(transactionSpy);

  [self assertDidRemountHooksWereNotCalled];
}

- (void)test_WhenApplyingAnimations_WrapsThemIntoIndividualTransactions
{
  controller->collectPendingAnimations();
  auto transactionSpy = TransactionProviderSpy {};
  controller->applyPendingAnimations(transactionSpy);

  XCTAssertEqual(transactionSpy.transactions().size(), allSpies.size());
}

- (void)test_WhenApplyingAnimations_PassesContextFromCollectionStage
{
  controller->collectPendingAnimations();
  auto transactionSpy = TransactionProviderSpy {};
  controller->applyPendingAnimations(transactionSpy);

  transactionSpy.runAllTransactions();
  [self assertDidRemountHooksWereCalledWithContextFromWillRemountHooks];
}

- (void)test_WhenTransactionCompletes_CleansUpAnimationsAndPassesContextFromApplicationStage
{
  controller->collectPendingAnimations();
  auto transactionSpy = TransactionProviderSpy {};
  controller->applyPendingAnimations(transactionSpy);

  transactionSpy.runAllTransactions();
  transactionSpy.runAllCompletions();
  [self assertCleanupHooksWereCalledWithContextFromDidRemountHook];
}

- (void)test_WhenControllerIsDeallocated_CallingTransactionCompletionDoesNotCrash
{
  controller->collectPendingAnimations();
  auto transactionSpy = TransactionProviderSpy {};
  controller->applyPendingAnimations(transactionSpy);
  transactionSpy.runAllTransactions();

  controller = nullptr;

  transactionSpy.runAllCompletions();
}

- (void)assertDidRemountHooksWereNotCalled
{
  const auto actualWillRemountCtxs = CK::map(allSpies, [](const auto &s){ return s->actualWillRemountCtx; });
  XCTAssert(all_of(actualWillRemountCtxs.begin(),
                   actualWillRemountCtxs.end(),
                   [](const id ctx){ return ctx == nil; }));
}

- (void)assertWillRemountHooksWereCalled
{
  const auto willRemountWasCalled = CK::map(allSpies, [](const auto &s){ return s->willRemountWasCalled; });
  XCTAssert(all_of(willRemountWasCalled.begin(),
                   willRemountWasCalled.end(),
                   [](bool x){ return x; }));
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

@interface CKComponentAnimationsControllerTests_Cleanup: XCTestCase
@end

@implementation CKComponentAnimationsControllerTests_Cleanup {
  CKComponent *c1;
  CKAnimationSpy as1;
  CKAnimationSpy as2;
  CKAnimationSpy as3;
  TransactionProviderSpy transactionSpy;
  // Unique pointer just to allow delayed initialisation
  std::unique_ptr<CK::ComponentAnimationsController> controller;
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
  const auto animations = CKComponentAnimations(animationsOnInitialMount, animationsFromPreviousComponent, {});
  controller = std::make_unique<CK::ComponentAnimationsController>(animations);
}

- (void)test_WhenAskedToCleanupAnimationsForComponent_CleansUpOnlyTheseAnimations
{
  controller->collectPendingAnimations();
  controller->applyPendingAnimations(transactionSpy);
  transactionSpy.runAllTransactions();

  controller->cleanupAppliedAnimationsForComponent(c1);

  XCTAssertEqualObjects(as1.actualDidRemountCtx, as1.didRemountCtx);
  XCTAssertNil(as2.actualDidRemountCtx);
  XCTAssertEqualObjects(as3.actualDidRemountCtx, as3.didRemountCtx);
}

- (void)test_WhenAskedToCleanupAnimationsForComponent_CleansUpOnlyAnimationsThatHaveNotBeenCleanedUpAlready
{
  controller->collectPendingAnimations();
  controller->applyPendingAnimations(transactionSpy);
  transactionSpy.runAllTransactions();
  transactionSpy.completions()[0](); // Completes the animation for c1

  controller->cleanupAppliedAnimationsForComponent(c1);

  XCTAssertEqual(as1.cleanupCallCount, 1);
}

- (void)test_WhenTransactionCompletesForAnimationThatWasAlreadyCleanedUp_DoesNothing
{
  controller->collectPendingAnimations();
  controller->applyPendingAnimations(transactionSpy);
  transactionSpy.runAllTransactions();
  controller->cleanupAppliedAnimationsForComponent(c1);

  transactionSpy.runAllCompletions();

  XCTAssertEqual(as1.cleanupCallCount, 1);
}

@end
