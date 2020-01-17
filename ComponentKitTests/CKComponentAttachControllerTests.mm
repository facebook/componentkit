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
#import <ComponentKit/ComponentRootViewPool.h>
#import <ComponentKitTestHelpers/CKAnalyticsListenerSpy.h>

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

@interface CKComponentTestRootViewHost : NSObject <CKComponentRootViewHost>

@property (nonatomic, readonly, assign) NSInteger numberOfViewsCreated;

@end

@interface CKComponentAttachControllerTests : XCTestCase
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

  XCTAssertEqual(spy->_willCollectAnimationsHitCount, 1);
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

  XCTAssertEqual(spy->_didCollectAnimationsHitCount, 1);
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

- (void)testAttachingRootViewHostAndViewIsCreatedIfThereIsNoRootViewFromViewPool
{
  auto rootViewPool = CK::Component::RootViewPool();
  const auto attachController = [CKComponentAttachController new];
  [attachController setRootViewPool:rootViewPool];
  const auto rootViewHost = CK::makeNonNull([CKComponentTestRootViewHost new]);
  const auto rootViewCategory = CK::makeNonNull(@"Category");

  [self _attachWithAttachController:attachController scopeIdentifier:1 view:{rootViewHost, rootViewCategory}];

  XCTAssertEqual([rootViewHost numberOfViewsCreated], 1);
  XCTAssertEqualObjects([rootViewHost rootViewCategory], rootViewCategory);
}

- (void)testAttachingRootViewHostAndViewIsReusedFromRootViewPool
{
  auto rootViewPool = CK::Component::RootViewPool();
  const auto attachController = [CKComponentAttachController new];
  [attachController setRootViewPool:rootViewPool];
  const auto rootViewHost = CK::makeNonNull([CKComponentTestRootViewHost new]);
  const auto rootViewCategory = CK::makeNonNull(@"Category");
  const auto rootView = CK::makeNonNull([CKComponentRootView new]);

  rootViewPool.pushRootViewWithCategory(rootView, rootViewCategory);
  [self _attachWithAttachController:attachController scopeIdentifier:1 view:{rootViewHost, rootViewCategory}];

  XCTAssertEqual([rootViewHost numberOfViewsCreated], 0);
  XCTAssertEqual([rootViewHost rootView], rootView);
  XCTAssertEqualObjects([rootViewHost rootViewCategory], rootViewCategory);
}

- (void)testAttachingRootViewHostAndPreviousRootViewIsPushedIntoRootViewPoolIfRootViewCategoriesAreDifferent
{
  auto rootViewPool = CK::Component::RootViewPool();
  const auto attachController = [CKComponentAttachController new];
  [attachController setRootViewPool:rootViewPool];
  const auto rootViewHost = CK::makeNonNull([CKComponentTestRootViewHost new]);
  const auto rootViewCategory1 = CK::makeNonNull(@"Category1");
  const auto rootViewCategory2 = CK::makeNonNull(@"Category2");

  [self _attachWithAttachController:attachController scopeIdentifier:1 view:{rootViewHost, rootViewCategory1}];

  XCTAssertEqual([rootViewHost numberOfViewsCreated], 1);
  XCTAssertEqualObjects([rootViewHost rootViewCategory], rootViewCategory1);
  XCTAssertNil(rootViewPool.popRootViewWithCategory(rootViewCategory1));
  const auto rootView1 = [rootViewHost rootView];

  [self _attachWithAttachController:attachController scopeIdentifier:2 view:{rootViewHost, rootViewCategory2}];

  XCTAssertEqual([rootViewHost numberOfViewsCreated], 2);
  XCTAssertEqualObjects([rootViewHost rootViewCategory], rootViewCategory2);
  XCTAssertEqual(rootView1, rootViewPool.popRootViewWithCategory(rootViewCategory1));
}

- (void)testAttachingRootViewHostAndAttachStateIsDetachedFromPreviousRootViewIfRootViewCategoriesAreDifferent
{
  auto rootViewPool = CK::Component::RootViewPool();
  const auto attachController = [CKComponentAttachController new];
  [attachController setRootViewPool:rootViewPool];
  const auto rootViewHost = CK::makeNonNull([CKComponentTestRootViewHost new]);
  const auto rootViewCategory1 = CK::makeNonNull(@"Category1");
  const auto rootViewCategory2 = CK::makeNonNull(@"Category2");

  [self _attachWithAttachController:attachController scopeIdentifier:1 view:{rootViewHost, rootViewCategory1}];

  XCTAssertEqual([rootViewHost numberOfViewsCreated], 1);
  XCTAssertEqualObjects([rootViewHost rootViewCategory], rootViewCategory1);

  const auto rootView1 = [rootViewHost rootView];
  XCTAssertNotNil(CKGetAttachStateForView(rootView1));

  [self _attachWithAttachController:attachController scopeIdentifier:2 view:{rootViewHost, rootViewCategory2}];

  XCTAssertEqual([rootViewHost numberOfViewsCreated], 2);
  XCTAssertEqualObjects([rootViewHost rootViewCategory], rootViewCategory2);
  XCTAssertNil(CKGetAttachStateForView(rootView1));
}

