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

#import <array>

#import <ComponentKit/CKCasting.h>
#import <ComponentKit/CKAnimation.h>
#import <ComponentKit/ComponentUtilities.h>

using namespace CK;
using namespace CK::Animation;

template <size_t N>
static auto checkKeyPathsForAnimations(XCTestCase *self,
                                       const std::array<CAPropertyAnimation *, N> &animations,
                                       const std::array<const char *, N> &expectedKeyPaths)
{
  for (auto i = 0; i < N; ++i) {
    XCTAssertEqualObjects(animations[i].keyPath, @(expectedKeyPaths[i]));
  }
}

@interface CKAnimationTests_KeyPaths : XCTestCase
@end

@implementation CKAnimationTests_KeyPaths

- (void)testInitialAnimationsKeyPaths
{
  auto const animations = std::array<CAPropertyAnimation *, 4>{
    objCForceCast<CAPropertyAnimation>(Initial::alpha().toCA()),
    objCForceCast<CAPropertyAnimation>(Initial::translationY().toCA()),
    objCForceCast<CAPropertyAnimation>(Initial::backgroundColor().toCA()),
    objCForceCast<CAPropertyAnimation>(Initial::borderColor().toCA()),
  };

  auto const expectedKeyPaths = std::array<const char *, 4>{
    "opacity",
    "transform.translation.y",
    "backgroundColor",
    "borderColor"
  };

  checkKeyPathsForAnimations(self, animations, expectedKeyPaths);
}

- (void)testFinalAnimationsKeyPaths
{
  auto const animations = std::array<CAPropertyAnimation *, 4>{
    objCForceCast<CAPropertyAnimation>(Final::alpha().toCA()),
    objCForceCast<CAPropertyAnimation>(Final::translationY().toCA()),
    objCForceCast<CAPropertyAnimation>(Final::backgroundColor().toCA()),
    objCForceCast<CAPropertyAnimation>(Final::borderColor().toCA()),
  };

  auto const expectedKeyPaths = std::array<const char *, 4>{
    "opacity",
    "transform.translation.y",
    "backgroundColor",
    "borderColor"
  };

  checkKeyPathsForAnimations(self, animations, expectedKeyPaths);
}

- (void)testChangeAnimationsKeyPaths
{
  auto const animations = std::array<CAPropertyAnimation *, 5>{
    objCForceCast<CAPropertyAnimation>(Change::alpha().toCA()),
    objCForceCast<CAPropertyAnimation>(Change::translationY().toCA()),
    objCForceCast<CAPropertyAnimation>(Change::backgroundColor().toCA()),
    objCForceCast<CAPropertyAnimation>(Change::borderColor().toCA()),
    objCForceCast<CAPropertyAnimation>(Change::position().toCA()),
  };

  auto const expectedKeyPaths = std::array<const char *, 5>{
    "opacity",
    "transform.translation.y",
    "backgroundColor",
    "borderColor",
    "position"
  };

  checkKeyPathsForAnimations(self, animations, expectedKeyPaths);
}

@end

@interface CKAnimationTests_Initial: XCTestCase
@end

@implementation CKAnimationTests_Initial

- (void)testSettingScalarFromValue
{
  auto a = objCForceCast<CABasicAnimation>(Initial::alpha().from(0).toCA());

  XCTAssertEqualObjects(a.fromValue, @(0));
}

- (void)testSettingUIColorFromValueForInitialAnimation
{
  auto a = objCForceCast<CABasicAnimation>(Initial::backgroundColor().from(UIColor.blueColor).toCA());

  XCTAssertEqualObjects(a.fromValue, (id)UIColor.blueColor.CGColor);
}

- (void)test_WhenDurationIsNotSet_ItIsZero
{
  XCTAssertEqual(Initial::alpha().toCA().duration, 0);
  XCTAssertEqual(Initial::backgroundColor().toCA().duration, 0);
}

- (void)testSettingDuration
{
  XCTAssertEqual(Initial::alpha().withDuration(0.25).toCA().duration, 0.25);
  XCTAssertEqual(Initial::backgroundColor().withDuration(0.25).toCA().duration, 0.25);
}

- (void)testSettingDelay
{
  XCTAssertEqual(Initial::alpha().withDelay(0.25).toCA().beginTime, 0.25);
  XCTAssertEqual(Initial::backgroundColor().withDelay(0.25).toCA().beginTime, 0.25);
}

- (void)test_WhenTimingFunctionIsNotSet_UsesLinear
{
  XCTAssertEqualObjects(Initial::alpha().toCA().timingFunction, [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]);
  XCTAssertEqualObjects(Initial::backgroundColor().toCA().timingFunction, [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]);
}

- (void)testSettingTimingFunction
{
  XCTAssertEqualObjects(Initial::alpha().easeIn().toCA().timingFunction, [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]);
  XCTAssertEqualObjects(Initial::backgroundColor().easeIn().toCA().timingFunction, [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]);
  XCTAssertEqualObjects(Initial::alpha().easeOut().toCA().timingFunction, [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]);
  XCTAssertEqualObjects(Initial::backgroundColor().easeOut().toCA().timingFunction, [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]);
}

