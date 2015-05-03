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

#import <ComponentKit/CKComponentController.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKCompositeComponent.h>

#import "CKComponentInternal.h"
#import "CKComponentScopeFrame.h"
#import "CKComponentScopeInternal.h"
#import "CKThreadLocalComponentScope.h"

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
@end

@interface CKStateExposingComponent : CKComponent
@property (nonatomic, strong, readonly) id state;
@end

@implementation CKStateExposingComponent
+ (id)initialState
{
  return @12345;
}
+ (instancetype)new
{
  CKComponentScope scope(self);
  CKStateExposingComponent *c = [super newWithView:{} size:{}];
  if (c) {
    c->_state = scope.state();
  }
  return c;
}
@end

#pragma mark - Tests

@interface CKStateScopeComponentBuilderTests : XCTestCase
@end

@implementation CKStateScopeComponentBuilderTests

#pragma mark - CKBuildComponent

- (void)testThreadLocalStateIsSet
{
  CKComponentScopeFrame *frame = [CKComponentScopeFrame rootFrameWithListener:nil globalIdentifier:0];

  CKComponent *(^block)(void) = ^CKComponent *{
    XCTAssertEqualObjects(CKThreadLocalComponentScope::cursor()->equivalentPreviousFrame(), frame);
    return [CKComponent new];
  };

  (void)CKBuildComponent(nil, frame, block);
}

- (void)testThreadLocalStateIsUnset
{
  CKComponentScopeFrame *frame = nil;

  CKComponent *(^block)(void) = ^CKComponent *{
    return [CKComponent new];
  };

  (void)CKBuildComponent(nil, frame, block);

  XCTAssertTrue(CKThreadLocalComponentScope::cursor()->empty());
}

- (void)testCorrectComponentIsReturned
{
  CKComponentScopeFrame *frame = nil;

  CKComponent __block *c = nil;
  CKComponent *(^block)(void) = ^CKComponent *{
    c = [CKComponent new];
    return c;
  };

  const CKBuildComponentResult result = CKBuildComponent(nil, frame, block);
  XCTAssertEqualObjects(result.component, c);
}

- (void)testResultingFrameContainsCorrectState
{
  CKComponentScopeFrame *frame = nil;

  id state = @12345;

  CKComponent *(^block)(void) = ^CKComponent *{
    CKComponentScope scope([CKComponent class], nil, ^{ return state; });
    (void)scope.state();
    return [CKComponent new];
  };

  const CKBuildComponentResult result = CKBuildComponent(nil, frame, block);
  XCTAssertEqualObjects([result.scopeFrame existingChildFrameWithClass:[CKComponent class] identifier:nil].state, state);
}

- (void)testStateIsReacquiredAndNewInitialValueBlockIsNotUsed
{
  CKComponentScopeFrame *frame = nil;

  id state = @12345;

  CKComponent *(^block)(void) = ^CKComponent *{
    CKComponentScope scope([CKComponent class], nil, ^{ return state; });
    (void)scope.state();
    return [CKComponent new];
  };

  const CKBuildComponentResult firstBuildResult = CKBuildComponent(nil, frame, block);

  id __block nextState = nil;
  CKComponent *(^block2)(void) = ^CKComponent *{
    CKComponentScope scope([CKComponent class], nil, ^{ return @67890; });
    nextState = scope.state();
    return [CKComponent new];
  };

  (void)CKBuildComponent(nil, firstBuildResult.scopeFrame, block2);

  XCTAssertEqualObjects(state, nextState);
}

#pragma mark - CKComponentScopeFrameForComponent

- (void)testComponentStateIsSetToInitialStateValue
{
  CKComponentScopeFrame *frame = nil;

  CKComponent *(^block)(void) = ^CKComponent *{
    return [CKStateExposingComponent new];
  };

  CKStateExposingComponent *component = (CKStateExposingComponent *)CKBuildComponent(nil, frame, block).component;
  XCTAssertEqualObjects(component.state, [CKStateExposingComponent initialState]);
}

- (void)testStateScopeFrameIsNotFoundForComponentWhenClassNamesDoNotMatch
{
  CKComponentScopeFrame *frame = nil;

  id state = @12345;

  CKComponent *(^block)(void) = ^CKComponent *{
    CKComponentScope scope([CKCompositeComponent class], nil, ^{ return state; });
    CKComponent *c = [CKComponent new];
    (void)scope.state();
    return c;
  };

  CKComponent *component = CKBuildComponent(nil, frame, block).component;
  XCTAssertNil(component.scopeFrameToken);
}

- (void)testStateScopeFrameIsNotFoundWhenAnotherComponentInTheSameScopeAcquiresItFirst
{
  CKComponentScopeFrame *frame = nil;

  CKComponent __block *innerComponent = nil;

  id state = @12345;

  CKComponent *(^block)(void) = ^CKComponent *{
    CKComponentScope scope([CKComponent class], nil, ^{ return state; });

    (void)scope.state();
    innerComponent = [CKComponent new];

    return [CKComponent new];
  };

  CKComponent *outerComponent = CKBuildComponent(nil, frame, block).component;
  XCTAssertNotNil(innerComponent.scopeFrameToken);
  XCTAssertNil(outerComponent.scopeFrameToken);
}

#pragma mark - Controller Construction

- (void)testComponentWithControllerThrowsIfNoScopeExistsForTheComponent
{
  CKComponent *(^block)(void) = ^CKComponent *{
    return [CKMonkeyComponent new];
  };

  CKComponentScopeFrame *frame = nil;
  XCTAssertThrows((void)CKBuildComponent(nil, frame, block));
}

- (void)testComponentWithControllerDoesNotThrowIfScopeExistsForTheComponent
{
  CKComponent *(^block)(void) = ^CKComponent *{
    CKComponentScope scope([CKMonkeyComponent class]);
    return [CKMonkeyComponent new];
  };

  CKComponentScopeFrame *frame = nil;
  XCTAssertNoThrow((void)CKBuildComponent(nil, frame, block));
}

- (void)testComponentWithControllerThatHasAnimationsThrowsIfNoScopeExistsForTheComponent
{
  CKComponent *(^block)(void) = ^CKComponent *{
    return [CKMonkeyComponentWithAnimations new];
  };

  CKComponentScopeFrame *frame = nil;
  XCTAssertThrows((void)CKBuildComponent(nil, frame, block));
}

- (void)testComponentWithControllerThatHasAnimationsDoesNotThrowIfScopeExistsForTheComponent
{
  CKComponent *(^block)(void) = ^CKComponent *{
    CKComponentScope scope([CKMonkeyComponentWithAnimations class]);
    return [CKMonkeyComponentWithAnimations new];
  };

  CKComponentScopeFrame *frame = nil;
  XCTAssertNoThrow((void)CKBuildComponent(nil, frame, block));
}

@end
