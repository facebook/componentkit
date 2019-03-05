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

typedef struct {
  BOOL allowTapPassthrough;
  BOOL invalidateRemovedControllers;
  BOOL embedInFlexbox;
  BOOL embedInTestComponent;
  id<CKAnalyticsListener> analyticsListener;
  id<CKComponentSizeRangeProviding> sizeRangeProvider;
} CKComponentHostingViewConfiguration;

@interface AnalyticsListenerSpy: NSObject <CKAnalyticsListener> {
  @package
  NSInteger _willLayoutComponentTreeHitCount;
  NSInteger _didLayoutComponentTreeHitCount;
  NSInteger _willCollectAnimationsHitCount;
  NSInteger _didCollectAnimationsHitCount;
}
@end

@interface CKComponentHostingViewTests : XCTestCase <CKComponentProvider, CKComponentHostingViewDelegate>
+ (CKComponentHostingView *)makeHostingView:(const CKComponentHostingViewConfiguration &)options;
@end

@implementation CKComponentHostingViewTests {
  BOOL _calledSizeDidInvalidate;
  AnalyticsListenerSpy *_analyticsListenerSpy;
}

+ (CKComponentHostingView *)hostingView:(const CKComponentHostingViewConfiguration &)options
{
  auto const model = [[CKComponentHostingViewTestModel alloc]
                      initWithColor:[UIColor orangeColor]
                      size:CKComponentSize::fromCGSize(CGSizeMake(50, 50))
                      embedInFlexbox:options.embedInFlexbox
                      embedInTestComponent:options.embedInTestComponent];
  auto const view = [self makeHostingView:options];
  view.bounds = CGRectMake(0, 0, 100, 100);
  [view updateModel:model mode:CKUpdateModeSynchronous];
  [view layoutIfNeeded];
  return view;
}

+ (CKComponentHostingView *)makeHostingView:(const CKComponentHostingViewConfiguration &)options
{
  return [[CKComponentHostingView alloc] initWithComponentProvider:[CKComponentHostingViewTests class]
                                                 sizeRangeProvider:options.sizeRangeProvider ?: [CKComponentFlexibleSizeRangeProvider providerWithFlexibility:CKComponentSizeRangeFlexibleWidthAndHeight]
                                               componentPredicates:{}
                                     componentControllerPredicates:{}
                                                 analyticsListener:options.analyticsListener
                                                           options:{
                                                             .allowTapPassthrough = options.allowTapPassthrough,
                                                             .invalidateRemovedControllers = options.invalidateRemovedControllers,
                                                           }];
}

+ (CKComponent *)componentForModel:(CKComponentHostingViewTestModel *)model context:(id<NSObject>)context
{
  return CKComponentWithHostingViewTestModel(model);
}

- (void)setUp
{
  [super setUp];
  _calledSizeDidInvalidate = NO;
  _analyticsListenerSpy = [AnalyticsListenerSpy new];
}

- (void)testInitializationInsertsContainerViewInHierarchy
{
  CKComponentHostingView *view = [[self class] hostingView:{}];
  XCTAssertTrue(view.subviews.count == 1, @"Expect hosting view to have a single subview.");
}

- (void)testInitializationInsertsComponentViewInHierarchy
{
  CKComponentHostingView *view = [[self class] hostingView:{}];
  XCTAssertTrue([view.containerView.subviews count] > 0, @"Expect that initialization should insert component view as subview of container view.");
}

- (void)testUpdatingHostingViewBoundsResizesComponentView
{
  CKComponentHostingView *view = [[self class] hostingView:{}];
  view.bounds = CGRectMake(0, 0, 200, 200);
  [view layoutIfNeeded];

  UIView *componentView = [view.containerView.subviews firstObject];
  XCTAssertEqualObjects(componentView.backgroundColor, [UIColor orangeColor], @"Expected to find orange component view");
  XCTAssertTrue(CGRectEqualToRect(componentView.bounds, CGRectMake(0, 0, 200, 200)));
}

- (void)testImmediatelyUpdatesViewOnSynchronousModelChange
{
  CKComponentHostingView *view = [[self class] hostingView:{}];
  [view updateModel:[[CKComponentHostingViewTestModel alloc] initWithColor:[UIColor redColor] size:CKComponentSize::fromCGSize(CGSizeMake(50, 50))]
               mode:CKUpdateModeSynchronous];
  [view layoutIfNeeded];

  UIView *componentView = [view.containerView.subviews firstObject];
  XCTAssertEqualObjects(componentView.backgroundColor, [UIColor redColor], @"Expected component view to become red");
}