- (void)testSettingTimingFunctionWithDuration
{
  auto a1 = Initial::alpha().easeIn(0.25).toCA();

  XCTAssertEqual(a1.duration, 0.25);
  XCTAssertEqualObjects(a1.timingFunction, [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]);

  auto a2 = Initial::backgroundColor().easeIn(0.25).toCA();

  XCTAssertEqual(a2.duration, 0.25);
  XCTAssertEqualObjects(a2.timingFunction, [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]);
}

- (void)testAlwaysUsesBackwardsFillMode
{
  XCTAssertEqualObjects(Initial::alpha().toCA().fillMode, kCAFillModeBackwards);
  XCTAssertEqualObjects(Initial::backgroundColor().toCA().fillMode, kCAFillModeBackwards);
}

@end

@interface CKAnimationTests_Final: XCTestCase
@end

@implementation CKAnimationTests_Final

- (void)testSettingScalarToValueForFinalAnimation
{
  auto a = objCForceCast<CABasicAnimation>(Final::alpha().to(0).toCA());

  XCTAssertEqualObjects(a.toValue, @(0));
}

- (void)testSettingUIColorToValueForFinalAnimation
{
  auto a = objCForceCast<CABasicAnimation>(Final::backgroundColor().to(UIColor.blueColor).toCA());

  XCTAssertEqualObjects(a.toValue, (id)UIColor.blueColor.CGColor);
}

- (void)test_WhenDurationIsNotSet_ItIsZero
{
  XCTAssertEqual(Final::alpha().toCA().duration, 0);
  XCTAssertEqual(Final::backgroundColor().toCA().duration, 0);
}

- (void)testSettingDuration
{
  XCTAssertEqual(Final::alpha().withDuration(0.25).toCA().duration, 0.25);
  XCTAssertEqual(Final::backgroundColor().withDuration(0.25).toCA().duration, 0.25);
}

- (void)testSettingDelay
{
  XCTAssertEqual(Final::alpha().withDelay(0.25).toCA().beginTime, 0.25);
  XCTAssertEqual(Final::backgroundColor().withDelay(0.25).toCA().beginTime, 0.25);
}

- (void)test_WhenTimingFunctionIsNotSet_UsesLinear
{
  XCTAssertEqualObjects(Final::alpha().toCA().timingFunction, [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]);
  XCTAssertEqualObjects(Final::backgroundColor().toCA().timingFunction, [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]);
}

- (void)testSettingTimingFunction
{
  XCTAssertEqualObjects(Final::alpha().easeIn().toCA().timingFunction, [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]);
  XCTAssertEqualObjects(Final::backgroundColor().easeIn().toCA().timingFunction, [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]);
  XCTAssertEqualObjects(Final::alpha().easeOut().toCA().timingFunction, [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]);
  XCTAssertEqualObjects(Final::backgroundColor().easeOut().toCA().timingFunction, [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]);
}

- (void)testSettingTimingFunctionWithDuration
{
  auto a1 = Final::alpha().easeIn(0.25).toCA();

  XCTAssertEqual(a1.duration, 0.25);
  XCTAssertEqualObjects(a1.timingFunction, [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]);

  auto a2 = Final::backgroundColor().easeIn(0.25).toCA();

  XCTAssertEqual(a2.duration, 0.25);
  XCTAssertEqualObjects(a2.timingFunction, [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]);
}

- (void)testAlwaysUsesForwardsFillMode
{
  XCTAssertEqualObjects(Final::alpha().toCA().fillMode, kCAFillModeForwards);
  XCTAssertEqualObjects(Final::backgroundColor().toCA().fillMode, kCAFillModeForwards);
}

@end

@interface CKAnimationTests_Change: XCTestCase
@end

@implementation CKAnimationTests_Change

- (void)test_WhenDurationIsNotSet_ItIsZero
{
  auto a = Change::alpha().toCA();

  XCTAssertEqual(a.duration, 0);
}

- (void)testSettingDuration
{
  auto a = Change::alpha().withDuration(0.25).toCA();

  XCTAssertEqual(a.duration, 0.25);
}

- (void)testSettingDelay
{
  auto a = Change::alpha().withDelay(0.25).toCA();

  XCTAssertEqual(a.beginTime, 0.25);
}

- (void)test_WhenTimingFunctionIsNotSet_UsesLinear
{
  XCTAssertEqualObjects(Change::alpha().toCA().timingFunction, [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]);
}

- (void)testSettingTimingFunction
{
  XCTAssertEqualObjects(Change::alpha().easeIn().toCA().timingFunction, [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]);
  XCTAssertEqualObjects(Change::alpha().easeOut().toCA().timingFunction, [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]);
}

- (void)testSettingTimingFunctionWithDuration
{
  auto a = Change::alpha().easeIn(0.25).toCA();

  XCTAssertEqual(a.duration, 0.25);
  XCTAssertEqualObjects(a.timingFunction, [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]);
}

@end

@interface CKAnimationTests_Parallel : XCTestCase
@end

@implementation CKAnimationTests_Parallel

