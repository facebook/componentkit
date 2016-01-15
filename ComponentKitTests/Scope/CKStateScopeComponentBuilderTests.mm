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

#import <OCMock/OCMock.h>

#import "CKComponentController.h"
#import "CKComponentSubclass.h"
#import "CKCompositeComponent.h"

#import "CKComponentScope.h"
#import "CKComponentInternal.h"
#import "CKComponentScopeFrame.h"
#import "CKComponentScopeRoot.h"
#import "CKThreadLocalComponentScope.h"
#import "CKStateExposingComponent.h"

#pragma mark - Test Components and Controllers

@interface CKMonkeyComponent : CKComponent
@end

@implementation CKMonkeyComponent
@end

@interface CKMonkeyComponentController : CKComponentController
@end

@implementation CKMonkeyComponentController
@end

@interface CKMonkeyComponentWithAnimations : CKComponent
@end

@implementation CKMonkeyComponentWithAnimations
- (std::vector<CKComponentAnimation>)animationsFromPreviousComponent:(CKComponent *)previousComponent { return {}; }
- (std::vector<CKComponentAnimation>)animationsOnInitialMount { return {}; }
@end

#pragma mark - Tests

@interface CKStateScopeComponentBuilderTests : XCTestCase
@end

@implementation CKStateScopeComponentBuilderTests

#pragma mark - CKBuildComponent

- (void)testThreadLocalStateIsSet
{
  CKComponentScopeRoot *root = [CKComponentScopeRoot rootWithListener:nil];

  CKComponent *(^block)(void) = ^CKComponent *{
    XCTAssertEqualObjects(CKThreadLocalComponentScope::currentScope()->stack.top().equivalentPreviousFrame, root.rootFrame);
    return [CKComponent new];
  };

  (void)CKBuildComponent(root, {}, block);
}

- (void)testCorrectComponentIsReturned
{
  CKComponent __block *c = nil;
  CKComponent *(^block)(void) = ^CKComponent *{
    c = [CKComponent new];
    return c;
  };

  const CKBuildComponentResult result = CKBuildComponent([CKComponentScopeRoot rootWithListener:nil], {}, block);
  XCTAssertEqualObjects(result.component, c);
}

- (void)testStateIsReacquiredAndNewInitialValueBlockIsNotUsed
{
  id state = @12345;

  CKComponent *(^block)(void) = ^CKComponent *{
    CKComponentScope scope([CKComponent class], nil, ^{ return state; });
    (void)scope.state();
    return [CKComponent new];
  };

  const CKBuildComponentResult firstBuildResult = CKBuildComponent([CKComponentScopeRoot rootWithListener:nil], {}, block);

  id __block nextState = nil;
  CKComponent *(^block2)(void) = ^CKComponent *{
    CKComponentScope scope([CKComponent class], nil, ^{ return @67890; });
    nextState = scope.state();
    return [CKComponent new];
  };

  (void)CKBuildComponent(firstBuildResult.scopeRoot, {}, block2);

  XCTAssertEqualObjects(state, nextState);
}

#pragma mark - CKComponentScopeFrameForComponent

- (void)testComponentStateIsSetToInitialStateValue
{
  CKComponent *(^block)(void) = ^CKComponent *{
    return [CKStateExposingComponent new];
  };

  CKStateExposingComponent *component = (CKStateExposingComponent *)CKBuildComponent([CKComponentScopeRoot rootWithListener:nil], {}, block).component;
  XCTAssertEqualObjects(component.state, [CKStateExposingComponent initialState]);
}

- (void)testStateScopeFrameIsNotFoundForComponentWhenClassNamesDoNotMatch
{
  id state = @12345;

  CKComponent *(^block)(void) = ^CKComponent *{
    CKComponentScope scope([CKCompositeComponent class], nil, ^{ return state; });
    CKComponent *c = [CKComponent new];
    (void)scope.state();
    return c;
  };

  CKComponent *component = CKBuildComponent([CKComponentScopeRoot rootWithListener:nil], {}, block).component;
  XCTAssertNil(component.scopeFrameToken);
}

- (void)testStateScopeFrameIsNotFoundWhenAnotherComponentInTheSameScopeAcquiresItFirst
{
  CKComponent __block *innerComponent = nil;

  id state = @12345;

  CKComponent *(^block)(void) = ^CKComponent *{
    CKComponentScope scope([CKComponent class], nil, ^{ return state; });

    (void)scope.state();
    innerComponent = [CKComponent new];

    return [CKComponent new];
  };

  CKComponent *outerComponent = CKBuildComponent([CKComponentScopeRoot rootWithListener:nil], {}, block).component;
  XCTAssertNotNil(innerComponent.scopeFrameToken);
  XCTAssertNil(outerComponent.scopeFrameToken);
}

@end
