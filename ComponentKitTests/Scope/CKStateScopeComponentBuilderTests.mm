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

#import <ComponentKit/CKBuildComponent.h>
#import <ComponentKit/CKComponentController.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKCompositeComponent.h>
#import <ComponentKit/CKComponentScope.h>
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKComponentScopeRootFactory.h>
#import <ComponentKit/CKRootTreeNode.h>
#import <ComponentKit/CKThreadLocalComponentScope.h>

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
  CKComponentScopeRoot *root = CKComponentScopeRootWithDefaultPredicates(nil, nil);

  CKComponent *(^block)(void) = ^CKComponent *{
    XCTAssertEqualObjects(CKThreadLocalComponentScope::currentScope()->stack.top().previousFrame, root.rootNode.node());
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

  const CKBuildComponentResult result = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, block);
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

  const CKBuildComponentResult firstBuildResult = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, block);

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

  CKStateExposingComponent *component = (CKStateExposingComponent *)CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, block).component;
  XCTAssertEqualObjects(component.state, [CKStateExposingComponent initialState]);
}

- (void)testStatUniqueIdentifierIsNotFoundForComponentWhenClassNamesDoNotMatch
{
  id state = @12345;

  CKComponent *(^block)(void) = ^CKComponent *{
    CKComponentScope scope([CKCompositeComponent class], nil, ^{ return state; });
    CKComponent *c = [CKComponent new];
    (void)scope.state();
    return c;
  };

  CKComponent *component = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, block).component;
  XCTAssertNil(component.uniqueIdentifier);
}

- (void)testStateUniqueIdentifierIsNotFoundWhenAnotherComponentInTheSameScopeAcquiresItFirst
{
  CKComponent __block *innerComponent = nil;

  id state = @12345;

  CKComponent *(^block)(void) = ^CKComponent *{
    CKComponentScope scope([CKComponent class], nil, ^{ return state; });

    (void)scope.state();
    innerComponent = [CKComponent new];

    return [CKComponent new];
  };

  CKComponent *outerComponent = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, block).component;
  XCTAssertNotNil(innerComponent.uniqueIdentifier);
  XCTAssertNil(outerComponent.uniqueIdentifier);
}

@end
