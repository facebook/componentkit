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

#import "CKComponent.h"
#import "CKComponentInternal.h"
#import "CKComponentLifecycleManager.h"
#import "CKComponentSubclass.h"
#import "CKStaticLayoutComponent.h"

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
  CKComponentLayout spec = [layoutComponent layoutThatFits:{} parentSize:{NAN, NAN}];
  CKComponentLifecycleManager *m = [[CKComponentLifecycleManager alloc] init];
  [m updateWithState:{.layout = spec}];

  UIView *v = [[UIView alloc] init];
  [m attachToView:v];

  XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(c.layoutGuideUsedAtMountTime, UIEdgeInsetsMake(50, 50, 50, 50)));
}

- (void)testNestedComponentReceivesCombinedLayoutGuide
{
  CKLayoutGuideTestComponent *c = [CKLayoutGuideTestComponent new];
  CKStaticLayoutComponent *layoutComponent =
  [CKStaticLayoutComponent
   newWithView:{}
   size:{100, 100}
   children:{
     {{20, 20}, c, {60, 60}},
   }];
  CKStaticLayoutComponent *wrappingLayoutComponent =
  [CKStaticLayoutComponent
   newWithView:{}
   size:{200, 200}
   children:{
     {{100, 100}, layoutComponent, {100, 100}},
   }];
  CKComponentLayout spec = [wrappingLayoutComponent layoutThatFits:{} parentSize:{NAN, NAN}];
  CKComponentLifecycleManager *m = [[CKComponentLifecycleManager alloc] init];
  [m updateWithState:{.layout = spec}];

  UIView *v = [[UIView alloc] init];
  [m attachToView:v];

  XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(c.layoutGuideUsedAtMountTime, UIEdgeInsetsMake(120, 120, 20, 20)));
}

@end

@implementation CKLayoutGuideTestComponent

- (CK::Component::MountResult)mountInContext:(const CK::Component::MountContext &)context
                                        size:(const CGSize)size
                                    children:(std::shared_ptr<const std::vector<CKComponentLayoutChild>>)children
                              supercomponent:(CKComponent *)supercomponent
{
  CK::Component::MountResult r = [super mountInContext:context size:size children:children supercomponent:supercomponent];
  _layoutGuideUsedAtMountTime = context.layoutGuide;
  return r;
}

@end