- (void)testDeallocatingAttachControllerAndRootViewsArePushedIntoRootViewPool
{
  auto rootViewPool = CK::Component::RootViewPool();
  const auto rootViewHost1 = CK::makeNonNull([CKComponentTestRootViewHost new]);
  const auto rootViewHost2 = CK::makeNonNull([CKComponentTestRootViewHost new]);
  const auto rootViewCategory1 = CK::makeNonNull(@"Category1");
  const auto rootViewCategory2 = CK::makeNonNull(@"Category2");
  CKComponentRootView *rootView1 = nil;
  CKComponentRootView *rootView2 = nil;

  @autoreleasepool {
    auto attachController = [CKComponentAttachController new];

    [attachController setRootViewPool:rootViewPool];
    [self _attachWithAttachController:attachController scopeIdentifier:1 view:{rootViewHost1, rootViewCategory1}];
    [self _attachWithAttachController:attachController scopeIdentifier:2 view:{rootViewHost2, rootViewCategory2}];

    rootView1 = [rootViewHost1 rootView];
    rootView2 = [rootViewHost2 rootView];

    attachController = nil;
  }

  XCTAssertEqual([rootViewHost1 numberOfViewsCreated], 1);
  XCTAssertEqual([rootViewHost2 numberOfViewsCreated], 1);
  XCTAssertNil([rootViewHost1 rootView]);
  XCTAssertNil([rootViewHost2 rootView]);
  XCTAssertNil([rootViewHost1 rootViewCategory]);
  XCTAssertNil([rootViewHost2 rootViewCategory]);
  XCTAssertEqual(rootView1, rootViewPool.popRootViewWithCategory(rootViewCategory1));
  XCTAssertEqual(rootView2, rootViewPool.popRootViewWithCategory(rootViewCategory2));
  XCTAssertNil(rootViewPool.popRootViewWithCategory(rootViewCategory1));
  XCTAssertNil(rootViewPool.popRootViewWithCategory(rootViewCategory2));
}

- (void)testAttachControllerPushRootViewsToViewPool
{
  auto rootViewPool = CK::Component::RootViewPool();
  const auto rootViewHost1 = CK::makeNonNull([CKComponentTestRootViewHost new]);
  const auto rootViewHost2 = CK::makeNonNull([CKComponentTestRootViewHost new]);
  const auto rootViewCategory1 = CK::makeNonNull(@"Category1");
  const auto rootViewCategory2 = CK::makeNonNull(@"Category2");

  auto attachController = [CKComponentAttachController new];

  [attachController setRootViewPool:rootViewPool];
  [self _attachWithAttachController:attachController scopeIdentifier:1 view:{rootViewHost1, rootViewCategory1}];
  [self _attachWithAttachController:attachController scopeIdentifier:2 view:{rootViewHost2, rootViewCategory2}];

  const auto rootView1 = [rootViewHost1 rootView];
  const auto rootView2 = [rootViewHost2 rootView];
  [attachController pushRootViewsToViewPool];

  XCTAssertEqual([rootViewHost1 numberOfViewsCreated], 1);
  XCTAssertEqual([rootViewHost2 numberOfViewsCreated], 1);
  XCTAssertNil([rootViewHost1 rootView]);
  XCTAssertNil([rootViewHost2 rootView]);
  XCTAssertNil([rootViewHost1 rootViewCategory]);
  XCTAssertNil([rootViewHost2 rootViewCategory]);
  XCTAssertEqual(rootView1, rootViewPool.popRootViewWithCategory(rootViewCategory1));
  XCTAssertEqual(rootView2, rootViewPool.popRootViewWithCategory(rootViewCategory2));
  XCTAssertNil(rootViewPool.popRootViewWithCategory(rootViewCategory1));
  XCTAssertNil(rootViewPool.popRootViewWithCategory(rootViewCategory2));
}

#pragma mark - Helpers

- (CKComponentTestAttachResult)_attachWithAttachController:(CKComponentAttachController *)attachController
                                           scopeIdentifier:(CKComponentScopeRootIdentifier)scopeIdentifier
                                                      view:(CKComponentAttachableView)view
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

@implementation CKComponentTestRootViewHost

@synthesize rootView = _rootView;
@synthesize rootViewCategory = _rootViewCategory;

- (CK::NonNull<CKComponentRootView *>)createRootView
{
  _numberOfViewsCreated++;
  return CK::makeNonNull([CKComponentRootView new]);
}

- (void)rootViewWillEnterViewPool
{
  [_rootView removeFromSuperview];
  _rootView = nil;
  _rootViewCategory = nil;
}

@end
