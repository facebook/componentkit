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

#import <ComponentKit/CKBuildComponent.h>
#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentContext.h>
#import <ComponentKit/CKComponentScopeRootFactory.h>
#import <ComponentKit/CKRenderComponent.h>
#import <ComponentKit/CKRenderLayoutWithChildrenComponent.h>

@interface CKContextTestComponent<T> : CKComponent
@property (nonatomic, strong) id<NSObject> objectFromContext;
@end

@interface CKContextTestRenderComponent<T> : CKRenderComponent
+ (instancetype)newWithContextObject:(NSNumber *)object;
@property (nonatomic, strong) id<NSObject> objectFromContext;
@property (nonatomic, strong) CKContextTestComponent *child;
@end

@interface CKContextTestWithChildrenComponent : CKRenderLayoutWithChildrenComponent
+ (instancetype)newWithChildren:(std::vector<CKComponent *>)children;
@property (nonatomic, assign) std::vector<CKComponent *>children;
@end

@interface CKComponentContextTests : XCTestCase
@end

@implementation CKComponentContextTests

- (void)testEstablishingAComponentContextAllowsYouToFetchIt
{
  NSObject *o = [[NSObject alloc] init];
  CKComponentContext<NSObject> context(o);

  NSObject *o2 = CKComponentContext<NSObject>::get();
  XCTAssertTrue(o == o2);
}

- (void)testFetchingAnObjectThatHasNotBeenEstablishedWithGetReturnsNil
{
  XCTAssertNil(CKComponentContext<NSObject>::get(), @"Expected to return nil without throwing");
}

- (void)testComponentContextCleansUpWhenItGoesOutOfScope
{
  {
    NSObject *o = [[NSObject alloc] init];
    CKComponentContext<NSObject> context(o);
  }
  XCTAssertNil(CKComponentContext<NSObject>::get(), @"Expected getting NSObject to return nil as its scope is closed");
}

- (void)testComponentContextDoesntCleansUpWhenItGoesOutOfScopeIfThereIsRenderComponentInSubtree
{
  NSObject *o = [[NSObject alloc] init];
  CKComponent *component = [CKComponent new];

  {
    CKComponentContext<NSObject> context(o);
    // This makes sure that the context values will leave after the context object goes out of scope.
    CKComponentContextHelper::didCreateRenderComponent(component);
  }

  CKComponentContextHelper::willBuildComponentTree(component);
  NSObject *o2 = CKComponentContext<NSObject>::get();
  XCTAssertTrue(o == o2);

  CKComponentContextHelper::didBuildComponentTree(component);
  XCTAssertNil(CKComponentContext<NSObject>::get(), @"Expected getting NSObject to return nil as its scope is closed");
}

- (void)testNestedComponentContextChangesValueAndRestoresItAfterGoingOutOfScope
{
  NSObject *outer = [[NSObject alloc] init];
  CKComponentContext<NSObject> outerContext(outer);
  {
    NSObject *inner = [[NSObject alloc] init];
    CKComponentContext<NSObject> innerContext(inner);
    XCTAssertTrue(CKComponentContext<NSObject>::get() == inner);
  }
  XCTAssertTrue(CKComponentContext<NSObject>::get() == outer);
}

- (void)testSameContextInSiblingComponentsWithRenderInTheTree
{
  NSNumber *n0 = @0;
  
  //                +--------+
  //                |push(n0)|
  //                |  Root  |
  //                |        |
  //                |        |
  //     +----------+---+----+---------+
  //     |              |              |
  //     |              |              |
  // +---v----+     +---v----+    +----v---+
  // |        |     |        |    |        |
  // |   c1   |     |   c2   |    |   c3   |
  // |(render)|     |(render)|    |(render)|
  // |        |     |        |    |        |
  // +---+----+     +---+----+    +----+---+
  //     |              |              |
  //     |              |              |
  // +---v----+     +---v----+    +----v---+
  // |read(n0)|     |read(n0)|    |read(n0)|
  // | child1 |     | child2 |    | child3 |
  // |        |     |        |    |        |
  // |        |     |        |    |        |
  // +--------+     +--------+    +--------+
  
  __block CKContextTestRenderComponent *c1;
  __block CKContextTestRenderComponent *c2;
  __block CKContextTestRenderComponent *c3;
  auto const componentFactory = ^{
    CKComponentContext<NSNumber> context(n0);
    c1 = [CKContextTestRenderComponent new];
    c2 = [CKContextTestRenderComponent new];
    c3 = [CKContextTestRenderComponent new];
    return [CKContextTestWithChildrenComponent newWithChildren:{c1,c2,c3}];
  };
  
  auto const buildResults = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, componentFactory);
  
  XCTAssertTrue(n0 == c1.child.objectFromContext);
  XCTAssertTrue(n0 == c2.child.objectFromContext);
  XCTAssertTrue(n0 == c3.child.objectFromContext);
}

