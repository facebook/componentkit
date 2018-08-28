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

#import <ComponentKitTestHelpers/CKEmbeddedTestComponent.h>
#import <ComponentKitTestHelpers/CKTestRunLoopRunning.h>
#import <ComponentKitTestHelpers/CKLifecycleTestComponent.h>

#import <ComponentKit/CKBuildComponent.h>
#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentFlexibleSizeRangeProvider.h>
#import <ComponentKit/CKComponentHostingView.h>
#import <ComponentKit/CKComponentHostingViewDelegate.h>
#import <ComponentKit/CKAnalyticsListener.h>
#import <ComponentKit/CKComponentHostingViewInternal.h>

#import "CKComponentHostingViewTestModel.h"

@interface CKComponentHostingViewTests : XCTestCase <CKComponentProvider, CKComponentHostingViewDelegate, CKAnalyticsListener>
@end

typedef struct {
  BOOL unifyBuildAndLayout;
  BOOL allowTapPassthrough;
  BOOL invalidateRemovedControllers;
  BOOL embedInFlexbox;
  BOOL embedInTestComponent;
  id<CKAnalyticsListener> analyticsListener;
  BOOL enableNewAnimationInfrastructure = NO;
} CKComponentHostingViewConfiguration;
static CKComponentHostingView *hostingView(const CKComponentHostingViewConfiguration &options = CKComponentHostingViewConfiguration())
{
  CKComponentHostingViewTestModel *model = [[CKComponentHostingViewTestModel alloc] initWithColor:[UIColor orangeColor]
                                                                                             size:CKComponentSize::fromCGSize(CGSizeMake(50, 50))
                                                                                   embedInFlexbox:options.embedInFlexbox
                                                                             embedInTestComponent:options.embedInTestComponent];
  CKComponentHostingView *view = [[CKComponentHostingView alloc] initWithComponentProvider:[CKComponentHostingViewTests class]
                                                                         sizeRangeProvider:[CKComponentFlexibleSizeRangeProvider providerWithFlexibility:CKComponentSizeRangeFlexibleWidthAndHeight]
                                                                       componentPredicates:{}
                                                             componentControllerPredicates:{}
                                                                         analyticsListener:options.analyticsListener
                                                                                   options:{
                                                                                     .unifyBuildAndLayout = options.unifyBuildAndLayout,
                                                                                     .allowTapPassthrough = options.allowTapPassthrough,
                                                                                     .invalidateRemovedControllers = options.invalidateRemovedControllers
                                                                                   }];
  view.bounds = CGRectMake(0, 0, 100, 100);
  [view updateModel:model mode:CKUpdateModeSynchronous];
  [view layoutIfNeeded];
  return view;
}

@implementation CKComponentHostingViewTests {
  BOOL _calledSizeDidInvalidate;
  NSInteger _willLayoutComponentTreeHitCount;
  NSInteger _didLayoutComponentTreeHitCount;
}

+ (CKComponent *)componentForModel:(CKComponentHostingViewTestModel *)model context:(id<NSObject>)context
{
  return CKComponentWithHostingViewTestModel(model);
}

- (void)setUp
{
  [super setUp];
  _calledSizeDidInvalidate = NO;
  _willLayoutComponentTreeHitCount = 0;
  _didLayoutComponentTreeHitCount = 0;
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

- (void)testImmediatelyUpdatesViewOnSynchronousModelChange
{
  CKComponentHostingView *view = hostingView();
  [view updateModel:[[CKComponentHostingViewTestModel alloc] initWithColor:[UIColor redColor] size:CKComponentSize::fromCGSize(CGSizeMake(50, 50))]
               mode:CKUpdateModeSynchronous];
  [view layoutIfNeeded];

  UIView *componentView = [view.containerView.subviews firstObject];
  XCTAssertEqualObjects(componentView.backgroundColor, [UIColor redColor], @"Expected component view to become red");
}

- (void)testEventuallyUpdatesViewOnAsynchronousModelChange
{
  CKComponentHostingView *view = hostingView();
  [view updateModel:[[CKComponentHostingViewTestModel alloc] initWithColor:[UIColor redColor] size:CKComponentSize::fromCGSize(CGSizeMake(50, 50))]
               mode:CKUpdateModeAsynchronous];
  [view layoutIfNeeded];

  UIView *componentView = [view.containerView.subviews firstObject];
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^{
    [view layoutIfNeeded];
    return [componentView.backgroundColor isEqual:[UIColor redColor]];
  }));
}

- (void)testInformsDelegateSizeIsInvalidatedOnModelChange
{
  CKComponentHostingView *view = hostingView();
  view.delegate = self;
  [view updateModel:[[CKComponentHostingViewTestModel alloc] initWithColor:[UIColor orangeColor] size:CKComponentSize::fromCGSize(CGSizeMake(75, 75))]
               mode:CKUpdateModeSynchronous];
  XCTAssertTrue(_calledSizeDidInvalidate);
}

