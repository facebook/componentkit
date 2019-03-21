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

#import "CKAnalyticsListenerSpy.h"
#import "CKComponent.h"
#import "CKComponentFlexibleSizeRangeProvider.h"
#import "CKComponentHostingContainerView.h"
#import "CKComponentLayout.h"
#import "CKComponentScopeRootFactory.h"

@interface CKComponentHostingContainerViewTests : XCTestCase
@end

@implementation CKComponentHostingContainerViewTests
{
  CKAnalyticsListenerSpy *_analyticsListener;
  CKComponentHostingContainerView *_containerView;
}

- (void)setUp
{
  [super setUp];

  const auto size = CGSize {200, 200};
  _analyticsListener = [CKAnalyticsListenerSpy new];
  _containerView =
  [[CKComponentHostingContainerView alloc]
   initWithFrame:CGRectMake(0, 0, size.width, size.height)
   scopeIdentifier:1
   analyticsListener:_analyticsListener
   sizeRangeProvider:
   [CKComponentFlexibleSizeRangeProvider
    providerWithFlexibility:CKComponentSizeRangeFlexibilityNone]
   allowTapPassthrough:NO];

  const auto result = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, _analyticsListener),
                                       {},
                                       ^{
                                         return [CKComponent
                                                 newWithView:{}
                                                 size:{.width = size.width, size.height}];
                                       });
  const auto rootLayout = CKComputeRootComponentLayout(result.component, {size, size}, _analyticsListener);
  [_containerView setRootLayout:rootLayout];
  [_containerView setComponent:result.component];
  [_containerView setBoundsAnimation:result.boundsAnimation];
  [_containerView mount];
}

- (void)testMount
{
  XCTAssertEqual(_analyticsListener->_willMountComponentHitCount, 1);
  XCTAssertEqual(_analyticsListener->_didMountComponentHitCount, 1);
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
  [_containerView sizeThatFits:constrainedSize];
  [_containerView sizeThatFits:constrainedSize];
  XCTAssertEqual(_analyticsListener->_willLayoutComponentTreeHitCount, 2);
}

- (void)testSizeCache_CachedSizeIsNotUsedIfConstrainedSizesAreDifferent
{
  const auto constrainedSize1 = CGSizeMake(100, 100);
  const auto constrainedSize2 = CGSizeMake(200, 200);
  [_containerView sizeThatFits:constrainedSize1];
  [_containerView sizeThatFits:constrainedSize2];
  XCTAssertEqual(_analyticsListener->_willLayoutComponentTreeHitCount, 3);
}

- (void)testSizeCache_CacheSizeIsNotUsedIfComponentIsUpdated
{
  const auto constrainedSize = CGSizeMake(100, 100);
  [_containerView sizeThatFits:constrainedSize];
  [_containerView setComponent:[CKComponent new]];
  [_containerView sizeThatFits:constrainedSize];
  XCTAssertEqual(_analyticsListener->_willLayoutComponentTreeHitCount, 3);
}

@end
