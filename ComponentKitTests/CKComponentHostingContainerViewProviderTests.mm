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
#import <ComponentKit/CKComponentFlexibleSizeRangeProvider.h>
#import <ComponentKit/CKComponentHostingContainerViewProvider.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentScopeRootFactory.h>

#import <ComponentKitTestHelpers/CKLifecycleTestComponent.h>
#import <ComponentKitTestHelpers/CKAnalyticsListenerSpy.h>

@interface CKComponentHostingContainerViewProviderTests : XCTestCase
@end

@implementation CKComponentHostingContainerViewProviderTests
{
  CKAnalyticsListenerSpy *_analyticsListener;
  CKComponentHostingContainerViewProvider *_containerViewProvider;
  CKLifecycleTestComponent *_component;
}

- (void)setUp
{
  [super setUp];

  const auto size = CGSize {200, 200};
  _analyticsListener = [CKAnalyticsListenerSpy new];
  _containerViewProvider =
  [[CKComponentHostingContainerViewProvider alloc]
   initWithFrame:CGRectMake(0, 0, size.width, size.height)
   scopeIdentifier:1
   analyticsListener:_analyticsListener
   sizeRangeProvider:
   [CKComponentFlexibleSizeRangeProvider
    providerWithFlexibility:CKComponentSizeRangeFlexibilityNone]
   allowTapPassthrough:NO
   rootViewPoolOptions:CK::none];

  const auto result = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, _analyticsListener),
                                       {},
                                       ^{
                                         return [CKLifecycleTestComponent
                                                 newWithView:{}
                                                 size:{.width = size.width, size.height}];
                                       });
  _component = (CKLifecycleTestComponent *)result.component;
  const auto rootLayout = CKComputeRootComponentLayout(result.component, {size, size}, _analyticsListener);
  [_containerViewProvider setRootLayout:rootLayout];
  [_containerViewProvider setComponent:result.component];
  [_containerViewProvider setBoundsAnimation:result.boundsAnimation];
  [_containerViewProvider mount];
}

- (void)testMount
{
  XCTAssertEqual(_analyticsListener->_willMountComponentHitCount, 1);
  XCTAssertEqual(_analyticsListener->_didMountComponentHitCount, 1);
}

- (void)testUnmount
{
  _containerViewProvider = nil;
  XCTAssertEqual(_component.controller.counts.willUnmount, 1);
}

- (void)test_WhenMountsLayout_ReportsWillCollectAnimationsEvent
{
  XCTAssertEqual(_analyticsListener->_willCollectAnimationsHitCount, 1);
}

- (void)test_WhenMountsLayout_ReportsDidCollectAnimationsEvent
{
  XCTAssertEqual(_analyticsListener->_didCollectAnimationsHitCount, 1);
}

- (void)testSizeCache_CachedSizeIsUsedIfConstrainedSizesAreSame
{
  const auto constrainedSize = CGSizeMake(100, 100);
  [_containerViewProvider.containerView sizeThatFits:constrainedSize];
  [_containerViewProvider.containerView sizeThatFits:constrainedSize];
  XCTAssertEqual(_analyticsListener->_willLayoutComponentTreeHitCount, 2);
}

- (void)testSizeCache_CachedSizeIsNotUsedIfConstrainedSizesAreDifferent
{
  const auto constrainedSize1 = CGSizeMake(100, 100);
  const auto constrainedSize2 = CGSizeMake(200, 200);
  [_containerViewProvider.containerView sizeThatFits:constrainedSize1];
  [_containerViewProvider.containerView sizeThatFits:constrainedSize2];
  XCTAssertEqual(_analyticsListener->_willLayoutComponentTreeHitCount, 3);
}

- (void)testSizeCache_CacheSizeIsNotUsedIfComponentIsUpdated
{
  const auto constrainedSize = CGSizeMake(100, 100);
  [_containerViewProvider.containerView sizeThatFits:constrainedSize];
  [_containerViewProvider setComponent:[CKComponent new]];
  [_containerViewProvider.containerView sizeThatFits:constrainedSize];
  XCTAssertEqual(_analyticsListener->_willLayoutComponentTreeHitCount, 3);
}

@end
