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

#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKCompositeComponent.h>
#import <ComponentKit/CKComponentScope.h>
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKComponentScopeFrame.h>
#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKDetectComponentScopeCollisions.h>

#pragma mark - Test Components

@interface CKOneComponent : CKComponent
@end

@implementation CKOneComponent
@end

@interface CKTwoComponent : CKComponent
@end

@implementation CKTwoComponent
@end

@interface CKThreeComponent : CKComponent
@end

@implementation CKThreeComponent
@end

@interface CKFourComponent : CKComponent
@end

@implementation CKFourComponent
@end

@interface CKFiveComponent : CKComponent
@end

@implementation CKFiveComponent
@end

@interface CKSixComponent : CKComponent
@end

@implementation CKSixComponent
@end

@interface CKSevenComponent : CKComponent
@end

@implementation CKSevenComponent
@end

@interface CKEightComponent : CKComponent
@end

@implementation CKEightComponent
@end

@interface CKNineComponent : CKComponent
@end

@implementation CKNineComponent
@end

@interface CKTenComponent : CKComponent
@end

@implementation CKTenComponent
@end

@interface CKElevenComponent : CKComponent
@end

@implementation CKElevenComponent
@end

@interface CKTwelveComponent : CKComponent
@end

@implementation CKTwelveComponent
@end

@interface CKThirteenComponent : CKComponent
@end

@implementation CKThirteenComponent
@end

#pragma mark - Tests

@interface CKDetectComponentScopeCollisionsTests : XCTestCase

@end

/* This is the tree we're going to generate for the tests.
 *
 *   _____1______
 *  /     |      \
 *  2 ____3____  4
 *   /    |    \
 *   5  __6   __7__
 *  /   |    /     \
 *  8   9    10    11
 *          /  \
 *         12  13
 */

@implementation CKDetectComponentScopeCollisionsTests

- (void)testNoCollisionsFound
{
  id componentMock1 = [OCMockObject mockForClass:[CKOneComponent class]];
  [[[componentMock1 stub] andReturn:@1] scopeFrameToken];

  id componentMock2 = [OCMockObject mockForClass:[CKTwoComponent class]];
  [[[componentMock2 stub] andReturn:@2] scopeFrameToken];

  id componentMock3 = [OCMockObject mockForClass:[CKThreeComponent class]];
  [[[componentMock3 stub] andReturn:@3] scopeFrameToken];

  id componentMock4 = [OCMockObject mockForClass:[CKFourComponent class]];
  [[[componentMock4 stub] andReturn:@4] scopeFrameToken];

  id componentMock5 = [OCMockObject mockForClass:[CKFiveComponent class]];
  [[[componentMock5 stub] andReturn:@5] scopeFrameToken];

  id componentMock6 = [OCMockObject mockForClass:[CKSixComponent class]];
  [[[componentMock6 stub] andReturn:@6] scopeFrameToken];

  id componentMock7 = [OCMockObject mockForClass:[CKSevenComponent class]];
  [[[componentMock7 stub] andReturn:@7] scopeFrameToken];

  id componentMock8 = [OCMockObject mockForClass:[CKEightComponent class]];
  [[[componentMock8 stub] andReturn:@8] scopeFrameToken];

  id componentMock9 = [OCMockObject mockForClass:[CKNineComponent class]];
  [[[componentMock9 stub] andReturn:@9] scopeFrameToken];

  id componentMock10 = [OCMockObject mockForClass:[CKTenComponent class]];
  [[[componentMock10 stub] andReturn:@10] scopeFrameToken];

  id componentMock11 = [OCMockObject mockForClass:[CKElevenComponent class]];
  [[[componentMock11 stub] andReturn:@11] scopeFrameToken];

  id componentMock12 = [OCMockObject mockForClass:[CKTwelveComponent class]];
  [[[componentMock12 stub] andReturn:@12] scopeFrameToken];

  id componentMock13 = [OCMockObject mockForClass:[CKThirteenComponent class]];
  [[[componentMock13 stub] andReturn:@13] scopeFrameToken];

  CKComponentLayout x13 = CKComponentLayout(componentMock13, CGSizeZero, {}, nil);
  CKComponentLayout x12 = CKComponentLayout(componentMock12, CGSizeZero, {}, nil);
  
  std::vector<CKComponentLayoutChild> childrenOf10 = { {{0,0}, x12}, {{0,0}, x13}};
  CKComponentLayout x10 = CKComponentLayout(componentMock10, CGSizeZero, childrenOf10, nil);
  
  CKComponentLayout x11 = CKComponentLayout(componentMock11, CGSizeZero, {}, nil);
  std::vector<CKComponentLayoutChild> childrenOf7 = { {{0,0}, x10}, {{0,0}, x11}};
  CKComponentLayout x7 = CKComponentLayout(componentMock7, CGSizeZero, childrenOf7, nil);
  
  CKComponentLayout x8 = CKComponentLayout(componentMock8, CGSizeZero, {}, nil);
  CKComponentLayout x9 = CKComponentLayout(componentMock9, CGSizeZero, {}, nil);
  
  std::vector<CKComponentLayoutChild> childrenOf6 = { {{0,0}, x8}, {{0,0}, x9}};
  CKComponentLayout x6 = CKComponentLayout(componentMock6, CGSizeZero, childrenOf6, nil);
  
  CKComponentLayout x5 = CKComponentLayout(componentMock5, CGSizeZero, {}, nil);
  
  std::vector<CKComponentLayoutChild> childrenOf3 = { {{0,0}, x5}, {{0,0}, x6}, {{0,0}, x7}};
  CKComponentLayout x3 = CKComponentLayout(componentMock3, CGSizeZero, childrenOf3, nil);
  
  CKComponentLayout x2 = CKComponentLayout(componentMock2, CGSizeZero, {}, nil);
  CKComponentLayout x4 = CKComponentLayout(componentMock4, CGSizeZero, {}, nil);
  
  std::vector<CKComponentLayoutChild> childrenOf1 = { {{0,0}, x2}, {{0,0}, x3}, {{0,0}, x4}};
  CKComponentLayout x1 = CKComponentLayout(componentMock1, CGSizeZero, childrenOf1, nil);
  
  const CKComponentCollision collision = CKFindComponentScopeCollision(x1);
  
  XCTAssertFalse(collision.hasCollision());
}

