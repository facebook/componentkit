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
#import "CKComponentLayout.h"
#import "CKComponentSubclass.h"

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
  NSSet *mountedComponents = CKMountComponentLayout(layout, view);

  XCTAssertEqual([[view subviews] count], 0u,
                 @"CKDontMountChildrenComponent should have prevented view component from mounting");

  for (CKComponent *component in mountedComponents) {
    [component unmount];
  }
}

- (void)testMountingComponentAffectsResponderChain
{
  CKComponent *c = [CKComponent newWithView:{[UIView class]} size:{}];
  CKComponentLayout layout = [c layoutThatFits:{} parentSize:{NAN, NAN}];

  UIView *container = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout(layout, container);
  XCTAssertEqualObjects(mountedComponents, [NSSet setWithObject:c], @"Didn't mount as expected");

  XCTAssertEqualObjects([c nextResponder], container, @"Did not setup responder correctly!");
  XCTAssertEqualObjects([c nextResponderAfterController], container, @"Did not setup responder correctly!");
}

- (void)testUnmounting
{
  CKComponent *a = [CKComponent newWithView:{[UIView class]} size:{}];
  CKComponent *b = [CKComponent newWithView:{[UIView class]} size:{}];
  CKComponent *c = [CKComponent newWithView:{[UIView class]} size:{}];

  CKComponentLayout layoutAll = {a, CGSizeZero,
    {
      {CGPointZero, {b, {}, {}}},
      {CGPointZero, {c, {}, {}}},
    }
  };

  CKComponentLayout layoutSome = {a, CGSizeZero,
    {
      {CGPointZero, {c, {}, {}}},
    }
  };
  
  
  UIView *container = [UIView new];
  NSSet *allMounted = CKMountComponentLayout(layoutAll, container);

  XCTAssertNotNil(a.viewContext.view, @"Didn't create view");
  XCTAssertNotNil(b.viewContext.view, @"Didn't create view");
  XCTAssertNotNil(c.viewContext.view, @"Didn't create view");

  NSSet *someMounted = CKMountComponentLayout(layoutSome, container);

  XCTAssertNotNil(a.viewContext.view, @"Should still be mounted");
  XCTAssertNotNil(b.viewContext.view, @"Should still be mounted");
  XCTAssertNotNil(c.viewContext.view, @"Should still be mounted");

  CKUnmountComponents(someMounted, allMounted);

  XCTAssertNotNil(a.viewContext.view, @"Should still be mounted");
  XCTAssertNil(b.viewContext.view, @"Should not be mounted");
  XCTAssertNotNil(c.viewContext.view, @"Should still be mounted");

  CKUnmountComponents(someMounted);

  XCTAssertNil(a.viewContext.view, @"Should not be mounted");
  XCTAssertNil(b.viewContext.view, @"Should not be mounted");
  XCTAssertNil(c.viewContext.view, @"Should not be mounted");


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
{
  CK::Component::MountResult r = [super mountInContext:context size:size children:children supercomponent:supercomponent];
  return {
    .mountChildren = NO,
    .contextForChildren = r.contextForChildren
  };
}

@end