- (void)testSameContextInSiblingComponentsAndOverrideContextWithRenderInTheTree
{
  NSNumber *n0 = @0;
  NSNumber *n1 = @1;
  NSNumber *n2 = @2;
  NSNumber *n3 = @3;

  //                +--------+
  //                |push(n0)|
  //                |  Root  |
  //                |        |
  //                |        |
  //     +----------+---+----+---------+
  //     |              |              |
  //     |              |              |
  // +---v----+     +---v----+    +----v---+
  // |read(n0)|     |read(n0)|    |read(n0)|
  // |   c1   |     |   c2   |    |   c3   |
  // |(render)|     |(render)|    |(render)|
  // |push(n1)|     |push(n2)|    |push(n3)|
  // +---+----+     +---+----+    +----+---+
  //     |              |              |
  //     |              |              |
  // +---v----+     +---v----+    +----v---+
  // |read(n1)|     |read(n2)|    |read(n3)|
  // | child1 |     | child2 |    | child3 |
  // |        |     |        |    |        |
  // |        |     |        |    |        |
  // +--------+     +--------+    +--------+

  __block CKContextTestRenderComponent *c1;
  __block CKContextTestRenderComponent *c2;
  __block CKContextTestRenderComponent *c3;
  auto const componentFactory = ^{
    CKComponentContext<NSNumber> context(n0);
    c1 = [CKContextTestRenderComponent newWithContextObject:n1];
    c2 = [CKContextTestRenderComponent newWithContextObject:n2];
    c3 = [CKContextTestRenderComponent newWithContextObject:n3];
    return [CKContextTestWithChildrenComponent newWithChildren:{c1,c2,c3}];
  };

  auto const buildResults = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, componentFactory);

  XCTAssertTrue(n0 == c1.objectFromContext);
  XCTAssertTrue(n0 == c2.objectFromContext);
  XCTAssertTrue(n0 == c3.objectFromContext);
  XCTAssertTrue(n1 == c1.child.objectFromContext);
  XCTAssertTrue(n2 == c2.child.objectFromContext);
  XCTAssertTrue(n3 == c3.child.objectFromContext);
}

- (void)testTriplyNestedComponentContextWithNilMiddleValueCorrectlyRestoresOuterValue
{
  // This tests an obscure edge case with restoring values for context as we pop scopes.
  NSObject *outer = [[NSObject alloc] init];
  CKComponentContext<NSObject> outerContext(outer);
  {
    CKComponentContext<NSObject> middleContext(nil);
    XCTAssertTrue(CKComponentContext<NSObject>::get() == nil);
    {
      NSObject *inner = [[NSObject alloc] init];
      CKComponentContext<NSObject> innerContext(inner);
      XCTAssertTrue(CKComponentContext<NSObject>::get() == inner);
    }
  }
  XCTAssertTrue(CKComponentContext<NSObject>::get() == outer);
}

- (void)testFetchingAllComponentContextItemsReturnsObjects
{
  NSObject *o = [[NSObject alloc] init];
  CKComponentContext<NSObject> context(o);
  const CKComponentContextContents contents = CKComponentContextHelper::fetchAll();
  XCTAssertEqualObjects(contents.objects, @{[NSObject class]: o});
}

- (void)testFetchingAllComponentContextItemsTwiceReturnsEqualContents
{
  CKComponentContext<NSObject> context([[NSObject alloc] init]);
  const CKComponentContextContents contents1 = CKComponentContextHelper::fetchAll();
  const CKComponentContextContents contents2 = CKComponentContextHelper::fetchAll();
  XCTAssertTrue(contents1 == contents2);
}

- (void)testFetchingAllComponentContextItemsBeforeAndAfterModificationReturnsUnequalContents
{
  CKComponentContext<NSObject> context1([[NSObject alloc] init]);
  const CKComponentContextContents contents1 = CKComponentContextHelper::fetchAll();
  CKComponentContext<NSObject> context2([[NSObject alloc] init]);
  const CKComponentContextContents contents2 = CKComponentContextHelper::fetchAll();
  XCTAssertTrue(contents1 != contents2);
}

- (void)testFetchingAllComponentContextWhenRenderComponentIsInTheTree
{
  NSObject *o1 = [NSObject alloc];
  NSObject *o2 = [NSObject alloc];

  CKComponent *component1;

  {
    CKComponentContext<NSObject> context1(o1);
    XCTAssertEqualObjects(CKComponentContextHelper::fetchAll().objects, @{[NSObject class]: o1});

    // Simulate creation of render component.
    component1 = [CKComponent new];
    CKComponentContextHelper::didCreateRenderComponent(component1);
  }

  CKComponentContextHelper::willBuildComponentTree(component1);

  // As there is a render component in the tree, o1 still need to stay in the store.
  XCTAssertEqualObjects(CKComponentContextHelper::fetchAll().objects, @{[NSObject class]: o1});

  {
    CKComponentContext<NSObject> context1(o2);
    // Make sure we get the latest value from the current store.
    XCTAssertEqualObjects(CKComponentContextHelper::fetchAll().objects, @{[NSObject class]: o2});
  }


  XCTAssertEqualObjects(CKComponentContextHelper::fetchAll().objects, @{[NSObject class]: o1});

  CKComponentContextHelper::didBuildComponentTree(component1);
  XCTAssertEqualObjects(CKComponentContextHelper::fetchAll().objects, nil);
}

@end

#pragma mark - Helpers

@implementation CKContextTestComponent

+ (instancetype)new
{
  id objectFromContext = CKComponentContext<NSNumber>::get();
  auto const c = [super new];
  if (c) {
    c->_objectFromContext = objectFromContext;
  }
  return c;
}
@end

@implementation CKContextTestRenderComponent
+ (instancetype)newWithContextObject:(NSNumber *)object
{
  // Read the existing value from context.
  NSNumber *objectFromContext = CKComponentContext<NSNumber>::get();
  
  // Override push new context with the same key
  CKComponentContext<NSNumber> context(object);
  auto const c = [super new];
  if (c) {
    c->_objectFromContext = objectFromContext;
  }
  return c;
}

- (CKComponent *)render:(id)state
{
  _child = [CKContextTestComponent new];
  return _child;
}
@end

@implementation CKContextTestWithChildrenComponent

+ (instancetype)newWithChildren:(std::vector<CKComponent *>)children
{
  auto const c = [super new];
  if (c) {
    c->_children = children;
  }
  return c;
}

- (std::vector<CKComponent *>)renderChildren:(id)state
{
  return _children;
}
@end