- (void)testComposingAnimations
{
  auto group = objCForceCast<CAAnimationGroup>(parallel(Initial::alpha(), Initial::translationY()).toCA());

  XCTAssertEqual(group.animations.count, 2);
  auto a1 = objCForceCast<CAPropertyAnimation>(group.animations[0]);
  XCTAssertEqualObjects(a1.keyPath, @"opacity");
  auto a2 = objCForceCast<CAPropertyAnimation>(group.animations[1]);
  XCTAssertEqualObjects(a2.keyPath, @"transform.translation.y");
}

- (void)test_WhenDurationIsNotSet_ItIsZero
{
  auto a = parallel(Initial::alpha(), Initial::translationY()).toCA();

  XCTAssertEqual(a.duration, 0);
}

- (void)testSettingDuration
{
  auto a = parallel(Initial::alpha(), Initial::translationY()).withDuration(0.25).toCA();

  XCTAssertEqual(a.duration, 0.25);
}

- (void)testSettingDelay
{
  auto a = parallel(Initial::alpha(), Initial::translationY()).withDelay(0.25).toCA();

  XCTAssertEqual(a.beginTime, 0.25);
}

- (void)test_WhenTimingFunctionIsNotSet_UsesLinear
{
  XCTAssertEqualObjects(parallel(Initial::alpha(), Initial::translationY()).toCA().timingFunction, [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]);
}

- (void)testSettingTimingFunction
{
  XCTAssertEqualObjects(parallel(Initial::alpha(), Initial::translationY()).easeIn().toCA().timingFunction, [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]);
  XCTAssertEqualObjects(parallel(Initial::alpha(), Initial::translationY()).easeOut().toCA().timingFunction, [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]);
}

- (void)testSettingTimingFunctionWithDuration
{
  auto a = parallel(Initial::alpha(), Initial::translationY()).easeIn(0.25).toCA();

  XCTAssertEqual(a.duration, 0.25);
  XCTAssertEqualObjects(a.timingFunction, [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]);
}

- (void)test_WhenComposingInitialAnimations_UsesBackwardsFillMode
{
  auto a = parallel(Initial::alpha(), Initial::translationY()).toCA();

  XCTAssertEqualObjects(a.fillMode, kCAFillModeBackwards);
}

@end

@interface CKAnimationTests_Sequence : XCTestCase
@end

@implementation CKAnimationTests_Sequence

- (void)testComposingAnimations
{
  auto group = objCForceCast<CAAnimationGroup>(sequence(Initial::alpha(), Initial::translationY()).toCA());

  XCTAssertEqual(group.animations.count, 2);
  auto a1 = objCForceCast<CAPropertyAnimation>(group.animations[0]);
  XCTAssertEqualObjects(a1.keyPath, @"opacity");
  auto a2 = objCForceCast<CAPropertyAnimation>(group.animations[1]);
  XCTAssertEqualObjects(a2.keyPath, @"transform.translation.y");
}

- (void)testSecondAnimationStartsAfterFirst
{
  auto group = objCForceCast<CAAnimationGroup>(sequence(Initial::alpha(), Initial::translationY()).toCA());

  XCTAssertEqual(group.animations.count, 2);
  auto a1 = objCForceCast<CAPropertyAnimation>(group.animations[0]);
  XCTAssertEqual(a1.beginTime, 0);
  auto a2 = objCForceCast<CAPropertyAnimation>(group.animations[1]);
  XCTAssertEqual(a2.beginTime, 0.25);
}

- (void)test_DurationIsEqualToSumOfComposedAnimationDurations
{
  XCTAssertEqual(sequence(Initial::alpha(), Initial::translationY()).toCA().duration, 0.5);
  XCTAssertEqual(sequence(Initial::alpha().withDuration(0.5), Initial::translationY()).toCA().duration, 0.75);
  XCTAssertEqual(sequence(Initial::alpha(), Initial::translationY().withDuration(0.5)).toCA().duration, 0.75);
}

- (void)testSettingDelay
{
  auto a = sequence(Initial::alpha(), Initial::translationY()).withDelay(0.25).toCA();

  XCTAssertEqual(a.beginTime, 0.25);
}

- (void)test_WhenTimingFunctionIsNotSet_UsesLinear
{
  XCTAssertEqualObjects(sequence(Initial::alpha(), Initial::translationY()).toCA().timingFunction, [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]);
}

- (void)testSettingTimingFunction
{
  XCTAssertEqualObjects(sequence(Initial::alpha(), Initial::translationY()).easeIn().toCA().timingFunction, [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]);
  XCTAssertEqualObjects(sequence(Initial::alpha(), Initial::translationY()).easeOut().toCA().timingFunction, [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]);
}

- (void)testSettingTimingFunctionWithDuration
{
  auto a = sequence(Initial::alpha(), Initial::translationY()).easeIn().toCA();

  XCTAssertEqualObjects(a.timingFunction, [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]);
}

- (void)test_WhenComposingInitialAnimations_UsesBackwardsFillMode
{
  auto a = sequence(Initial::alpha(), Initial::translationY()).toCA();

  XCTAssertEqualObjects(a.fillMode, kCAFillModeBackwards);
}


@end
