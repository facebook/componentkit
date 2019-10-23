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

#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKComponentRootViewInternal.h>
#import <ComponentKit/ComponentRootViewPool.h>
#import <ComponentKit/ComponentViewManager.h>

using namespace CK::Component;

@interface CKComponentRootViewPoolTests : XCTestCase

@end

@interface CKTestComponentRootView : CKComponentRootView

@property (nonatomic, readonly, assign) BOOL didEnterPool;

@end

@implementation CKComponentRootViewPoolTests
{
  RootViewPool _rootViewPool;
}

- (void)setUp
{
  _rootViewPool = RootViewPool {};
}

- (void)testThatRootViewIsInPoolAfterRootViewIsPushedIntoPool
{
  const auto rootView = [CKComponentRootView new];
  const auto category = CK::makeNonNull(@"Category");
  _rootViewPool.pushRootViewWithCategory(CK::makeNonNull(rootView), category);
  XCTAssertEqual(rootView, _rootViewPool.popRootViewWithCategory(category));
}

- (void)testThatRootViewIsNotInPoolAfterRootViewIsPoppedFromPool
{
  const auto rootView = [CKComponentRootView new];
  const auto category = CK::makeNonNull(@"Category");
  _rootViewPool.pushRootViewWithCategory(CK::makeNonNull(rootView), category);
  XCTAssertNotNil(_rootViewPool.popRootViewWithCategory(category));
  XCTAssertNil(_rootViewPool.popRootViewWithCategory(category));
}

- (void)testThatRootViewIsNotInPoolAfterPoolIsCleared
{
  const auto rootView = [CKComponentRootView new];
  const auto category = CK::makeNonNull(@"Category");
  _rootViewPool.pushRootViewWithCategory(CK::makeNonNull(rootView), category);
  _rootViewPool.clear();
  XCTAssertNil(_rootViewPool.popRootViewWithCategory(category));
}

- (void)testThatReentrantMutationIsNotAllowedUponEnumeration
{
  @autoreleasepool {
    auto rootView = [CKTestComponentRootView new];
    const auto category = CK::makeNonNull(@"Category");
    GlobalRootViewPool().pushRootViewWithCategory(CK::makeNonNull(rootView), category);
    rootView = nil;
  }
  GlobalRootViewPool().clear(); // Reentrant mutation happens in `dealloc` of `CKTestComponentRootView`.
  XCTAssertNil(GlobalRootViewPool().popRootViewWithCategory(CK::makeNonNull(@"Test")));
}

- (void)testThatWillEnterViewPoolIsCalledAfterRootViewIsPushIntoPool
{
  const auto rootView = [CKTestComponentRootView new];
  const auto category = CK::makeNonNull(@"Category");
  XCTAssertFalse(rootView.didEnterPool);
  _rootViewPool.pushRootViewWithCategory(CK::makeNonNull(rootView), category);
  XCTAssertTrue(rootView.didEnterPool);
}

- (void)testThatSubviewIsHiddenAfterRootViewIsPushedIntoPool
{
  const auto component = CK::ComponentBuilder()
                             .viewClass([UIView class])
                             .build();
  const auto rootView = [CKComponentRootView new];
  const auto category = CK::makeNonNull(@"Category");
  CK::Component::ViewReuseUtilities::mountingInRootView(rootView);
  UIView *subview;
  {
    ViewManager m(rootView);
    subview = m.viewForConfiguration([component class], [component viewConfiguration]);
  }
  XCTAssertFalse(subview.isHidden);
  _rootViewPool.pushRootViewWithCategory(CK::makeNonNull(rootView), category);
  XCTAssertTrue(subview.isHidden);
}

@end

@implementation CKTestComponentRootView

- (void)dealloc
{
  GlobalRootViewPool().pushRootViewWithCategory(CK::makeNonNull([CKComponentRootView new]),
                                                CK::makeNonNull(@"Test"));
}

- (void)willEnterViewPool
{
  [super willEnterViewPool];
  _didEnterPool = YES;
}

@end