- (void)testEventuallyUpdatesViewOnAsynchronousModelChange
{
  CKComponentHostingView *view = [[self class] hostingView:{}];
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
  CKComponentHostingView *view = [[self class] hostingView:{}];
  view.delegate = self;
  [view updateModel:[[CKComponentHostingViewTestModel alloc] initWithColor:[UIColor orangeColor] size:CKComponentSize::fromCGSize(CGSizeMake(75, 75))]
               mode:CKUpdateModeSynchronous];
  XCTAssertTrue(_calledSizeDidInvalidate);
}

- (void)testInformsDelegateSizeIsInvalidatedOnContextChange
{
  CKComponentHostingView *view = [[self class] hostingView:{}];
  view.delegate = self;
  [view updateContext:@"foo" mode:CKUpdateModeSynchronous];
  XCTAssertTrue(_calledSizeDidInvalidate);
}

- (void)testUpdateWithEmptyBoundsMountLayout
{
  CKComponentHostingViewTestModel *model = [[CKComponentHostingViewTestModel alloc] initWithColor:[UIColor orangeColor] size:CKComponentSize::fromCGSize(CGSizeMake(50, 50))];
  auto const view = [CKComponentHostingViewTests makeHostingView:{}];
  [view updateModel:model mode:CKUpdateModeSynchronous];
  [view layoutIfNeeded];

  XCTAssertEqual([view.containerView.subviews count], 1u, @"Expect the component is mounted with empty bounds");
}

- (void)testComponentControllerReceivesInvalidateEventDuringDeallocation
{
  CKLifecycleTestComponent *testComponent = nil;
  @autoreleasepool {
    CKComponentHostingView *view = [[self class] hostingView:{}];
    [view updateContext:@"foo" mode:CKUpdateModeSynchronous];
    testComponent = (CKLifecycleTestComponent *)view.mountedLayout.component;
  }
  XCTAssertTrue(testComponent.controller.calledInvalidateController,
                @"Expected component controller to get invalidation event");
}

- (void)testComponentControllerReceivesInvalidateEventDuringDeallocationEvenWhenParentIsStillPresent
{
  CKComponentHostingView *view = [[self class] hostingView:{
    .embedInTestComponent = YES,
    .invalidateRemovedControllers = YES
  }];

  auto const testComponent = (CKEmbeddedTestComponent *)view.mountedLayout.component;
  auto const testLifecyleComponent = testComponent.lifecycleTestComponent;

  [testComponent setLifecycleTestComponentIsHidden:YES];
  [view layoutIfNeeded];

  XCTAssertTrue(testLifecyleComponent.controller.calledInvalidateController, @"Expected component controller to get invalidation event");
}

- (void)testComponentControllerReceivesDidPrepareLayoutForComponent
{
  CKLifecycleTestComponent *testComponent = nil;
  CKComponentHostingView *view = [[self class] hostingView:{}];
  [view updateContext:@"foo" mode:CKUpdateModeSynchronous];
  testComponent = (CKLifecycleTestComponent *)view.mountedLayout.component;
  XCTAssertTrue(testComponent.controller.calledDidPrepareLayoutForComponent,
                @"Expected component controller to get did attach component");
}

- (void)testAllowTapPassthroughOn
{
  // We embed this in a flexbox which allows the view to stay at its natural size
  // while still allowing the host to grow. This allows us to do our hit testing
  // properly below...
  CKComponentHostingView *view = [[self class] hostingView:{
    .allowTapPassthrough = YES,
    .embedInFlexbox = YES,
  }];

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
  CKComponentHostingView *view = [[self class] hostingView:{
    .embedInFlexbox = YES,
  }];

  [view layoutIfNeeded];

  // this should return the root view
  UIView *const shouldBeRoot = [view hitTest:CGPointMake(55, 5) withEvent:nil];
  XCTAssertTrue(shouldBeRoot == view.containerView, @"hitTest should return the hosting view or root view");
}

- (void)testSizeCache_CachedSizeIsUsedIfConstrainedSizesAreSame
{
  CKComponentHostingView *view = [[self class] hostingView:{
    .analyticsListener = _analyticsListenerSpy,
  }];
  const auto constrainedSize = CGSizeMake(100, 100);
  [view sizeThatFits:constrainedSize];
  [view sizeThatFits:constrainedSize];
  XCTAssertEqual(_analyticsListenerSpy->_willLayoutComponentTreeHitCount, 2);
}

- (void)testSizeCache_CachedSizeIsNotUsedIfConstrainedSizesAreDifferent
{
  CKComponentHostingView *view = [[self class] hostingView:{
    .analyticsListener = _analyticsListenerSpy,
    .sizeRangeProvider = [CKComponentFlexibleSizeRangeProvider providerWithFlexibility:CKComponentSizeRangeFlexibilityNone],
  }];
  const auto constrainedSize1 = CGSizeMake(100, 100);
  const auto constrainedSize2 = CGSizeMake(200, 200);
  [view sizeThatFits:constrainedSize1];
  [view sizeThatFits:constrainedSize2];
  XCTAssertEqual(_analyticsListenerSpy->_willLayoutComponentTreeHitCount, 3);
}

