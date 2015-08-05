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
#import <OCMock/OCMock.h>

#import "CKComponent.h"
#import "CKComponentInternal.h"
#import "CKComponentLayout.h"
#import "CKComponentDataSourceAttachController.h"
#import "CKComponentDataSourceAttachControllerInternal.h"

@interface CKComponentDataSourceAttachControllerTests : XCTestCase
@end

@implementation CKComponentDataSourceAttachControllerTests {
  CKComponentDataSourceAttachController *_attachController;
}

- (void)setUp
{
  [super setUp];
  _attachController = [CKComponentDataSourceAttachController new];
}

- (void)testAttachingAndDetachingComponentLayoutOnViewResultsInCorrectAttachState
{
  UIView *view = [UIView new];
  CKComponent *component = [CKComponent new];
  CKComponentScopeRootIdentifier scopeIdentifier = 0x5C09E;

  [_attachController attachComponentLayout:{component, {0, 0}} withScopeIdentifier:scopeIdentifier toView:view];
  CKComponentDataSourceAttachState *attachState = [_attachController attachStateForScopeIdentifier:scopeIdentifier];
  XCTAssertEqualObjects(attachState.mountedComponents, [NSSet setWithObject:component]);
  XCTAssertEqual(attachState.scopeIdentifier, scopeIdentifier);

  [_attachController detachComponentLayoutWithScopeIdentifier:scopeIdentifier];
  attachState = [_attachController attachStateForScopeIdentifier:scopeIdentifier];
  XCTAssertNil(attachState);
}

- (void)testAttachingOneComponentLayoutAfterAnotherToViewResultsInTheFirstOneBeingDetached
{
  UIView *view = [UIView new];
  CKComponent *component = [CKComponent new];
  CKComponentScopeRootIdentifier scopeIdentifier = 0x5C09E;
  [_attachController attachComponentLayout:{component, {0, 0}} withScopeIdentifier:scopeIdentifier toView:view];

  CKComponent *component2 = [CKComponent new];
  CKComponentScopeRootIdentifier scopeIdentifier2 = 0x5C09E2;
  [_attachController attachComponentLayout:{component2, {0, 0}} withScopeIdentifier:scopeIdentifier2 toView:view];

  // the first component is now detached
  CKComponentDataSourceAttachState *attachState = [_attachController attachStateForScopeIdentifier:scopeIdentifier];
  XCTAssertNil(attachState);

  // the second component is attached
  CKComponentDataSourceAttachState *attachState2 = [_attachController attachStateForScopeIdentifier:scopeIdentifier2];
  XCTAssertEqualObjects(attachState2.mountedComponents, [NSSet setWithObject:component2]);
  XCTAssertEqual(attachState2.scopeIdentifier, scopeIdentifier2);
}

@end
