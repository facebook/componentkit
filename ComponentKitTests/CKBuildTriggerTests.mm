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

#import <ComponentKit/CKBuildComponent.h>
#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentScopeRootFactory.h>
#import <ComponentKit/CKComponentScopeRoot.h>

@interface CKBuildTriggerTests : XCTestCase
@end

@implementation CKBuildTriggerTests

struct ScopeRootAndStateUpdates {
  CK::NonNull<CKComponentScopeRoot *> scopeRoot;
  CKComponentStateUpdateMap stateUpdates;
};

static auto makeScopeRoot(BOOL empty) -> CK::NonNull<CKComponentScopeRoot *> {
  const auto scopeRoot = CKComponentScopeRootWithDefaultPredicates(nil, nil);
  if (empty) {
    return scopeRoot;
  } else {
    return CK::makeNonNull([scopeRoot newRoot]);
  }
}


static auto makeScopeRootAndStateUpdates(BOOL empty, BOOL withStateUpdate) -> ScopeRootAndStateUpdates {
  const auto scopeRoot = makeScopeRoot(empty);
  CKComponentStateUpdateMap stateUpdates;

  if (withStateUpdate) {
    const auto scopeHandle = [[CKComponentScopeHandle alloc] initWithListener:nil
                                                               rootIdentifier:4242
                                                            componentTypeName:"test"
                                                                 initialState:nil];

    [scopeHandle resolveInScopeRoot:*scopeRoot];
    stateUpdates[scopeHandle] = {};
  }

  return {scopeRoot, stateUpdates};
}

- (void)testBuildTriggerNoneWhenEmptyScopeRoot
{
  const auto scopeRootAndStateUpdate = makeScopeRootAndStateUpdates(YES, NO);
  const auto trigger = CKBuildComponentTrigger(scopeRootAndStateUpdate.scopeRoot, scopeRootAndStateUpdate.stateUpdates, YES, YES);
  XCTAssertEqual(trigger, CKBuildTriggerNone);
}

- (void)testBuildTriggerStateUpdate
{
  const auto scopeRootAndStateUpdate = makeScopeRootAndStateUpdates(NO, YES);
  const auto trigger = CKBuildComponentTrigger(scopeRootAndStateUpdate.scopeRoot, scopeRootAndStateUpdate.stateUpdates, NO, NO);
  XCTAssertEqual(trigger, CKBuildTriggerStateUpdate);
}

- (void)testBuildTriggerForcePropsUpdate
{
  const auto scopeRootAndStateUpdate = makeScopeRootAndStateUpdates(NO, NO);
  const auto trigger = CKBuildComponentTrigger(scopeRootAndStateUpdate.scopeRoot, scopeRootAndStateUpdate.stateUpdates, NO, YES);
  XCTAssertEqual(trigger, CKBuildTriggerPropsUpdate);
}

- (void)testBuildTriggerMustBePropsUpdate
{
  const auto scopeRootAndStateUpdate = makeScopeRootAndStateUpdates(NO, NO);
  const auto trigger = CKBuildComponentTrigger(scopeRootAndStateUpdate.scopeRoot, scopeRootAndStateUpdate.stateUpdates, NO, NO);
  XCTAssertEqual(trigger, CKBuildTriggerPropsUpdate);
}

- (void)testBuildTriggerStatePropsUpdate
{
  const auto scopeRootAndStateUpdate = makeScopeRootAndStateUpdates(NO, YES);
  const auto trigger = CKBuildComponentTrigger(scopeRootAndStateUpdate.scopeRoot, scopeRootAndStateUpdate.stateUpdates, NO, YES);
  XCTAssertEqual(trigger, CKBuildTriggerStateUpdate | CKBuildTriggerPropsUpdate);
}

- (void)testBuildTriggerEnvironmentUpdate
{
  const auto scopeRootAndStateUpdate = makeScopeRootAndStateUpdates(NO, NO);
  const auto trigger = CKBuildComponentTrigger(scopeRootAndStateUpdate.scopeRoot, scopeRootAndStateUpdate.stateUpdates, YES, NO);
  XCTAssertEqual(trigger, CKBuildTriggerEnvironmentUpdate);
}

- (void)testBuildTriggerAll
{
  const auto scopeRootAndStateUpdate = makeScopeRootAndStateUpdates(NO, YES);
  const auto trigger = CKBuildComponentTrigger(scopeRootAndStateUpdate.scopeRoot, scopeRootAndStateUpdate.stateUpdates, YES, YES);
  XCTAssertEqual(trigger, CKBuildTriggerPropsUpdate | CKBuildTriggerStateUpdate | CKBuildTriggerEnvironmentUpdate);
}

@end
