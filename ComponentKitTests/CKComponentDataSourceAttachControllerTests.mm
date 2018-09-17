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
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentDataSourceAttachController.h>
#import <ComponentKit/CKComponentDataSourceAttachControllerInternal.h>
#import <ComponentKit/CKComponentRootLayoutProvider.h>

@interface CKComponentRootLayoutTestProvider: NSObject <CKComponentRootLayoutProvider>

@end

@implementation CKComponentRootLayoutTestProvider
{
  CKComponentRootLayout _rootLayout;
}

- (instancetype)initWithRootLayout:(const CKComponentRootLayout &)rootLayout
{
  if (self = [super init]) {
    _rootLayout = rootLayout;
  }
  return self;
}

- (const CKComponentRootLayout &)rootLayout
{
  return _rootLayout;
}

@end

@interface CKComponentDataSourceAttachControllerTests : XCTestCase
@end

@implementation CKComponentDataSourceAttachControllerTests

- (void)testAttachingAndDetachingComponentLayoutOnViewResultsInCorrectAttachState
{
  auto const attachController = [CKComponentDataSourceAttachController new];
  [self _testAttachingAndDetachingComponentLayoutOnViewResultsInCorrectAttachStateWithAttachController:attachController];
}

- (void)testAttachingAndDetachingComponentLayoutOnViewResultsInCorrectAttachStateWithNewAnimationInfra;
{
  auto const attachController = [CKComponentDataSourceAttachController newWithEnableNewAnimationInfrastructure:YES];
  [self _testAttachingAndDetachingComponentLayoutOnViewResultsInCorrectAttachStateWithAttachController:attachController];
}

- (void)testAttachingOneComponentLayoutAfterAnotherToViewResultsInTheFirstOneBeingDetachedWithAttachController
{
  auto const attachController = [CKComponentDataSourceAttachController new];
  [self _testAttachingOneComponentLayoutAfterAnotherToViewResultsInTheFirstOneBeingDetachedWithAttachController:attachController];
}

- (void)testAttachingOneComponentLayoutAfterAnotherToViewResultsInTheFirstOneBeingDetachedWithAttachControllerWithNewAnimationInfra
{
  auto const attachController = [CKComponentDataSourceAttachController newWithEnableNewAnimationInfrastructure:YES];
  [self _testAttachingOneComponentLayoutAfterAnotherToViewResultsInTheFirstOneBeingDetachedWithAttachController:attachController];
}

- (void)_testAttachingAndDetachingComponentLayoutOnViewResultsInCorrectAttachStateWithAttachController:(CKComponentDataSourceAttachController *)attachController
{
  UIView *view = [UIView new];
  CKComponent *component = [CKComponent new];
  CKComponentScopeRootIdentifier scopeIdentifier = 0x5C09E;

  CKComponentDataSourceAttachControllerAttachComponentRootLayout(
      attachController,
      {.layoutProvider =
        [[CKComponentRootLayoutTestProvider alloc]
         initWithRootLayout:CKComponentRootLayout {{component, {0, 0}}}],
       .scopeIdentifier = scopeIdentifier,
       .boundsAnimation = {},
       .view = view,
       .analyticsListener = nil});
  CKComponentDataSourceAttachState *attachState = [attachController attachStateForScopeIdentifier:scopeIdentifier];
  XCTAssertEqualObjects(attachState.mountedComponents, [NSSet setWithObject:component]);
  XCTAssertEqual(attachState.scopeIdentifier, scopeIdentifier);

  [attachController detachComponentLayoutWithScopeIdentifier:scopeIdentifier];
  attachState = [attachController attachStateForScopeIdentifier:scopeIdentifier];
  XCTAssertNil(attachState);
}

- (void)_testAttachingOneComponentLayoutAfterAnotherToViewResultsInTheFirstOneBeingDetachedWithAttachController:(CKComponentDataSourceAttachController *)attachController
{
  UIView *view = [UIView new];
  CKComponent *component = [CKComponent new];
  CKComponentScopeRootIdentifier scopeIdentifier = 0x5C09E;
  CKComponentDataSourceAttachControllerAttachComponentRootLayout(
      attachController,
      {.layoutProvider =
        [[CKComponentRootLayoutTestProvider alloc]
         initWithRootLayout:CKComponentRootLayout {{component, {0, 0}}}],
       .scopeIdentifier = scopeIdentifier,
       .boundsAnimation = {},
       .view = view,
       .analyticsListener = nil});

  CKComponent *component2 = [CKComponent new];
  CKComponentScopeRootIdentifier scopeIdentifier2 = 0x5C09E2;
  CKComponentDataSourceAttachControllerAttachComponentRootLayout(
      attachController,
      {.layoutProvider =
        [[CKComponentRootLayoutTestProvider alloc]
         initWithRootLayout:CKComponentRootLayout {{component2, {0, 0}}}],
       .scopeIdentifier = scopeIdentifier2,
       .boundsAnimation = {},
       .view = view,
       .analyticsListener = nil});

  // the first component is now detached
  CKComponentDataSourceAttachState *attachState = [attachController attachStateForScopeIdentifier:scopeIdentifier];
  XCTAssertNil(attachState);

  // the second component is attached
  CKComponentDataSourceAttachState *attachState2 = [attachController attachStateForScopeIdentifier:scopeIdentifier2];
  XCTAssertEqualObjects(attachState2.mountedComponents, [NSSet setWithObject:component2]);
  XCTAssertEqual(attachState2.scopeIdentifier, scopeIdentifier2);
}

@end
