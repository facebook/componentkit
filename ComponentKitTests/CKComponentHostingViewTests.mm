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
#import "CKComponentLifecycleManager.h"
#import "CKComponentViewInterface.h"

@interface CKComponentHostingViewTests : XCTestCase <CKComponentProvider, CKComponentHostingViewDelegate>
@end

@interface CKFakeComponentLifecycleManager : NSObject
@property (nonatomic, assign) BOOL updateWithStateWasCalled;
@end

@implementation CKFakeComponentLifecycleManager {
  BOOL _isAttached;
}

- (CKComponentLifecycleManagerState)prepareForUpdateWithModel:(id)model constrainedSize:(CKSizeRange)constrainedSize context:(id<NSObject>)context
{
  return CKComponentLifecycleManagerStateEmpty;
}

- (void)updateWithState:(const CKComponentLifecycleManagerState &)state
{
  self.updateWithStateWasCalled = YES;
}

- (void)attachToView:(UIView *)view
{
  _isAttached = YES;
}

- (void)detachFromView
{
  _isAttached = NO;
}

- (BOOL)isAttachedToView
{
  return _isAttached;
}

- (void)setDelegate:(id<CKComponentLifecycleManagerDelegate>)delegate {}

@end

@implementation CKComponentHostingViewTests {
  BOOL _calledSizeDidInvalidate;
}

+ (CKComponent *)componentForModel:(CKComponentHostingViewTestModel *)model context:(id<NSObject>)context
{
  return CKComponentWithHostingViewTestModel(model);
}

- (CKComponentHostingView *)newHostingView
{
  CKComponentLifecycleManager *manager = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class]];
  return [self newHostingViewWithLifecycleManager:manager];
}

- (CKComponentHostingView *)newHostingViewWithLifecycleManager:(CKComponentLifecycleManager *)manager
{
  CKComponentHostingViewTestModel *model = [[CKComponentHostingViewTestModel alloc] initWithColor:[UIColor orangeColor] size:CKComponentSize::fromCGSize(CGSizeMake(50, 50))];
  CKComponentHostingView *view = [[CKComponentHostingView alloc] initWithLifecycleManager:manager
                                                                        sizeRangeProvider:[CKComponentFlexibleSizeRangeProvider providerWithFlexibility:CKComponentSizeRangeFlexibleWidthAndHeight]
                                                                                  context:nil];
  view.bounds = CGRectMake(0, 0, 100, 100);
  view.model = model;
  [view layoutIfNeeded];
  return view;
}

- (void)tearDown
{
  _calledSizeDidInvalidate = NO;
  [super tearDown];
}

- (void)testInitializationInsertsContainerViewInHierarchy
{
  CKComponentHostingView *hostingView = [self newHostingView];
  XCTAssertTrue(hostingView.subviews.count == 1, @"Expect hosting view to have a single subview.");
}

- (void)testInitializationInsertsComponentViewInHierarcy
{
  CKComponentHostingView *hostingView = [self newHostingView];

  XCTAssertTrue([hostingView.containerView.subviews count] > 0, @"Expect that initialization should insert component view as subview of container view.");
}

- (void)testLifecycleManagerAttachedToContainerAndNotRoot
{
  CKComponentHostingView *hostingView = [self newHostingView];
  XCTAssertNil(hostingView.ck_componentLifecycleManager, @"Expect hosting view to have no lifecycle manager.");
  XCTAssertNotNil(hostingView.containerView.ck_componentLifecycleManager, @"Expect container view to have a lifecycle manager.");
}

- (void)testUpdatesOnBoundsChange
{
  id fakeManager = [[CKFakeComponentLifecycleManager alloc] init];
  CKComponentHostingView *hostingView = [self newHostingViewWithLifecycleManager:fakeManager];

  hostingView.bounds = CGRectMake(0, 0, 100, 100);

  XCTAssertTrue([fakeManager updateWithStateWasCalled], @"Expect update to be triggered on bounds change.");
}

- (void)testUpdatesOnModelChange
{
  id fakeManager = [[CKFakeComponentLifecycleManager alloc] init];
  CKComponentHostingView *hostingView = [self newHostingViewWithLifecycleManager:fakeManager];
  CKComponentHostingViewTestModel *model = [[CKComponentHostingViewTestModel alloc] initWithColor:[UIColor redColor] size:CKComponentSize::fromCGSize(CGSizeMake(50, 50))];

  hostingView.model = model;

  XCTAssertTrue([fakeManager updateWithStateWasCalled], @"Expect update to be triggered on bounds change.");
}

- (void)testCallsDelegateOnSizeChange
{
  CKComponentHostingView *hostingView = [self newHostingView];
  hostingView.delegate = self;
  hostingView.model = [[CKComponentHostingViewTestModel alloc] initWithColor:[UIColor orangeColor] size:CKComponentSize::fromCGSize(CGSizeMake(75, 75))];
  hostingView.bounds = (CGRect){ .size = [hostingView sizeThatFits:CGSizeMake(75, CGFLOAT_MAX)] };
  [hostingView layoutIfNeeded];

  XCTAssertTrue(_calledSizeDidInvalidate, @"Expect -componentHostingViewSizeDidInvalidate: to be called when component size changes.");
}

- (void)testUpdateWithEmptyBoundsDoesntAttachLifecycleManager
{
  CKComponentLifecycleManager *manager = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class]];
  CKComponentHostingViewTestModel *model = [[CKComponentHostingViewTestModel alloc] initWithColor:[UIColor orangeColor] size:CKComponentSize::fromCGSize(CGSizeMake(50, 50))];
  CKComponentHostingView *hostingView = [[CKComponentHostingView alloc] initWithLifecycleManager:manager
                                                                               sizeRangeProvider:[CKComponentFlexibleSizeRangeProvider providerWithFlexibility:CKComponentSizeRangeFlexibleWidthAndHeight]
                                                                                         context:nil];
  hostingView.model = model;
  [hostingView layoutIfNeeded];

  XCTAssertFalse([manager isAttachedToView], @"Expect lifecycle manager to not be attached to the view when the bounds rect is empty.");
}

#pragma mark - CKComponentHostingViewDelegate

- (void)componentHostingViewDidInvalidateSize:(CKComponentHostingView *)hostingView
{
  _calledSizeDidInvalidate = YES;
}

@end
