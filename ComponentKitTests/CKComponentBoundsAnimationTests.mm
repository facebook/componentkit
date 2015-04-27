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

#import "CKComponentScope.h"
#import "CKComponentScopeFrame.h"
#import "CKComponentScopeRoot.h"
#import "CKComponentSubclass.h"

@interface CKComponentBoundsAnimationTests : XCTestCase
@end

@interface CKBoundsAnimationComponent : CKComponent
@end

@implementation CKBoundsAnimationComponent
+ (instancetype)new
{
  CKComponentScope scope(self);
  return [super newWithView:{} size:{}];
}

- (CKComponentBoundsAnimation)boundsAnimationFromPreviousComponent:(CKComponent *)previousComponent
{
  return {.duration = 0.5};
}
@end

@implementation CKComponentBoundsAnimationTests

- (void)testStateScopeFrameIsNotFoundWhenAnotherComponentInTheSameScopeAcquiresItFirst
{
  CKComponent *(^block)(void) = ^{
    return [CKBoundsAnimationComponent new];
  };
  const CKBuildComponentResult firstResult = CKBuildComponent([CKComponentScopeRoot rootWithListener:nil], {}, block);
  const CKBuildComponentResult secondResult = CKBuildComponent(firstResult.scopeRoot, {}, block);
  XCTAssertEqual(secondResult.boundsAnimation.duration, 0.5);
}

@end
