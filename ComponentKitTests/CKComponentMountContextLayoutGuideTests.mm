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

#import <ComponentKitTestHelpers/CKComponentLifecycleTestHelper.h>

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKStaticLayoutComponent.h>

@protocol CKAnalyticsListener;

@interface CKComponentMountContextLayoutGuideTests : XCTestCase
@end

@interface CKLayoutGuideTestComponent : CKComponent
@property (nonatomic, readonly) UIEdgeInsets layoutGuideUsedAtMountTime;
@end

@implementation CKComponentMountContextLayoutGuideTests

- (void)testThatComponentIsPassedLayoutGuideDuringMountThatIndicatesItsDistanceFromRootComponentEdges
{
  CKLayoutGuideTestComponent *c = [CKLayoutGuideTestComponent new];
  CKStaticLayoutComponent *layoutComponent =
  [CKStaticLayoutComponent
   newWithView:{}
   size:{200, 200}
   children:{
     {{50, 50}, c, {100, 100}},
   }];
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:nullptr
                                                                                                                             sizeRangeProvider:nil];
  [componentLifecycleTestController updateWithState:{
    .componentLayout = [layoutComponent layoutThatFits:{} parentSize:{NAN, NAN}]
  }];

  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];

  XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(c.layoutGuideUsedAtMountTime, UIEdgeInsetsMake(50, 50, 50, 50)));
}

- (void)testNestedComponentReceivesCombinedLayoutGuide
{
  CKLayoutGuideTestComponent *c = [CKLayoutGuideTestComponent new];
  CKStaticLayoutComponent *innerLayoutComponent =
  [CKStaticLayoutComponent
   newWithView:{}
   size:{100, 100}
   children:{
     {{20, 20}, c, {60, 60}},
   }];
  CKStaticLayoutComponent *outerLayoutComponent =
  [CKStaticLayoutComponent
   newWithView:{}
   size:{200, 200}
   children:{
     {{100, 100}, innerLayoutComponent, {100, 100}},
   }];
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:nullptr
                                                                                                                             sizeRangeProvider:nil];
  [componentLifecycleTestController updateWithState:{
    .componentLayout = [outerLayoutComponent layoutThatFits:{} parentSize:{NAN, NAN}]
  }];

  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];

  XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(c.layoutGuideUsedAtMountTime, UIEdgeInsetsMake(120, 120, 20, 20)));
}

@end

@implementation CKLayoutGuideTestComponent

- (CK::Component::MountResult)mountInContext:(const CK::Component::MountContext &)context
                                        size:(const CGSize)size
                                    children:(std::shared_ptr<const std::vector<CKComponentLayoutChild>>)children
                              supercomponent:(CKComponent *)supercomponent
{
  const CK::Component::MountResult mountResult = [super mountInContext:context
                                                                  size:size
                                                              children:children
                                                        supercomponent:supercomponent];
  _layoutGuideUsedAtMountTime = context.layoutGuide;
  return mountResult;
}

@end
