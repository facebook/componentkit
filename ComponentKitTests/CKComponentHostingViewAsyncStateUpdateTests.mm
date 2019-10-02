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

#import <ComponentKitTestHelpers/CKTestRunLoopRunning.h>

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentFlexibleSizeRangeProvider.h>
#import <ComponentKit/CKComponentHostingView.h>
#import <ComponentKit/CKComponentHostingViewInternal.h>
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKComponentScope.h>
#import <ComponentKit/CKComponentSubclass.h>

@interface CKComponentHostingViewAsyncStateUpdateTests : XCTestCase <CKComponentProvider>
@end

@implementation CKComponentHostingViewAsyncStateUpdateTests

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  CKComponentScope scope([CKComponent class]);
  return CK::ComponentBuilder()
             .viewClass([UIView class])
             .backgroundColor(scope.state() ?: [UIColor blackColor])
             .build();
}

- (void)testAsynchronouslyUpdatingStateOfComponentEventuallyUpdatesCorrespondingView
{
  CKComponentHostingView *hostingView = [[CKComponentHostingView alloc] initWithComponentProvider:[CKComponentHostingViewAsyncStateUpdateTests class]
                                                                                sizeRangeProvider:[CKComponentFlexibleSizeRangeProvider providerWithFlexibility:CKComponentSizeRangeFlexibleWidthAndHeight]];
  hostingView.bounds = CGRectMake(0, 0, 100, 100);
  [hostingView layoutIfNeeded];

  UIView *componentView = [hostingView.containerView.subviews firstObject];
  XCTAssertEqualObjects(componentView.backgroundColor, [UIColor blackColor], @"Expected bg color to initially be black");

  const CKComponentLayout &layout = [hostingView mountedLayout];
  CKComponent *c = (CKComponent *)layout.component;
  [c updateState:^(id oldState){ return [UIColor redColor]; } mode:CKUpdateModeAsynchronous];

  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^{
    [hostingView layoutIfNeeded];
    return [componentView.backgroundColor isEqual:[UIColor redColor]];
  }));
}

- (void)testAsynchronouslyUpdatingStateOfComponentAndThenSynchronouslyUpdatingStateImmediatelyUpdatesCorrespondingView
{
  CKComponentHostingView *hostingView = [[CKComponentHostingView alloc] initWithComponentProvider:[CKComponentHostingViewAsyncStateUpdateTests class]
                                                                                sizeRangeProvider:[CKComponentFlexibleSizeRangeProvider providerWithFlexibility:CKComponentSizeRangeFlexibleWidthAndHeight]];
  hostingView.bounds = CGRectMake(0, 0, 100, 100);
  [hostingView layoutIfNeeded];

  UIView *componentView = [hostingView.containerView.subviews firstObject];
  XCTAssertEqualObjects(componentView.backgroundColor, [UIColor blackColor], @"Expected bg color to initially be black");

  const CKComponentLayout &layout = [hostingView mountedLayout];
  CKComponent *c = (CKComponent *)layout.component;
  [c updateState:^(id oldState){ return [UIColor redColor]; } mode:CKUpdateModeAsynchronous];
  [c updateState:^(id oldState){ return oldState; } mode:CKUpdateModeSynchronous];

  [hostingView layoutIfNeeded];
  XCTAssertEqualObjects(componentView.backgroundColor, [UIColor redColor],
                        @"Expected the two state updates to be rolled into one synchronous update");
}

@end