- (void)testCollisionDetected
{
  id componentMock1 = [OCMockObject mockForClass:[CKOneComponent class]];
  [[[componentMock1 stub] andReturn:@1] scopeFrameToken];

  id componentMock2 = [OCMockObject mockForClass:[CKTwoComponent class]];
  [[[componentMock2 stub] andReturn:@2] scopeFrameToken];

  id componentMock3 = [OCMockObject mockForClass:[CKThreeComponent class]];
  [[[componentMock3 stub] andReturn:@3] scopeFrameToken];

  id componentMock4 = [OCMockObject mockForClass:[CKFourComponent class]];
  [[[componentMock4 stub] andReturn:@4] scopeFrameToken];

  id componentMock5 = [OCMockObject mockForClass:[CKFiveComponent class]];
  [[[componentMock5 stub] andReturn:@5] scopeFrameToken];

  id componentMock6 = [OCMockObject mockForClass:[CKSixComponent class]];
  [[[componentMock6 stub] andReturn:@6] scopeFrameToken];

  id componentMock7 = [OCMockObject mockForClass:[CKSevenComponent class]];
  [[[componentMock7 stub] andReturn:@7] scopeFrameToken];

  id componentMock8 = [OCMockObject mockForClass:[CKEightComponent class]];
  [[[componentMock8 stub] andReturn:@8] scopeFrameToken];

  // We set the scopeToken to 30 for a collision
  id componentMock9 = [OCMockObject mockForClass:[CKNineComponent class]];
  [[[componentMock9 stub] andReturn:@30] scopeFrameToken];

  id componentMock10 = [OCMockObject mockForClass:[CKTenComponent class]];
  [[[componentMock10 stub] andReturn:@10] scopeFrameToken];

  id componentMock11 = [OCMockObject mockForClass:[CKElevenComponent class]];
  [[[componentMock11 stub] andReturn:@11] scopeFrameToken];

  // We set the scopeToken to 30 for a collision
  id componentMock12 = [OCMockObject mockForClass:[CKTwelveComponent class]];
  [[[componentMock12 stub] andReturn:@30] scopeFrameToken];

  id componentMock13 = [OCMockObject mockForClass:[CKThirteenComponent class]];
  [[[componentMock13 stub] andReturn:@13] scopeFrameToken];

  CKComponentLayout x13 = CKComponentLayout(componentMock13, CGSizeZero, {}, nil);
  CKComponentLayout x12 = CKComponentLayout(componentMock12, CGSizeZero, {}, nil);
  
  std::vector<CKComponentLayoutChild> childrenOf10 = { {{0,0}, x12}, {{0,0}, x13}};
  CKComponentLayout x10 = CKComponentLayout(componentMock10, CGSizeZero, childrenOf10, nil);
  
  CKComponentLayout x11 = CKComponentLayout(componentMock11, CGSizeZero, {}, nil);
  std::vector<CKComponentLayoutChild> childrenOf7 = { {{0,0}, x10}, {{0,0}, x11}};
  CKComponentLayout x7 = CKComponentLayout(componentMock7, CGSizeZero, childrenOf7, nil);
  
  CKComponentLayout x8 = CKComponentLayout(componentMock8, CGSizeZero, {}, nil);
  CKComponentLayout x9 = CKComponentLayout(componentMock9, CGSizeZero, {}, nil);
  
  std::vector<CKComponentLayoutChild> childrenOf6 = { {{0,0}, x8}, {{0,0}, x9}};
  CKComponentLayout x6 = CKComponentLayout(componentMock6, CGSizeZero, childrenOf6, nil);
  
  CKComponentLayout x5 = CKComponentLayout(componentMock5, CGSizeZero, {}, nil);
  
  std::vector<CKComponentLayoutChild> childrenOf3 = { {{0,0}, x5}, {{0,0}, x6}, {{0,0}, x7}};
  CKComponentLayout x3 = CKComponentLayout(componentMock3, CGSizeZero, childrenOf3, nil);
  
  CKComponentLayout x2 = CKComponentLayout(componentMock2, CGSizeZero, {}, nil);
  CKComponentLayout x4 = CKComponentLayout(componentMock4, CGSizeZero, {}, nil);
  
  std::vector<CKComponentLayoutChild> childrenOf1 = { {{0,0}, x2}, {{0,0}, x3}, {{0,0}, x4}};
  CKComponentLayout x1 = CKComponentLayout(componentMock1, CGSizeZero, childrenOf1, nil);
  
  const CKComponentCollision collision = CKFindComponentScopeCollision(x1);
  
  // Component Twelve and Nine should collide
  XCTAssertTrue(collision.hasCollision());
  XCTAssertNotNil(collision.component);
  XCTAssertTrue([collision.component isKindOfClass:[CKTwelveComponent class]] ||
                [collision.component isKindOfClass:[CKNineComponent class]]);

  // The lowest common ancestor of the two should be Three
  XCTAssertTrue([collision.lowestCommonAncestor isKindOfClass:[CKThreeComponent class]]);
}

