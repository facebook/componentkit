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

#import "CKComponentHostingViewTestModel.h"

#import "CKComponent.h"
#import "CKComponentFlexibleSizeRangeProvider.h"
#import "CKComponentHostingView.h"
#import "CKComponentHostingViewDelegate.h"
#import "CKComponentHostingViewInternal.h"
#import "CKComponentViewInterface.h"

@interface CKComponentHostingViewTests : XCTestCase <CKComponentProvider, CKComponentHostingViewDelegate>
@end

static CKComponentHostingView *hostingView()
{
  CKComponentHostingViewTestModel *model = [[CKComponentHostingViewTestModel alloc] initWithColor:[UIColor orangeColor] size:CKComponentSize::fromCGSize(CGSizeMake(50, 50))];
  CKComponentHostingView *view = [[CKComponentHostingView alloc] initWithComponentProvider:[CKComponentHostingViewTests class]
                                                                         sizeRangeProvider:[CKComponentFlexibleSizeRangeProvider providerWithFlexibility:CKComponentSizeRangeFlexibleWidthAndHeight]
                                                                                   context:nil];
  view.bounds = CGRectMake(0, 0, 100, 100);
  view.model = model;
  [view layoutIfNeeded];
  return view;
}

@implementation CKComponentHostingViewTests {
  BOOL _calledSizeDidInvalidate;
  CKComponentHostingView *_hostingView;
}

+ (CKComponent *)componentForModel:(CKComponentHostingViewTestModel *)model context:(id<NSObject>)context
{
  return CKComponentWithHostingViewTestModel(model);
}

- (void)setUp
{
  [super setUp];
  _calledSizeDidInvalidate = NO;
}

- (void)testInitializationInsertsContainerViewInHierarchy
{
  CKComponentHostingView *view = hostingView();
  XCTAssertTrue(view.subviews.count == 1, @"Expect hosting view to have a single subview.");
}

- (void)testInitializationInsertsComponentViewInHierarchy
{
  CKComponentHostingView *view = hostingView();
  XCTAssertTrue([view.containerView.subviews count] > 0, @"Expect that initialization should insert component view as subview of container view.");
}

- (void)testUpdatingHostingViewBoundsResizesComponentView
{
  CKComponentHostingView *view = hostingView();
  view.bounds = CGRectMake(0, 0, 200, 200);
  [view layoutIfNeeded];

  UIView *componentView = [view.containerView.subviews firstObject];
  XCTAssertEqualObjects(componentView.backgroundColor, [UIColor orangeColor], @"Expected to find orange component view");
  XCTAssertTrue(CGRectEqualToRect(componentView.bounds, CGRectMake(0, 0, 200, 200)));
}

- (void)testUpdatesOnModelChange
{
  CKComponentHostingView *view = hostingView();
  view.model = [[CKComponentHostingViewTestModel alloc] initWithColor:[UIColor redColor] size:CKComponentSize::fromCGSize(CGSizeMake(50, 50))];
  [view layoutIfNeeded];

  UIView *componentView = [view.containerView.subviews firstObject];
  XCTAssertEqualObjects(componentView.backgroundColor, [UIColor redColor], @"Expected component view to become red");
}

- (void)testInformsDelegateSizeIsInvalidatedOnModelChange
{
  CKComponentHostingView *view = hostingView();
  view.delegate = self;
  view.model = [[CKComponentHostingViewTestModel alloc] initWithColor:[UIColor orangeColor] size:CKComponentSize::fromCGSize(CGSizeMake(75, 75))];
  XCTAssertTrue(_calledSizeDidInvalidate);
}

- (void)testInformsDelegateSizeIsInvalidatedOnContextChange
{
  CKComponentHostingView *view = hostingView();
  view.delegate = self;
  view.context = @"foo";
  XCTAssertTrue(_calledSizeDidInvalidate);
}

- (void)testUpdateWithEmptyBoundsDoesntMountLayout
{
  CKComponentHostingViewTestModel *model = [[CKComponentHostingViewTestModel alloc] initWithColor:[UIColor orangeColor] size:CKComponentSize::fromCGSize(CGSizeMake(50, 50))];
  CKComponentHostingView *view = [[CKComponentHostingView alloc] initWithComponentProvider:[self class]
                                                                         sizeRangeProvider:[CKComponentFlexibleSizeRangeProvider providerWithFlexibility:CKComponentSizeRangeFlexibleWidthAndHeight]
                                                                                   context:nil];
  view.model = model;
  [view layoutIfNeeded];

  XCTAssertEqual([view.containerView.subviews count], 0u, @"Expect the component is not mounted with empty bounds");
}

#pragma mark - CKComponentHostingViewDelegate

- (void)componentHostingViewDidInvalidateSize:(CKComponentHostingView *)hostingView
{
  _calledSizeDidInvalidate = YES;
}

@end
