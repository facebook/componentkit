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

#import "CKComponentAnimationsEquality.h"

struct AnimationsControllerSpy {
  void collectPendingAnimations() { collectPendingAnimationsWasCalled = true; }
  template <typename T>
  void applyPendingAnimations(T t) { applyPendingAnimationsWasCalled = true; }
  void cleanupAppliedAnimationsForComponent(CKComponent *const c) {
    [componentsWithCleanedUpAnimations addObject:c];
  }

  bool collectPendingAnimationsWasCalled = false;
  bool applyPendingAnimationsWasCalled = false;
  NSMutableSet<CKComponent *> *componentsWithCleanedUpAnimations = [NSMutableSet set];
};

@interface CKAnimationApplicatorTests : XCTestCase
@end

const auto testAnimations = CKComponentAnimations {
  {
    {[CKComponent new], {CKComponentAnimation([CKComponent new], [CAAnimation new])}},
  },
  {},
  {},
};
const auto unmountedComponents = (NSSet<CKComponent *> *)[NSSet setWithArray:@[
                                                                               [CKComponent new],
                                                                               [CKComponent new],
                                                                               ]];

@implementation CKAnimationApplicatorTests

- (void)test_WhenThereAreNoAnimationsToApply_PerformsMount
{
  // We explicitly test with null pointer to make sure "no animations" case can be safely handled
  // even if we don't have an applicator in place
  auto applicator = std::unique_ptr<CK::AnimationApplicator<AnimationsControllerSpy>> {};
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
  // We explicitly test with null pointer to make sure "no animations" case can be safely handled
  // even if we don't have an applicator in place
  auto applicator = std::unique_ptr<CK::AnimationApplicator<AnimationsControllerSpy>> {};

  applicator->runAnimationsWhenMounting({}, ^{ return [NSSet new]; });

  XCTAssertFalse(factoryWasInvoked);
}

- (void)test_WhenHasAnimationsToApply_InvokesControllerFactoryWithThem
{
  const auto controllerSpy = std::make_shared<AnimationsControllerSpy>();
  auto animations = CKComponentAnimations {};
  auto applicator = CK::AnimationApplicator<AnimationsControllerSpy>([=, &animations](const CKComponentAnimations &as){
    animations = as;
    return controllerSpy;
  });

  applicator.runAnimationsWhenMounting(testAnimations, ^{ return [NSSet new]; });

  XCTAssert(animations == testAnimations);
}

- (void)test_WhenHasAnimationsToApply_PerformsMountAfterCollectingPendingAnimations
{
  const auto controllerSpy = std::make_shared<AnimationsControllerSpy>();
  auto applicator = CK::AnimationApplicator<AnimationsControllerSpy>([=](const CKComponentAnimations &){
    return controllerSpy;
  });
  __block auto performedMount = false;

  applicator.runAnimationsWhenMounting(testAnimations, ^{
    XCTAssert(controllerSpy->collectPendingAnimationsWasCalled);
    performedMount = true;
    return [NSSet new];
  });

  XCTAssert(performedMount);
}

- (void)test_WhenHasAnimationsToApply_AppliesPendingAnimationsAfterPerformingMount
{
  const auto controllerSpy = std::make_shared<AnimationsControllerSpy>();
  auto applicator = CK::AnimationApplicator<AnimationsControllerSpy>([=](const CKComponentAnimations &){
    return controllerSpy;
  });

  applicator.runAnimationsWhenMounting(testAnimations, ^{
    XCTAssertFalse(controllerSpy->applyPendingAnimationsWasCalled);
    return [NSSet new];
  });

  XCTAssert(controllerSpy->applyPendingAnimationsWasCalled);
}

- (void)test_WhenHasAnimationsToApply_CleansUpPreviouslyAppliedAnimationsForUnmountedComponents
{
  const auto controllerSpies = std::vector<std::shared_ptr<AnimationsControllerSpy>> {
    std::make_shared<AnimationsControllerSpy>(),
    std::make_shared<AnimationsControllerSpy>(),
  };
  auto currentSpyIdx = 0;
  auto applicator = CK::AnimationApplicator<AnimationsControllerSpy>([=, &currentSpyIdx](const CKComponentAnimations &){
    return controllerSpies[currentSpyIdx++];
  });

  applicator.runAnimationsWhenMounting(testAnimations, ^{ return [NSSet new]; });
  // Only *previous* controller should be asked to clean up animations, and there's no previous controller after
  // the first call to `runAnimationsWhenMounting`
  XCTAssertEqual(controllerSpies[0]->componentsWithCleanedUpAnimations.count, 0);
  applicator.runAnimationsWhenMounting(testAnimations, ^{ return unmountedComponents; });

  XCTAssertEqualObjects(controllerSpies[0]->componentsWithCleanedUpAnimations, unmountedComponents);
}

- (void)test_WhenHasAnimationsToApplyAndComponentsAreUnmountedImmediately_DoesNotCrash
{
  const auto controllerSpies = std::vector<std::shared_ptr<AnimationsControllerSpy>> {
    std::make_shared<AnimationsControllerSpy>(),
    std::make_shared<AnimationsControllerSpy>(),
  };
  auto currentSpyIdx = 0;
  auto applicator = CK::AnimationApplicator<AnimationsControllerSpy>([=, &currentSpyIdx](const CKComponentAnimations &){
    return controllerSpies[currentSpyIdx++];
  });

  applicator.runAnimationsWhenMounting(testAnimations, ^{ return unmountedComponents; });
}

@end