- (void)testCollisionIsRootElement
{
  // We set the scopeToken to 30 for a collision
  id componentMock1 = [OCMockObject mockForClass:[CKOneComponent class]];
  [[[componentMock1 stub] andReturn:@30] scopeFrameToken];

  id componentMock2 = [OCMockObject mockForClass:[CKTwoComponent class]];
  [[[componentMock2 stub] andReturn:@2] scopeFrameToken];

  id componentMock3 = [OCMockObject mockForClass:[CKThreeComponent class]];
  [[[componentMock3 stub] andReturn:@3] scopeFrameToken];

  id componentMock4 = [OCMockObject mockForClass:[CKFourComponent class]];
  [[[componentMock4 stub] andReturn:@4] scopeFrameToken];

  id componentMock5 = [OCMockObject mockForClass:[CKFiveComponent class]];
  [[[componentMock5 stub] andReturn:@5] scopeFrameToken];

  id componentMock6 = [OCMockObject mockForClass:[CKSixComponent class]];
  [[[componentMock6 stub] andReturn:@6] scopeFrameToken];

  id componentMock7 = [OCMockObject mockForClass:[CKSevenComponent class]];
  [[[componentMock7 stub] andReturn:@7] scopeFrameToken];

  id componentMock8 = [OCMockObject mockForClass:[CKEightComponent class]];
  [[[componentMock8 stub] andReturn:@8] scopeFrameToken];

  id componentMock9 = [OCMockObject mockForClass:[CKNineComponent class]];
  [[[componentMock9 stub] andReturn:@9] scopeFrameToken];

  id componentMock10 = [OCMockObject mockForClass:[CKTenComponent class]];
  [[[componentMock10 stub] andReturn:@10] scopeFrameToken];

  id componentMock11 = [OCMockObject mockForClass:[CKElevenComponent class]];
  [[[componentMock11 stub] andReturn:@11] scopeFrameToken];

  // We set the scopeToken to 30 for a collision
  id componentMock12 = [OCMockObject mockForClass:[CKTwelveComponent class]];
  [[[componentMock12 stub] andReturn:@30] scopeFrameToken];

  id componentMock13 = [OCMockObject mockForClass:[CKThirteenComponent class]];
  [[[componentMock13 stub] andReturn:@13] scopeFrameToken];

  CKComponentLayout x13 = CKComponentLayout(componentMock13, CGSizeZero, {}, nil);
  CKComponentLayout x12 = CKComponentLayout(componentMock12, CGSizeZero, {}, nil);
  
  std::vector<CKComponentLayoutChild> childrenOf10 = { {{0,0}, x12}, {{0,0}, x13}};
  CKComponentLayout x10 = CKComponentLayout(componentMock10, CGSizeZero, childrenOf10, nil);
  
  CKComponentLayout x11 = CKComponentLayout(componentMock11, CGSizeZero, {}, nil);
  std::vector<CKComponentLayoutChild> childrenOf7 = { {{0,0}, x10}, {{0,0}, x11}};
  CKComponentLayout x7 = CKComponentLayout(componentMock7, CGSizeZero, childrenOf7, nil);
  
  CKComponentLayout x8 = CKComponentLayout(componentMock8, CGSizeZero, {}, nil);
  CKComponentLayout x9 = CKComponentLayout(componentMock9, CGSizeZero, {}, nil);
  
  std::vector<CKComponentLayoutChild> childrenOf6 = { {{0,0}, x8}, {{0,0}, x9}};
  CKComponentLayout x6 = CKComponentLayout(componentMock6, CGSizeZero, childrenOf6, nil);
  
  CKComponentLayout x5 = CKComponentLayout(componentMock5, CGSizeZero, {}, nil);
  
  std::vector<CKComponentLayoutChild> childrenOf3 = { {{0,0}, x5}, {{0,0}, x6}, {{0,0}, x7}};
  CKComponentLayout x3 = CKComponentLayout(componentMock3, CGSizeZero, childrenOf3, nil);
  
  CKComponentLayout x2 = CKComponentLayout(componentMock2, CGSizeZero, {}, nil);
  CKComponentLayout x4 = CKComponentLayout(componentMock4, CGSizeZero, {}, nil);
  
  std::vector<CKComponentLayoutChild> childrenOf1 = { {{0,0}, x2}, {{0,0}, x3}, {{0,0}, x4}};
  CKComponentLayout x1 = CKComponentLayout(componentMock1, CGSizeZero, childrenOf1, nil);
  
  const CKComponentCollision collision = CKFindComponentScopeCollision(x1);
  
  // Component Twelve and One should collide
  XCTAssertTrue(collision.hasCollision());
  XCTAssertNotNil(collision.component);
  XCTAssertTrue([collision.component isKindOfClass:[CKTwelveComponent class]] ||
                [collision.component isKindOfClass:[CKOneComponent class]]);
  
  // Since Component One is the Root node, it doesn't have any common ancestor, so it should be nil.
  XCTAssertNil(collision.lowestCommonAncestor);
}