- (void)testInformsDelegateSizeIsInvalidatedOnContextChange
{
  CKComponentHostingView *view = hostingView();
  view.delegate = self;
  [view updateContext:@"foo" mode:CKUpdateModeSynchronous];
  XCTAssertTrue(_calledSizeDidInvalidate);
}

- (void)testUpdateWithEmptyBoundsMountLayout
{
  CKComponentHostingViewTestModel *model = [[CKComponentHostingViewTestModel alloc] initWithColor:[UIColor orangeColor] size:CKComponentSize::fromCGSize(CGSizeMake(50, 50))];
  CKComponentHostingView *view = [[CKComponentHostingView alloc] initWithComponentProvider:[self class]
                                                                         sizeRangeProvider:[CKComponentFlexibleSizeRangeProvider providerWithFlexibility:CKComponentSizeRangeFlexibleWidthAndHeight]];
  [view updateModel:model mode:CKUpdateModeSynchronous];
  [view layoutIfNeeded];

  XCTAssertEqual([view.containerView.subviews count], 1u, @"Expect the component is mounted with empty bounds");
}

- (void)testComponentControllerReceivesInvalidateEventDuringDeallocation
{
  CKLifecycleTestComponent *testComponent = nil;
  @autoreleasepool {
    CKComponentHostingView *view = hostingView();
    [view updateContext:@"foo" mode:CKUpdateModeSynchronous];
    testComponent = (CKLifecycleTestComponent *)view.mountedLayout.component;
  }
  XCTAssertTrue(testComponent.controller.calledInvalidateController,
                @"Expected component controller to get invalidation event");
}

- (void)testComponentControllerReceivesInvalidateEventDuringDeallocationEvenWhenParentIsStillPresent
{
  CKComponentHostingView *view = hostingView({
    .embedInTestComponent = YES,
    .invalidateRemovedControllers = YES
  });
  
  auto const testComponent = (CKEmbeddedTestComponent *)view.mountedLayout.component;
  auto const testLifecyleComponent = testComponent.lifecycleTestComponent;
  
  [testComponent setLifecycleTestComponentIsHidden:YES];
  [view layoutIfNeeded];
  
  XCTAssertTrue(testLifecyleComponent.controller.calledInvalidateController, @"Expected component controller to get invalidation event");
}

- (void)testComponentControllerReceivesDidPrepareLayoutForComponent
{
  CKLifecycleTestComponent *testComponent = nil;
  CKComponentHostingView *view = hostingView();
  [view updateContext:@"foo" mode:CKUpdateModeSynchronous];
  testComponent = (CKLifecycleTestComponent *)view.mountedLayout.component;
  XCTAssertTrue(testComponent.controller.calledDidPrepareLayoutForComponent,
                @"Expected component controller to get did attach component");
}

- (void)testUpdatingHostingViewBoundsResizesComponentView_WithUnifiedBuildAndLayout
{
  CKComponentHostingView *view = hostingView({
    .unifyBuildAndLayout = YES
  });

  view.bounds = CGRectMake(0, 0, 200, 200);
  [view layoutIfNeeded];

  UIView *componentView = [view.containerView.subviews firstObject];
  XCTAssertEqualObjects(componentView.backgroundColor, [UIColor orangeColor], @"Expected to find orange component view");
  XCTAssertTrue(CGRectEqualToRect(componentView.bounds, CGRectMake(0, 0, 200, 200)));
}

- (void)testImmediatelyUpdatesViewOnSynchronousModelChange_WithUnifiedBuildAndLayout
{
  CKComponentHostingView *view = hostingView({
    .unifyBuildAndLayout = YES
  });
  [view updateModel:[[CKComponentHostingViewTestModel alloc] initWithColor:[UIColor redColor] size:CKComponentSize::fromCGSize(CGSizeMake(50, 50))]
               mode:CKUpdateModeSynchronous];
  [view layoutIfNeeded];

  UIView *componentView = [view.containerView.subviews firstObject];
  XCTAssertEqualObjects(componentView.backgroundColor, [UIColor redColor], @"Expected component view to become red");
}

- (void)testEventuallyUpdatesViewOnAsynchronousModelChange_WithUnifiedBuildAndLayout
{
  CKComponentHostingView *view = hostingView({
    .unifyBuildAndLayout = YES
  });
  [view updateModel:[[CKComponentHostingViewTestModel alloc] initWithColor:[UIColor redColor] size:CKComponentSize::fromCGSize(CGSizeMake(50, 50))]
               mode:CKUpdateModeAsynchronous];
  [view layoutIfNeeded];

  UIView *componentView = [view.containerView.subviews firstObject];
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^{
    [view layoutIfNeeded];
    return [componentView.backgroundColor isEqual:[UIColor redColor]];
  }));
}

