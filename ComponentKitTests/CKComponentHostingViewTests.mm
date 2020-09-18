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
#import <ComponentKit/CKOptional.h>
#import <ComponentKitTestHelpers/CKAnalyticsListenerSpy.h>

#import "CKComponentHostingViewTestModel.h"

typedef struct {
  BOOL allowTapPassthrough;
  CKComponentHostingViewWrapperType wrapperType;
  id<CKAnalyticsListener> analyticsListener;
  id<CKComponentSizeRangeProviding> sizeRangeProvider;
  CK::Optional<CGSize> initialSize;
  BOOL shouldUpdateModelAfterCreation = YES;
  void(^willGenerateComponent)();
} CKComponentHostingViewConfiguration;


static CKComponent *CKComponentTestComponentProviderFunc(id<NSObject> model, id<NSObject> context)
{
  return CKComponentWithHostingViewTestModel(model);
}

@interface CKComponentHostingViewTests : XCTestCase <CKComponentHostingViewDelegate>
+ (CKComponentHostingView *)makeHostingView:(const CKComponentHostingViewConfiguration &)options;
@end

@implementation CKComponentHostingViewTests {
  BOOL _calledSizeDidInvalidate;
  CKAnalyticsListenerSpy *_analyticsListenerSpy;
}

+ (CKComponentHostingView *)hostingView:(const CKComponentHostingViewConfiguration &)options
{
  auto const model = [[CKComponentHostingViewTestModel alloc]
                      initWithColor:[UIColor orangeColor]
                      size:CKComponentSize::fromCGSize(CGSizeMake(50, 50))
                      wrapperType:options.wrapperType
                      willGenerateComponent:options.willGenerateComponent];
  auto const view = [self makeHostingView:options];
  if (options.shouldUpdateModelAfterCreation) {
    view.bounds = CGRectMake(0, 0, 100, 100);
    [view updateModel:model mode:CKUpdateModeSynchronous];
    [view layoutIfNeeded];
  }
  return view;
}

+ (CKComponentHostingView *)makeHostingView:(const CKComponentHostingViewConfiguration &)options
{
  return [[CKComponentHostingView alloc] initWithComponentProviderFunc:CKComponentTestComponentProviderFunc
                                                 sizeRangeProvider:options.sizeRangeProvider ?: [CKComponentFlexibleSizeRangeProvider providerWithFlexibility:CKComponentSizeRangeFlexibleWidthAndHeight]
                                               componentPredicates:{}
                                     componentControllerPredicates:{}
                                                 analyticsListener:options.analyticsListener
                                                           options:{
                                                             .allowTapPassthrough = options.allowTapPassthrough,
                                                             .initialSize = options.initialSize,
                                                           }];
}

/// Used to identify component provider class / function
+ (NSString *)componentProviderIdentifier
{
  return [NSString stringWithFormat:@"%p", [CKComponentHostingViewTests class]];
}

+ (CK::NonNull<NSString *>)rootViewCategory
{
  return CK::makeNonNull([NSString stringWithFormat:@"%@-%@",
                          NSStringFromClass([CKComponentHostingView class]),
                          [self componentProviderIdentifier]]);
}

- (void)setUp
{
  [super setUp];
  _calledSizeDidInvalidate = NO;
  _analyticsListenerSpy = [CKAnalyticsListenerSpy new];
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

- (void)testInformsDelegateSizeIsInvalidatedOnAsynchronousUpdate
{
  CKComponentHostingView *view = [[self class] hostingView:{}];
  view.delegate = self;
  [view updateContext:@"foo" mode:CKUpdateModeAsynchronous];
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    return _calledSizeDidInvalidate;
  }));
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

- (void)testComponentControllerReceivesDidInit
{
  CKComponentHostingView *view = [[self class] hostingView:{}];
  CKLifecycleTestComponent *testComponent = (CKLifecycleTestComponent *)view.mountedLayout.component;

  XCTAssertTrue(testComponent.controller.calledDidInit, @"Expected component controller to get did init event");
}

