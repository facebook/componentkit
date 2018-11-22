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

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentSubclass.h>

@interface CKComponentMountTests : XCTestCase
@end

@interface CKDontMountChildrenComponent : CKComponent
+ (instancetype)newWithChild:(CKComponent *)child;
@end

@implementation CKComponentMountTests

- (void)testThatMountingComponentThatReturnsMountChildrenNoDoesNotMountItsChild
{
  CKComponent *viewComponent = [CKComponent newWithView:{[UIView class]} size:{}];
  CKComponent *c = [CKDontMountChildrenComponent newWithChild:viewComponent];

  CKComponentLayout layout = [c layoutThatFits:{} parentSize:{NAN, NAN}];

  XCTAssertTrue(layout.children->front().layout.component == viewComponent,
               @"Expected view component to exist in the layout tree");

  UIView *view = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout(layout, view, nil, nil).mountedComponents;

  XCTAssertEqual([[view subviews] count], 0u,
                 @"CKDontMountChildrenComponent should have prevented view component from mounting");

  CKUnmountComponents(mountedComponents);
}

- (void)testMountingComponentAffectsResponderChain
{
  CKComponent *c = [CKComponent newWithView:{[UIView class]} size:{}];
  CKComponentLayout layout = [c layoutThatFits:{} parentSize:{NAN, NAN}];

  UIView *container = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout(layout, container, nil, nil).mountedComponents;
  XCTAssertEqualObjects(mountedComponents, [NSSet setWithObject:c], @"Didn't mount as expected");

  XCTAssertEqualObjects([c nextResponder], container, @"Did not setup responder correctly!");
  XCTAssertEqualObjects([c nextResponderAfterController], container, @"Did not setup responder correctly!");
}

- (void)testUnmounting
{
  CKComponent *a = [CKComponent newWithView:{[UIView class]} size:{}];
  CKComponent *b = [CKComponent newWithView:{[UIView class]} size:{}];

  const CKComponentLayout layoutBoth = {a, CGSizeZero,
    {
      {CGPointZero, {a, {}, {}}},
      {CGPointZero, {b, {}, {}}},
    }
  };

  UIView *container = [UIView new];
  NSSet *allMounted = CKMountComponentLayout(layoutBoth, container, nil, nil).mountedComponents;

  XCTAssertNotNil(a.viewContext.view, @"Didn't create view");
  XCTAssertNotNil(b.viewContext.view, @"Didn't create view");

  const CKComponentLayout layoutA = {a, CGSizeZero,
    {
      {CGPointZero, {a, {}, {}}},
    }
  };

  NSSet *someMounted = CKMountComponentLayout(layoutA, container, allMounted, nil).mountedComponents;

  XCTAssertNotNil(a.viewContext.view, @"Should still be mounted");
  XCTAssertNil(b.viewContext.view, @"Should not be mounted");

  CKUnmountComponents(someMounted);

  XCTAssertNil(a.viewContext.view, @"Should not be mounted");
  XCTAssertNil(b.viewContext.view, @"Should not be mounted");
}

@end

@implementation CKDontMountChildrenComponent
{
  CKComponent *_child;
}

+ (instancetype)newWithChild:(CKComponent *)child
{
  CKDontMountChildrenComponent *c = [self newWithView:{} size:{}];
  c->_child = child;
  return c;
}

- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
{
  return {
    self,
    constrainedSize.clamp({100, 100}),
    {{{0,0}, [_child layoutThatFits:{{100, 100}, {100, 100}} parentSize:{100, 100}]}}
  };
}

- (CK::Component::MountResult)mountInContext:(const CK::Component::MountContext &)context
size:(const CGSize)size
children:(std::shared_ptr<const std::vector<CKComponentLayoutChild>>)children
supercomponent:(CKComponent *)supercomponent
analyticsListener:(id<CKAnalyticsListener>)analyticsListener
{
  CK::Component::MountResult r = [super mountInContext:context size:size children:children supercomponent:supercomponent analyticsListener:analyticsListener];
  return {
    .mountChildren = NO,
    .contextForChildren = r.contextForChildren
  };
}

@end
