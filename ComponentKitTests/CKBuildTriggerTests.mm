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

static auto makeScopeRoot(BOOL empty = NO) -> CK::NonNull<CKComponentScopeRoot *> {
  const auto scopeRoot = CKComponentScopeRootWithDefaultPredicates(nil, nil);
  if (empty) {
    return scopeRoot;
  } else {
    return CK::makeNonNull([scopeRoot newRoot]);
  }
}

static auto nonEmptyStateUpdates() -> CKComponentStateUpdateMap {
  CKComponentStateUpdateMap map;
  map[[CKComponentScopeHandle new]] = {};
  return map;
}

- (void)testBuildTriggerNoneWhenEmptyScopeRoot
{
  const auto trigger = CKBuildComponentTrigger(makeScopeRoot(YES), nonEmptyStateUpdates(), YES, YES);
  XCTAssertEqual(trigger, CKBuildTriggerNone);
}

- (void)testBuildTriggerStateUpdate
{
  const auto trigger = CKBuildComponentTrigger(makeScopeRoot(), nonEmptyStateUpdates(), NO, NO);
  XCTAssertEqual(trigger, CKBuildTriggerStateUpdate);
}

- (void)testBuildTriggerForcePropsUpdate
{
  const auto trigger = CKBuildComponentTrigger(makeScopeRoot(), {}, NO, YES);
  XCTAssertEqual(trigger, CKBuildTriggerPropsUpdate);
}

- (void)testBuildTriggerMustBePropsUpdate
{
  const auto trigger = CKBuildComponentTrigger(makeScopeRoot(), {}, NO, NO);
  XCTAssertEqual(trigger, CKBuildTriggerPropsUpdate);
}

- (void)testBuildTriggerStatePropsUpdate
{
  const auto trigger = CKBuildComponentTrigger(makeScopeRoot(), nonEmptyStateUpdates(), NO, YES);
  XCTAssertEqual(trigger, CKBuildTriggerStateUpdate | CKBuildTriggerPropsUpdate);
}

- (void)testBuildTriggerEnvironmentUpdate
{
  const auto trigger = CKBuildComponentTrigger(makeScopeRoot(), {}, YES, NO);
  XCTAssertEqual(trigger, CKBuildTriggerEnvironmentUpdate);
}

- (void)testBuildTriggerAll
{
  const auto trigger = CKBuildComponentTrigger(makeScopeRoot(), nonEmptyStateUpdates(), YES, YES);
  XCTAssertEqual(trigger, CKBuildTriggerPropsUpdate | CKBuildTriggerStateUpdate | CKBuildTriggerEnvironmentUpdate);
}

@end