- (void)testComponentControllerReceivesInvalidateEventDuringDeallocationEvenWhenParentIsStillPresent
{
  CKComponentHostingView *view = [[self class] hostingView:{
    .wrapperType = CKComponentHostingViewWrapperTypeTestComponent,
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
    .wrapperType = CKComponentHostingViewWrapperTypeFlexbox,
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
    .wrapperType = CKComponentHostingViewWrapperTypeFlexbox,
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
  XCTAssertEqual(_analyticsListenerSpy.willLayoutComponentTreeHitCount, 2);
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
  XCTAssertEqual(_analyticsListenerSpy.willLayoutComponentTreeHitCount, 3);
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
  XCTAssertEqual(_analyticsListenerSpy.willLayoutComponentTreeHitCount, 3);
}

- (void)testUpdateModel_ComponentIsReused
{
  CKComponentHostingView *view = [[self class] hostingView:{
    .analyticsListener = _analyticsListenerSpy,
    .wrapperType = CKComponentHostingViewWrapperTypeRenderComponent,
  }];
  const auto c1 = (CKRenderLifecycleTestComponent *)view.mountedLayout.component;
  XCTAssertTrue(c1.isRenderFunctionCalled);

  [view updateModel:[[CKComponentHostingViewTestModel alloc]
                     initWithColor:nil
                     size:{}
                     wrapperType:CKComponentHostingViewWrapperTypeRenderComponent
                     willGenerateComponent:nil]
               mode:CKUpdateModeSynchronous];
  [view layoutIfNeeded];
  const auto c2 = (CKRenderLifecycleTestComponent *)view.mountedLayout.component;
  XCTAssertFalse(c2.isRenderFunctionCalled);
}

- (void)testReload_ComponentIsNotReused
{
  CKComponentHostingView *view = [[self class] hostingView:{
    .analyticsListener = _analyticsListenerSpy,
    .wrapperType = CKComponentHostingViewWrapperTypeRenderComponent,
  }];
  const auto c1 = (CKRenderLifecycleTestComponent *)view.mountedLayout.component;
  XCTAssertTrue(c1.isRenderFunctionCalled);

  [view reloadWithMode:CKUpdateModeSynchronous];
  [view layoutIfNeeded];
  const auto c2 = (CKRenderLifecycleTestComponent *)view.mountedLayout.component;
  XCTAssertTrue(c2.isRenderFunctionCalled);
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

  XCTAssertEqual(_analyticsListenerSpy.willCollectAnimationsHitCount, 1);
}

- (void)test_WhenMountsLayout_ReportsDidCollectAnimationsEvent
{
  // This has a side-effect of mounting the test layout
  [[self class] hostingView:{
    .analyticsListener = _analyticsListenerSpy,
  }];

  XCTAssertEqual(_analyticsListenerSpy.didCollectAnimationsHitCount, 1);
}

- (void)test_LayoutAndGenerationOfComponentAreOnMainThreadWhenAsyncUpdateIsTriggeredWithoutInitialSize
{
  const auto hostingView = [[self class] hostingView:{
    .analyticsListener = _analyticsListenerSpy,
    .shouldUpdateModelAfterCreation = NO,
  }];
  [hostingView updateModel:nil mode:CKUpdateModeAsynchronous];
  [hostingView layoutIfNeeded];
  XCTAssertEqual(_analyticsListenerSpy.didLayoutComponentTreeHitCount, 1);
  XCTAssertEqual(_analyticsListenerSpy.didMountComponentHitCount, 1);
}

- (void)test_LayoutAndGenerationOfComponentAreNotOnMainThreadWhenAsyncUpdateIsTriggeredWithInitialSize
{
  const auto hostingView = [[self class] hostingView:{
    .analyticsListener = _analyticsListenerSpy,
    .shouldUpdateModelAfterCreation = NO,
    .initialSize = CGSizeMake(100, 100),
  }];
  [hostingView updateModel:nil mode:CKUpdateModeAsynchronous];
  [hostingView layoutIfNeeded];
  XCTAssertEqual(_analyticsListenerSpy.didLayoutComponentTreeHitCount, 0);
  XCTAssertEqual(_analyticsListenerSpy.didMountComponentHitCount, 0);

  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    [hostingView layoutIfNeeded];
    return _analyticsListenerSpy.didLayoutComponentTreeHitCount == 1
    && _analyticsListenerSpy.didMountComponentHitCount == 1;
  }));
}

- (void)test_LayoutAndGenerationOfComponentAreOnMainThreadWhenSyncUpdateIsTriggeredWithInitialSize
{
  const auto hostingView = [[self class] hostingView:{
    .analyticsListener = _analyticsListenerSpy,
    .shouldUpdateModelAfterCreation = NO,
    .initialSize = CGSizeMake(100, 100),
  }];
  [hostingView updateModel:nil mode:CKUpdateModeSynchronous];
  [hostingView layoutIfNeeded];
  XCTAssertEqual(_analyticsListenerSpy.didLayoutComponentTreeHitCount, 1);
  XCTAssertEqual(_analyticsListenerSpy.didMountComponentHitCount, 1);
}

- (void)test_CurrentTraitCollectionIsCorrectInBackgroundQueueWhenTraitCollectionIsSet
{
  if (@available(iOS 13.0, tvOS 13.0, *)) {
    __block UITraitCollection *currentTraitCollection = nil;
    const auto hostingView = [[self class] hostingView:{
      .analyticsListener = _analyticsListenerSpy,
      .shouldUpdateModelAfterCreation = YES,
      .initialSize = CGSizeMake(100, 100),
      .willGenerateComponent = ^{
        currentTraitCollection = [UITraitCollection currentTraitCollection];
      },
    }];

    XCTAssertEqual(currentTraitCollection.userInterfaceIdiom, hostingView.traitCollection.userInterfaceIdiom);
    [hostingView updateContext:nil mode:CKUpdateModeAsynchronous];
    CKRunRunLoopUntilBlockIsTrue(^BOOL{
      return _analyticsListenerSpy.didBuildComponentTreeHitCount == 2;
    });
    XCTAssertEqual(currentTraitCollection.userInterfaceIdiom, hostingView.traitCollection.userInterfaceIdiom);
  }
}

@end

@interface CKComponentHostingViewTests_ComponentProviderFunction : CKComponentHostingViewTests
@end

@implementation CKComponentHostingViewTests_ComponentProviderFunction

+ (CKComponentHostingView *)makeHostingView:(const CKComponentHostingViewConfiguration &)options
{
  return [[CKComponentHostingView alloc] initWithComponentProviderFunc:CKComponentTestComponentProviderFunc
                                                     sizeRangeProvider:options.sizeRangeProvider ?: [CKComponentFlexibleSizeRangeProvider providerWithFlexibility:CKComponentSizeRangeFlexibleWidthAndHeight]
                                                   componentPredicates:{}
                                         componentControllerPredicates:{}
                                                     analyticsListener:options.analyticsListener
                                                               options:{
                                                                 .allowTapPassthrough = options.allowTapPassthrough,
                                                                 .initialSize = options.initialSize,
                                                               }];
}

+ (NSString *)componentProviderIdentifier
{
  return [NSString stringWithFormat:@"%p", CKComponentTestComponentProviderFunc];
}

@end
