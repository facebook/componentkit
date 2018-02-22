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
#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKComponentScopeRootFactory.h>
#import <ComponentKit/CKComponentController.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKFlexboxComponent.h>
#import <ComponentKitTestHelpers/CKTestRunLoopRunning.h>

@interface CKComponentLayoutTestComponent : CKComponent
@end
@implementation CKComponentLayoutTestComponent
+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view size:(const CKComponentSize &)size
{
  // Just a hack for the test as we don't really care about this scope id in this case.
  static int counter = 0;
  CKComponentScope scope (self, @(counter++));
  return [super newWithView:view size:size];
}
@end

@interface CKComponentLayoutTestComponentController : CKComponentController
@end
@implementation CKComponentLayoutTestComponentController
@end

@interface CKComponentLayoutTests : XCTestCase

@end

@implementation CKComponentLayoutTests

- (void)testComputeRootLayout_NoCache_NoScope
{
  __block NSArray<CKComponent *> *children;
  __block CKFlexboxComponent *c;
  CKBuildComponentResult results = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, ^{
    children = createChildrenArray(NO);
    c = flexboxComponentWithScopedChildren(children);
    return c;
  });

  const CKComponentLayout layout = CKComputeRootComponentLayout(c, {{200, 0}, {200, INFINITY}});

  // Make sure we don't build any cache unless we explicty pass in the `buildComponentLayoutCache` parameter.
  XCTAssertNil(layout.extra);
}

- (void)testComputeRootLayout_NoCache_WithScope
{
  __block NSArray<CKComponent *> *children;
  __block CKFlexboxComponent *c;

  CKBuildComponentResult results = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, ^{
    children = createChildrenArray(YES);
    c = flexboxComponentWithScopedChildren(children);
    return c;
  });

  const CKComponentLayout layout = CKComputeRootComponentLayout(c, {{200, 0}, {200, INFINITY}});

  // Make sure we don't build any cache unless we explicty pass in the `buildComponentLayoutCache` parameter.
  XCTAssertNil(layout.extra);
}

- (void)testComputeRootLayout_WithCache_NoScope
{
  __block NSArray<CKComponent *> *children;
  __block CKFlexboxComponent *c;
  CKBuildComponentResult results = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, ^{
    children = createChildrenArray(NO);
    return flexboxComponentWithScopedChildren(children);
    return c;
  });

  const CKComponentLayout layout = CKComputeRootComponentLayout(c, {{200, 0}, {200, INFINITY}}, nil, YES);

  // Make sure we do build the components cache in case that `buildComponentLayoutCache` is set to `YES`.
  XCTAssertNotNil(layout.extra);

  // Make sure the cache contains all the components that have component controller.
  for (id child in children) {
    const CKComponentLayout cacheLayout = layout.cachedLayoutForScopedComponent(child);
    XCTAssertTrue(cacheLayout.component == nil);
  }
}

- (void)testComputeRootLayout_WithCache_WithScope
{
  __block NSArray<CKComponent *> *children;
  __block CKFlexboxComponent *c;
  CKBuildComponentResult results = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, ^{
    children = createChildrenArray(YES);
    c = flexboxComponentWithScopedChildren(children);
    return c;
  });
  
  const CKComponentLayout layout = CKComputeRootComponentLayout(c, {{200, 0}, {200, INFINITY}}, nil, YES);

  // Make sure we do build the components cache in case that `buildComponentLayoutCache` is set to `YES`.
  XCTAssertNotNil(layout.extra);

  // Make sure the cache contains all the components that have component controller.
  for (id child in children) {
    const CKComponentLayout cacheLayout = layout.cachedLayoutForScopedComponent(child);
    XCTAssertTrue(cacheLayout.component == child);
  }
}

- (void)testWhenLayoutIsBeingDeallocated_LayoutCacheIsBeingDeallocatedToo
{
  NSPointerArray *weakChildren = [NSPointerArray weakObjectsPointerArray];

  @autoreleasepool {
    __block NSArray<CKComponent *> *children;
    __block CKFlexboxComponent *c;

    CKBuildComponentResult results = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, ^{
      children = createChildrenArray(YES);
      c = flexboxComponentWithScopedChildren(children);
      return c;
    });

    const CKComponentLayout layout = CKComputeRootComponentLayout(c, {{200, 0}, {200, INFINITY}}, nil, YES);

    for (CKComponent *child in children) {
      [weakChildren addPointer:(void *)child];
    }
  }

  // Make sure all the children have been released.
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL{
    NSUInteger weakChildrenCounter = 0;
    for (id child in weakChildren) {
      if (child) {
        weakChildrenCounter++;
      }
    }
    return weakChildrenCounter == 0;
  }));
}

#pragma mark - Helpers

static CKFlexboxComponent* flexboxComponentWithScopedChildren(NSArray<CKComponent *> *children) {

  CKFlexboxComponent *c = [CKFlexboxComponent newWithView:{} size:{} style:{}
                                                 children:CK::map(children, [](CKComponent *child) -> CKFlexboxComponentChild { return {child}; })];
  return c;
}

static NSArray<CKComponent *>* createChildrenArray(BOOL scoped) {
  Class componentClass = scoped ? [CKComponentLayoutTestComponent class] : [CKComponent class];
  return @[
    [componentClass newWithView:{} size:{}],
    [componentClass newWithView:{} size:{}],
    [componentClass newWithView:{} size:{}],
    [componentClass newWithView:{} size:{}],
    [componentClass newWithView:{} size:{}],
  ];
}

@end
