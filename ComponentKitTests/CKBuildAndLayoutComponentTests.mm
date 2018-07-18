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

#import "CKRenderWithSizeSpecComponent.h"
#import "CKRenderComponent.h"
#import "CKBuildComponent.h"
#import "CKComponentInternal.h"
#import "CKComponentSubclass.h"
#import "CKRenderTreeNodeWithChildren.h"
#import "CKComponentScopeHandle.h"
#import "CKThreadLocalComponentScope.h"

#import <ComponentKit/CKComponentScopeRootFactory.h>

// Working RenderWithSizeSpecComponent
@interface TestRenderWithSizeSpecComponent : CKRenderWithSizeSpecComponent
+ (instancetype)newWithRenderCalled:(BOOL *)renderHasBeenCalled;
@end

@interface CKBuildAndLayoutComponentTests : XCTestCase

@end

@implementation CKBuildAndLayoutComponentTests

- (void)testRenderOnChild_NOT_Invoked_WhenNotUsingCKBuildAndLayout {
  __block BOOL renderOnChildCalled = NO;
  CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, ^ {
    return [TestRenderWithSizeSpecComponent newWithRenderCalled:&renderOnChildCalled];
  });
  XCTAssertFalse(renderOnChildCalled);
}

- (void)testRenderOnChild_Invoked_WhenUsingCKBuildAndLayout {
  __block BOOL renderOnChildCalled = NO;
  CKBuildAndLayoutComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, CKSizeRange({200, 200},{200, 200}), ^ {
    return [TestRenderWithSizeSpecComponent newWithRenderCalled:&renderOnChildCalled];
  }, {});
  XCTAssertTrue(renderOnChildCalled);
}
@end

@interface TestRenderChildComponent : CKRenderComponent
+ (TestRenderChildComponent *)newWithRenderCalled:(BOOL *)renderHasBeenCalled;
@end

@implementation TestRenderChildComponent{
  BOOL *_renderCalled;
}

+ (TestRenderChildComponent *)newWithRenderCalled:(BOOL *)renderHasBeenCalled{
  TestRenderChildComponent *const c = [super new];
  if (c) {
    c->_renderCalled = renderHasBeenCalled;
  }
  return c;
}

- (CKComponent *)render:(id)state {
  *_renderCalled = YES;
  return [CKComponent newWithView:{} size:{
    .width = 100,
    .height = 100,
  }];
}

@end

@implementation TestRenderWithSizeSpecComponent{
  BOOL *_functionCalled;
}

+ (TestRenderWithSizeSpecComponent *)newWithRenderCalled:(BOOL *)renderHasBeenCalled {
  TestRenderWithSizeSpecComponent *const c = [super newWithView:{} size:{
    .width = 100,
    .height = 100,
  }
                                              ];
  if (c) {
    c->_functionCalled = renderHasBeenCalled;
  }
  return c;
}

- (CKComponentLayout)render:(id)state constrainedSize:(CKSizeRange)constrainedSize restrictedToSize:(const CKComponentSize &)size relativeToParentSize:(CGSize)parentSize {
  CKComponent *c = [TestRenderChildComponent newWithRenderCalled:_functionCalled];
  CKComponentLayout cLayout = [self measureChild:c constrainedSize:constrainedSize relativeToParentSize:parentSize];
  return {
    self,
    cLayout.size,
    {
      {{0,0}, cLayout}
    }
  };
}

@end
