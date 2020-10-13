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
#import <ComponentKit/CKComponentAttachController.h>
#import <ComponentKit/CKComponentAttachControllerInternal.h>
#import <ComponentKit/CKComponentRootLayoutProvider.h>
#import <ComponentKit/CKComponentRootView.h>
#import <ComponentKitTestHelpers/CKAnalyticsListenerSpy.h>

#import "CKComponentTestCase.h"

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

struct CKComponentTestAttachResult {
  CKComponent *component;
  id<CKComponentRootLayoutProvider> layoutProvider;
};

@interface CKComponentAttachControllerTests : CKComponentTestCase
@end

@implementation CKComponentAttachControllerTests

- (void)testAttachingAndDetachingComponentLayoutOnViewResultsInCorrectAttachState
{
  auto const attachController = [CKComponentAttachController new];
  auto const view = [UIView new];
  CKComponentScopeRootIdentifier scopeIdentifier = 0x5C09E;

  [self _attachWithAttachController:attachController scopeIdentifier:scopeIdentifier view:view];
  [attachController detachComponentLayoutWithScopeIdentifier:scopeIdentifier];
  XCTAssertNil([attachController attachStateForScopeIdentifier:scopeIdentifier]);
}

- (void)testAttachingOneComponentLayoutAfterAnotherToViewResultsInTheFirstOneBeingDetachedWithAttachController
{
  auto const attachController = [CKComponentAttachController new];
  auto const view = [UIView new];
  CKComponentScopeRootIdentifier scopeIdentifier = 0x5C09E;
  CKComponentScopeRootIdentifier scopeIdentifier2 = 0x5C09E2;

  [self _attachWithAttachController:attachController scopeIdentifier:scopeIdentifier view:view];
  const auto attachResult2 = [self _attachWithAttachController:attachController scopeIdentifier:scopeIdentifier2 view:view];

  // the first component is now detached
  CKComponentAttachState *attachState = [attachController attachStateForScopeIdentifier:scopeIdentifier];
  XCTAssertNil(attachState);

  // the second component is attached
  CKComponentAttachState *attachState2 = [attachController attachStateForScopeIdentifier:scopeIdentifier2];
  XCTAssertEqualObjects(attachState2.mountedComponents, [NSSet setWithObject:attachResult2.component]);
  XCTAssertEqual(attachState2.scopeIdentifier, scopeIdentifier2);
}

- (void)test_WhenMountsLayout_ReportsWillCollectAnimationsEvent
{
  auto const attachController = [CKComponentAttachController new];
  auto const layout = CKComponentRootLayout {
    {[CKComponent new], {0, 0}}
  };
  auto const layoutProvider = [[CKComponentRootLayoutTestProvider alloc] initWithRootLayout:layout];
  auto const spy = [CKAnalyticsListenerSpy new];

  CKComponentAttachControllerAttachComponentRootLayout(attachController,
                                                                 {.layoutProvider =
                                                                   layoutProvider,
                                                                   .scopeIdentifier = 0x5C09E,
                                                                   .boundsAnimation = {},
                                                                   .view = [UIView new],
                                                                   .analyticsListener = spy});

  XCTAssertEqual(spy.willCollectAnimationsHitCount, 1);
}

- (void)test_WhenMountsLayout_ReportsDidCollectAnimationsEvent
{
  auto const attachController = [CKComponentAttachController new];
  auto const layout = CKComponentRootLayout {
    {[CKComponent new], {0, 0}}
  };
  auto const layoutProvider = [[CKComponentRootLayoutTestProvider alloc] initWithRootLayout:layout];
  auto const spy = [CKAnalyticsListenerSpy new];

  CKComponentAttachControllerAttachComponentRootLayout(attachController,
                                                                 {.layoutProvider =
                                                                   layoutProvider,
                                                                   .scopeIdentifier = 0x5C09E,
                                                                   .boundsAnimation = {},
                                                                   .view = [UIView new],
                                                                   .analyticsListener = spy});

  XCTAssertEqual(spy.didCollectAnimationsHitCount, 1);
}

- (void)testDetachingAllComponents
{
  const auto attachController = [CKComponentAttachController new];
  const auto view1 = [UIView new];
  const auto view2 = [UIView new];
  CKComponentScopeRootIdentifier scopeIdentifier1 = 1;
  CKComponentScopeRootIdentifier scopeIdentifier2 = 2;

  // Just for keeping a strong reference for `layoutProvider` in `attachResult` so that
  // `attachController` can hold a non-nil weak reference when component is attached.
  __unused const auto attachResult1 = [self _attachWithAttachController:attachController scopeIdentifier:scopeIdentifier1 view:view1];
  __unused const auto attachResult2 = [self _attachWithAttachController:attachController scopeIdentifier:scopeIdentifier2 view:view2];

  XCTAssertNotNil([attachController layoutProviderForScopeIdentifier:scopeIdentifier1]);
  XCTAssertNotNil([attachController layoutProviderForScopeIdentifier:scopeIdentifier2]);

  [attachController detachAll];
  XCTAssertNil([attachController attachStateForScopeIdentifier:scopeIdentifier1]);
  XCTAssertNil([attachController attachStateForScopeIdentifier:scopeIdentifier2]);
  XCTAssertNil([attachController layoutProviderForScopeIdentifier:scopeIdentifier1]);
  XCTAssertNil([attachController layoutProviderForScopeIdentifier:scopeIdentifier2]);
}

#pragma mark - Helpers

- (CKComponentTestAttachResult)_attachWithAttachController:(CKComponentAttachController *)attachController
                                           scopeIdentifier:(CKComponentScopeRootIdentifier)scopeIdentifier
                                                      view:(UIView *)view
{
  CKComponent *component = [CKComponent new];
  id<CKComponentRootLayoutProvider> layoutProvider = [[CKComponentRootLayoutTestProvider alloc]
                                                      initWithRootLayout:CKComponentRootLayout {{component, {0, 0}}}];

  CKComponentAttachControllerAttachComponentRootLayout(attachController,
                                                       {
                                                         .layoutProvider = layoutProvider,
                                                         .scopeIdentifier = scopeIdentifier,
                                                         .boundsAnimation = {},
                                                         .view = view,
                                                         .analyticsListener = nil,
                                                       });
  CKComponentAttachState *attachState = [attachController attachStateForScopeIdentifier:scopeIdentifier];
  XCTAssertEqualObjects(attachState.mountedComponents, [NSSet setWithObject:component]);
  XCTAssertEqual(attachState.scopeIdentifier, scopeIdentifier);

  return {
    .component = component,
    .layoutProvider = layoutProvider,
  };
}

@end