- (void)testCollisionIsDirectParent
{
  id componentMock1 = [OCMockObject mockForClass:[CKOneComponent class]];
  [[[componentMock1 stub] andReturn:@1] scopeFrameToken];

  id componentMock2 = [OCMockObject mockForClass:[CKTwoComponent class]];
  [[[componentMock2 stub] andReturn:@2] scopeFrameToken];

  id componentMock3 = [OCMockObject mockForClass:[CKThreeComponent class]];
  [[[componentMock3 stub] andReturn:@3] scopeFrameToken];

  id componentMock4 = [OCMockObject mockForClass:[CKFourComponent class]];
  [[[componentMock4 stub] andReturn:@4] scopeFrameToken];

  id componentMock5 = [OCMockObject mockForClass:[CKFiveComponent class]];
  [[[componentMock5 stub] andReturn:@5] scopeFrameToken];

  id componentMock6 = [OCMockObject mockForClass:[CKSixComponent class]];
  [[[componentMock6 stub] andReturn:@6] scopeFrameToken];

  id componentMock7 = [OCMockObject mockForClass:[CKSevenComponent class]];
  [[[componentMock7 stub] andReturn:@7] scopeFrameToken];

  id componentMock8 = [OCMockObject mockForClass:[CKEightComponent class]];
  [[[componentMock8 stub] andReturn:@8] scopeFrameToken];

  id componentMock9 = [OCMockObject mockForClass:[CKNineComponent class]];
  [[[componentMock9 stub] andReturn:@9] scopeFrameToken];

  // We set the scopeToken to 30 for a collision
  id componentMock10 = [OCMockObject mockForClass:[CKTenComponent class]];
  [[[componentMock10 stub] andReturn:@30] scopeFrameToken];

  id componentMock11 = [OCMockObject mockForClass:[CKElevenComponent class]];
  [[[componentMock11 stub] andReturn:@11] scopeFrameToken];

  // We set the scopeToken to 30 for a collision
  id componentMock12 = [OCMockObject mockForClass:[CKTwelveComponent class]];
  [[[componentMock12 stub] andReturn:@30] scopeFrameToken];

  id componentMock13 = [OCMockObject mockForClass:[CKThirteenComponent class]];
  [[[componentMock13 stub] andReturn:@13] scopeFrameToken];

  CKComponentLayout x13 = CKComponentLayout(componentMock13, CGSizeZero, {}, nil);
  CKComponentLayout x12 = CKComponentLayout(componentMock12, CGSizeZero, {}, nil);
  
  std::vector<CKComponentLayoutChild> childrenOf10 = { {{0,0}, x12}, {{0,0}, x13}};
  CKComponentLayout x10 = CKComponentLayout(componentMock10, CGSizeZero, childrenOf10, nil);
  
  CKComponentLayout x11 = CKComponentLayout(componentMock11, CGSizeZero, {}, nil);
  std::vector<CKComponentLayoutChild> childrenOf7 = { {{0,0}, x10}, {{0,0}, x11}};
  CKComponentLayout x7 = CKComponentLayout(componentMock7, CGSizeZero, childrenOf7, nil);
  
  CKComponentLayout x8 = CKComponentLayout(componentMock8, CGSizeZero, {}, nil);
  CKComponentLayout x9 = CKComponentLayout(componentMock9, CGSizeZero, {}, nil);
  
  std::vector<CKComponentLayoutChild> childrenOf6 = { {{0,0}, x8}, {{0,0}, x9}};
  CKComponentLayout x6 = CKComponentLayout(componentMock6, CGSizeZero, childrenOf6, nil);
  
  CKComponentLayout x5 = CKComponentLayout(componentMock5, CGSizeZero, {}, nil);
  
  std::vector<CKComponentLayoutChild> childrenOf3 = { {{0,0}, x5}, {{0,0}, x6}, {{0,0}, x7}};
  CKComponentLayout x3 = CKComponentLayout(componentMock3, CGSizeZero, childrenOf3, nil);
  
  CKComponentLayout x2 = CKComponentLayout(componentMock2, CGSizeZero, {}, nil);
  CKComponentLayout x4 = CKComponentLayout(componentMock4, CGSizeZero, {}, nil);
  
  std::vector<CKComponentLayoutChild> childrenOf1 = { {{0,0}, x2}, {{0,0}, x3}, {{0,0}, x4}};
  CKComponentLayout x1 = CKComponentLayout(componentMock1, CGSizeZero, childrenOf1, nil);
  
  const CKComponentCollision collision = CKFindComponentScopeCollision(x1);
  
  // Component Twelve and Ten should collide
  XCTAssertTrue(collision.hasCollision());
  XCTAssertNotNil(collision.component);
  XCTAssertTrue([collision.component isKindOfClass:[CKTwelveComponent class]] ||
                [collision.component isKindOfClass:[CKTenComponent class]]);
  
  // The lowest common ancestor of the two should be Ten itself
  XCTAssertTrue([collision.lowestCommonAncestor isKindOfClass:[CKTenComponent class]]);
}

@end