- (void)testSizeCache_CacheSizeIsNotUsedIfComponentIsUpdated
{
  CKComponentHostingView *view = [[self class] hostingView:{
    .analyticsListener = _analyticsListenerSpy,
  }];
  const auto constrainedSize = CGSizeMake(100, 100);
  [view sizeThatFits:constrainedSize];
  [view updateModel:nil mode:CKUpdateModeSynchronous];
  [view sizeThatFits:constrainedSize];
  XCTAssertEqual(_analyticsListenerSpy->_willLayoutComponentTreeHitCount, 3);
}

#pragma mark - CKComponentHostingViewDelegate

- (void)componentHostingViewDidInvalidateSize:(CKComponentHostingView *)hostingView
{
  _calledSizeDidInvalidate = YES;
}

- (void)test_WhenMountsLayout_ReportsWillCollectAnimationsEvent
{
  // This has a side-effect of mounting the test layout
  [[self class] hostingView:{
    .analyticsListener = _analyticsListenerSpy,
  }];

  XCTAssertEqual(_analyticsListenerSpy->_willCollectAnimationsHitCount, 1);
}

- (void)test_WhenMountsLayout_ReportsDidCollectAnimationsEvent
{
  // This has a side-effect of mounting the test layout
  [[self class] hostingView:{
    .analyticsListener = _analyticsListenerSpy,
  }];

  XCTAssertEqual(_analyticsListenerSpy->_didCollectAnimationsHitCount, 1);
}

@end

#pragma mark - CKAnalyticsListener

@implementation AnalyticsListenerSpy

- (void)willBuildComponentTreeWithScopeRoot:(CKComponentScopeRoot *)scopeRoot
                               buildTrigger:(BuildTrigger)buildTrigger
                               stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates {}
- (void)didBuildComponentTreeWithScopeRoot:(CKComponentScopeRoot *)scopeRoot component:(CKComponent *)component {}

- (void)willMountComponentTreeWithRootComponent:(CKComponent *)component {}
- (void)didMountComponentTreeWithRootComponent:(CKComponent *)component
                         mountAnalyticsContext:(CK::Component::MountAnalyticsContext *)mountAnalyticsContext {}

- (void)willCollectAnimationsFromComponentTreeWithRootComponent:(CKComponent *)component
{
  _willCollectAnimationsHitCount++;
}

- (void)didCollectAnimationsFromComponentTreeWithRootComponent:(CKComponent *)component
{
  _didCollectAnimationsHitCount++;
}

- (void)willLayoutComponentTreeWithRootComponent:(CKComponent *)component { _willLayoutComponentTreeHitCount++; }
- (void)didLayoutComponentTreeWithRootComponent:(CKComponent *)component { _didLayoutComponentTreeHitCount++; }

- (void)willBuildComponent:(Class)componentClass {}
- (void)didBuildComponent:(Class)componentClass {}

- (void)willMountComponent:(CKComponent *)component {}
- (void)didMountComponent:(CKComponent *)component {}

- (void)willLayoutComponent:(CKComponent *)component {}
- (void)didLayoutComponent:(CKComponent *)component {}

- (id<CKSystraceListener>)systraceListener { return nil; }

- (BOOL)shouldCollectMountInformationForRootComponent:(CKComponent *)component { return NO; }

- (void)didReuseNode:(id<CKTreeNodeProtocol>)node inScopeRoot:(CKComponentScopeRoot *)scopeRoot fromPreviousScopeRoot:(CKComponentScopeRoot *)previousScopeRoot {}

@end

@interface CKComponentHostingViewTests_ComponentProviderFunction : CKComponentHostingViewTests
@end

@implementation CKComponentHostingViewTests_ComponentProviderFunction

+ (CKComponentHostingView *)makeHostingView:(const CKComponentHostingViewConfiguration &)options
{
  auto const p = [](id<NSObject> m, id<NSObject>){ return CKComponentWithHostingViewTestModel(m); };
  return [[CKComponentHostingView alloc] initWithComponentProviderFunc:p
                                                     sizeRangeProvider:options.sizeRangeProvider ?: [CKComponentFlexibleSizeRangeProvider providerWithFlexibility:CKComponentSizeRangeFlexibleWidthAndHeight]
                                                   componentPredicates:{}
                                         componentControllerPredicates:{}
                                                     analyticsListener:options.analyticsListener
                                                               options:{
                                                                 .allowTapPassthrough = options.allowTapPassthrough,
                                                                 .invalidateRemovedControllers = options.invalidateRemovedControllers,
                                                               }];
}

@end
