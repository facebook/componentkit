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

#import "CKTestRunLoopRunning.h"

#import "CKComponent.h"
#import "CKComponentFlexibleSizeRangeProvider.h"
#import "CKComponentHostingView.h"
#import "CKComponentHostingViewInternal.h"
#import "CKComponentInternal.h"
#import "CKComponentScope.h"
#import "CKComponentSubclass.h"

@interface CKComponentHostingViewAsyncStateUpdateTests : XCTestCase <CKComponentProvider>
@end

@implementation CKComponentHostingViewAsyncStateUpdateTests

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  CKComponentScope scope([CKComponent class]);
  return [CKComponent
          newWithView:{
            [UIView class],
            {{@selector(setBackgroundColor:), scope.state() ?: [UIColor blackColor]}}
          }
          size:{}];
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
  [layout.component updateStateWithExpensiveReflow:^(id oldState){ return [UIColor redColor]; }];

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
  [layout.component updateStateWithExpensiveReflow:^(id oldState){ return [UIColor redColor]; }];
  [layout.component updateState:^(id oldState){ return oldState; }];

  [hostingView layoutIfNeeded];
  XCTAssertEqualObjects(componentView.backgroundColor, [UIColor redColor],
                        @"Expected the two state updates to be rolled into one synchronous update");
}

@end