- (void)testInformsDelegateSizeIsInvalidatedOnModelChange_WithUnifiedBuildAndLayout
{
  CKComponentHostingView *view = hostingView({
    .unifyBuildAndLayout = YES
  });
  view.delegate = self;
  [view updateModel:[[CKComponentHostingViewTestModel alloc] initWithColor:[UIColor orangeColor] size:CKComponentSize::fromCGSize(CGSizeMake(75, 75))]
               mode:CKUpdateModeSynchronous];
  XCTAssertTrue(_calledSizeDidInvalidate);
}

- (void)testInformsDelegateSizeIsInvalidatedOnContextChange_WithUnifiedBuildAndLayout
{
  CKComponentHostingView *view = hostingView({
    .unifyBuildAndLayout = YES
  });
  view.delegate = self;
  [view updateContext:@"foo" mode:CKUpdateModeSynchronous];
  XCTAssertTrue(_calledSizeDidInvalidate);
}

- (void)testUpdateWithEmptyBoundsMountLayout_WithUnifiedBuildAndLayout
{
  CKComponentHostingViewTestModel *model = [[CKComponentHostingViewTestModel alloc] initWithColor:[UIColor orangeColor] size:CKComponentSize::fromCGSize(CGSizeMake(50, 50))];
  CKComponentHostingView *view = [[CKComponentHostingView alloc] initWithComponentProvider:[self class]
                                                                         sizeRangeProvider:[CKComponentFlexibleSizeRangeProvider providerWithFlexibility:CKComponentSizeRangeFlexibleWidthAndHeight]];
  [view updateModel:model mode:CKUpdateModeSynchronous];
  [view layoutIfNeeded];

  XCTAssertEqual([view.containerView.subviews count], 1u, @"Expect the component is mounted with empty bounds");
}

- (void)testComponentControllerReceivesInvalidateEventDuringDeallocation_WithUnifiedBuildAndLayout
{
  CKLifecycleTestComponent *testComponent = nil;
  @autoreleasepool {
    CKComponentHostingView *view = hostingView({
      .unifyBuildAndLayout = YES
    });
    [view updateContext:@"foo" mode:CKUpdateModeSynchronous];
    testComponent = (CKLifecycleTestComponent *)view.mountedLayout.component;
  }
  XCTAssertTrue(testComponent.controller.calledInvalidateController,
                @"Expected component controller to get invalidation event");
}

- (void)testAllowTapPassthroughOn
{
  // We embed this in a flexbox which allows the view to stay at its natural size
  // while still allowing the host to grow. This allows us to do our hit testing
  // properly below...
  CKComponentHostingView *view = hostingView({
    .allowTapPassthrough = YES,
    .embedInFlexbox = YES,
  });

  [view layoutIfNeeded];

  // this point should hit the component
  UIView *const shouldHit = [view hitTest:CGPointMake(5, 5) withEvent:nil];
  XCTAssertNotNil(shouldHit, @"When allowTapPassthrough is YES, hitTest should return nil");

  // this one misses
  UIView *const shouldMiss = [view hitTest:CGPointMake(55, 5) withEvent:nil];
  XCTAssertNil(shouldMiss, @"When allowTapPassthrough is YES, hitTest should return nil");
}

- (void)testAllowTapPassthroughOff
{
  // We embed this in a flexbox which allows the view to stay at its natural size
  // while still allowing the host to grow. This allows us to do our hit testing
  // properly below...
  CKComponentHostingView *view = hostingView({
    .embedInFlexbox = YES,
  });

  [view layoutIfNeeded];

  // this should return the root view
  UIView *const shouldBeRoot = [view hitTest:CGPointMake(55, 5) withEvent:nil];
  XCTAssertTrue(shouldBeRoot == view.containerView, @"hitTest should return the hosting view or root view");
}

#pragma mark - CKComponentHostingViewDelegate

- (void)componentHostingViewDidInvalidateSize:(CKComponentHostingView *)hostingView
{
  _calledSizeDidInvalidate = YES;
}

#pragma mark - CKAnalyticsListener

- (void)willBuildComponentTreeWithScopeRoot:(CKComponentScopeRoot *)scopeRoot buildTrigger:(BuildTrigger)buildTrigger { }
- (void)didBuildComponentTreeWithScopeRoot:(CKComponentScopeRoot *)scopeRoot component:(CKComponent *)component { }

- (void)willMountComponentTreeWithRootComponent:(CKComponent *)component { }
- (void)didMountComponentTreeWithRootComponent:(CKComponent *)component { }

- (void)willLayoutComponentTreeWithRootComponent:(CKComponent *)component { _willLayoutComponentTreeHitCount++; }
- (void)didLayoutComponentTreeWithRootComponent:(CKComponent *)component { _didLayoutComponentTreeHitCount++; }

@end
