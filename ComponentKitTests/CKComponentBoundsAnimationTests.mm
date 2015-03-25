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

#import "CKComponentLifecycleManager.h"
#import "CKComponentProvider.h"
#import "CKComponentScope.h"
#import "CKCompositeComponent.h"

@interface CKBoundsAnimatingComponent : CKCompositeComponent
+ (instancetype)newWithHeight:(CGFloat)height;
@end

@implementation CKBoundsAnimatingComponent
+ (instancetype)newWithHeight:(CGFloat)height
{
  CKComponentScope scope(self);
  return [super newWithComponent:[CKComponent newWithView:{} size:{.height = height}]];
}
- (CKComponentBoundsAnimation)boundsAnimationFromPreviousComponent:(CKBoundsAnimatingComponent *)previous
{
  return {.duration = 5.0, .delay = 2.0};
}
@end

@interface CKComponentBoundsAnimationTests : XCTestCase <CKComponentProvider>
@end

@implementation CKComponentBoundsAnimationTests

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [CKBoundsAnimatingComponent newWithHeight:(CGFloat)[(NSNumber *)model doubleValue]];
}

- (void)testComputingUpdateForComponentLifecycleManagerReturnsBoundsAnimation
{
  static const CKSizeRange size = {{100, 0}, {100, INFINITY}};
  CKComponentLifecycleManager *lifeManager = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class] context:nil];

  CKComponentLifecycleManagerState stateA = [lifeManager prepareForUpdateWithModel:@100 constrainedSize:size];
  CKComponentLifecycleManagerState stateB = [lifeManager prepareForUpdateWithModel:@200 constrainedSize:size];
  XCTAssertEqual(stateB.boundsAnimation.duration, (NSTimeInterval)5.0);
  XCTAssertEqual(stateB.boundsAnimation.delay, (NSTimeInterval)2.0);
}

@end
