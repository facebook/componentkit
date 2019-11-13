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
#import <ComponentKit/CKCompositeComponent.h>
#import <ComponentKit/CKFlexboxComponent.h>
#import <ComponentKitTestHelpers/CKTestRunLoopRunning.h>

@interface CKComponentLayoutTestComponentController : CKComponentController
@end

@interface CKComponentLayoutTestComponent : CKComponent
@end
@implementation CKComponentLayoutTestComponent
+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view
                       size:(const CKComponentSize &)size
{
  // Just a hack for the test as we don't really care about this scope id in this case.
  static int counter = 0;
  CKComponentScope scope (self, @(counter++));
  return [super newWithView:view size:size];
}
+ (Class<CKComponentControllerProtocol>)controllerClass
{
  return [CKComponentLayoutTestComponentController class];
}
@end

@implementation CKComponentLayoutTestComponentController
@end

@interface CKComponentLayoutTests : XCTestCase

@end

@implementation CKComponentLayoutTests

- (void)testComputeRootLayout_WithCache_NoScope
{
  __block NSArray<CKComponent *> *children;
  __block CKFlexboxComponent *c;
  CKBuildComponentResult results = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, ^{
    children = createChildrenArray(NO);
    c = flexboxComponentWithScopedChildren(children);
    return c;
  });

  const auto layout = CKComputeRootComponentLayout(c, {{200, 0}, {200, INFINITY}}, nil);

  // Make sure the cache contains all the components that have component controller.
  for (id child in children) {
    const CKComponentLayout cacheLayout = layout.cachedLayoutForComponent(child);
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

  const auto layout = CKComputeRootComponentLayout(c, {{200, 0}, {200, INFINITY}}, nil);

  // Make sure the cache contains all the components that have component controller.
  for (id child in children) {
    const CKComponentLayout cacheLayout = layout.cachedLayoutForComponent(child);
    XCTAssertTrue(cacheLayout.component == child);
  }
}

#pragma mark - Helpers

static CKFlexboxComponent* flexboxComponentWithScopedChildren(NSArray<CKComponent *> *children) {

  CKFlexboxComponent *c = CK::FlexboxComponentBuilder()
                              .alignItems(CKFlexboxAlignItemsStart)
                              .children(CK::map(children, [](CKComponent *child) -> CKFlexboxComponentChild { return {child}; }))
                              .build();
  return c;
}

static NSArray<CKComponent *>* createChildrenArray(BOOL scoped) {
  NSMutableArray<CKComponent *> *components = [NSMutableArray array];
  for (NSUInteger i=0; i<5; i++) {
    if (scoped) {
      [components addObject:[CKComponentLayoutTestComponent newWithView:{} size:{}]];
    } else {
      [components addObject:CK::ComponentBuilder()
                                .build()];
    }
  }
  return components;
}

@end
