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
#import <ComponentKit/CKCasting.h>
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKComponentScope.h>
#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKComponentScopeRootFactory.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKFlexboxComponent.h>

@interface CKComponentBoundsAnimationTests : XCTestCase
@end

@interface CKBoundsAnimationRecordingView : UIView
@property (nonatomic, readonly) BOOL animatedLastBoundsChange;
@end

@implementation CKBoundsAnimationRecordingView
- (void)setBounds:(CGRect)bounds
{
  [super setBounds:bounds];
  _animatedLastBoundsChange = ![CATransaction disableActions];
}
@end

@interface CKBoundsAnimationComponent : CKComponent
@end

@implementation CKBoundsAnimationComponent
+ (instancetype)newWithIdentifier:(NSNumber *)identifier
{
  CKComponentScope scope(self, identifier);
  return [super newWithView:{[CKBoundsAnimationRecordingView class]} size:{}];
}

- (CKComponentBoundsAnimation)boundsAnimationFromPreviousComponent:(CKComponent *)previousComponent
{
  return {.duration = 0.5};
}
@end

@implementation CKComponentBoundsAnimationTests

- (void)testBoundsAnimationCorrectlyComputedWhenBuildingNewVersionOfComponent
{
  CKComponent *(^block)(void) = ^{
    return [CKBoundsAnimationComponent newWithIdentifier:@0];
  };
  const CKBuildComponentResult firstResult = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, block);
  const CKBuildComponentResult secondResult = CKBuildComponent(firstResult.scopeRoot, {}, block);
  XCTAssertEqual(secondResult.boundsAnimation.duration, 0.5);
}

- (void)testBoundsAnimationIsAppliedToViewsWhenUpdatingToNewVersionOfComponent
{
  CKComponent *(^block)(void) = ^{
    return [CKBoundsAnimationComponent newWithIdentifier:@0];
  };
  UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];

  const CKBuildComponentResult firstResult = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, block);
  const CKComponentLayout firstLayout = [firstResult.component layoutThatFits:{{50, 50}, {50, 50}} parentSize:{}];
  NSSet *firstMountedComponents = CKMountComponentLayout(firstLayout, container, nil, nil).mountedComponents;

  const CKBuildComponentResult secondResult = CKBuildComponent(firstResult.scopeRoot, {}, block);
  const CKComponentLayout secondLayout = [secondResult.component layoutThatFits:{{100, 100}, {100, 100}} parentSize:{}];
  NSSet *secondMountedComponents = CKMountComponentLayout(secondLayout, container, firstMountedComponents, nil).mountedComponents;

  CKBoundsAnimationRecordingView *v = (CKBoundsAnimationRecordingView *)secondResult.component.viewContext.view;
  XCTAssertTrue(v.animatedLastBoundsChange);

  CKUnmountComponents(secondMountedComponents);
}

- (void)testBoundsAnimationIsNotAppliedToNewlyCreatedViews
{
  UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];

  const CKBuildComponentResult firstResult = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, ^{
    return CK::FlexboxComponentBuilder()
               .alignItems(CKFlexboxAlignItemsStretch)
               .child([CKBoundsAnimationComponent newWithIdentifier:@0])
                   .flexGrow(1)
               .build();
  });
  const CKComponentLayout firstLayout = [firstResult.component layoutThatFits:{{100, 100}, {100, 100}} parentSize:{}];
  NSSet *firstMountedComponents = CKMountComponentLayout(firstLayout, container, nil, nil).mountedComponents;

  const CKBuildComponentResult secondResult = CKBuildComponent(firstResult.scopeRoot, {}, ^{
    return CK::FlexboxComponentBuilder()
               .alignItems(CKFlexboxAlignItemsStretch)
               .child([CKBoundsAnimationComponent newWithIdentifier:@0])
                   .flexGrow(1)
               .child([CKBoundsAnimationComponent newWithIdentifier:@1])
                   .flexGrow(1)
               .build();
  });
  const CKComponentLayout secondLayout = [secondResult.component layoutThatFits:{{100, 100}, {100, 100}} parentSize:{}];
  NSSet *secondMountedComponents = CKMountComponentLayout(secondLayout, container, firstMountedComponents, nil).mountedComponents;

  XCTAssertEqual([container.subviews count], 2u);
  XCTAssertTrue(((CKBoundsAnimationRecordingView *)container.subviews[0]).animatedLastBoundsChange);
  XCTAssertFalse(((CKBoundsAnimationRecordingView *)container.subviews[1]).animatedLastBoundsChange);

  CKUnmountComponents(secondMountedComponents);
}

- (void)test_WhenComponentBlocksImplicitAnimations_BoundsAnimationIsNotApplied
{
  auto const f = ^CKComponent *{
    return CK::ComponentBuilder()
               .viewClass([CKBoundsAnimationRecordingView class])
               .blockImplicitAnimations(true)
               .build();
  };
  auto const bcr1 = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, f);
  auto const l1 = [bcr1.component layoutThatFits:{{50, 50}, {50, 50}} parentSize:{}];
  auto const v = [[UIView alloc] initWithFrame:{{0, 0}, {50, 50}}];
  auto const mc1 = CKMountComponentLayout(l1, v, nil, nil).mountedComponents;
  auto const bcr2 = CKBuildComponent(bcr1.scopeRoot, {}, f);
  auto const l2 = [bcr2.component layoutThatFits:{{100, 100}, {100, 100}} parentSize:{}];

  __unused auto const _ = CKMountComponentLayout(l2, v, mc1, nil).mountedComponents;

  auto const barv = CK::objCForceCast<CKBoundsAnimationRecordingView>(bcr2.component.viewContext.view);
  XCTAssertFalse(barv.animatedLastBoundsChange);
}

- (void)testBoundsAnimationIsNotAppliedWhenViewRecycledForComponentWithDistinctUniqueIdentifier
{
  UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];

  const CKBuildComponentResult firstResult = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, ^{
    return [CKBoundsAnimationComponent newWithIdentifier:@0];
  });
  const CKComponentLayout firstLayout = [firstResult.component layoutThatFits:{{50, 50}, {50, 50}} parentSize:{}];
  NSSet *firstMountedComponents = CKMountComponentLayout(firstLayout, container, nil, nil).mountedComponents;

  const CKBuildComponentResult secondResult = CKBuildComponent(firstResult.scopeRoot, {}, ^{
    return [CKBoundsAnimationComponent newWithIdentifier:@1];
  });
  const CKComponentLayout secondLayout = [secondResult.component layoutThatFits:{{100, 100}, {100, 100}} parentSize:{}];
  NSSet *secondMountedComponents = CKMountComponentLayout(secondLayout, container, firstMountedComponents, nil).mountedComponents;

  CKBoundsAnimationRecordingView *v = (CKBoundsAnimationRecordingView *)secondResult.component.viewContext.view;
  XCTAssertFalse(v.animatedLastBoundsChange);

  CKUnmountComponents(secondMountedComponents);
}

- (void)testBoundsAnimationIsNotAppliedToChildrenWhenViewRecycledForComponentWithDistinctUniqueIdentifier
{
  UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];

  const CKBuildComponentResult firstResult = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, ^{
    CKComponentScope scope([CKFlexboxComponent class], @"foo");
    return CK::FlexboxComponentBuilder()
               .viewClass([CKBoundsAnimationRecordingView class])
               .alignItems(CKFlexboxAlignItemsStretch)
               .child(CK::ComponentBuilder()
                   .viewClass([CKBoundsAnimationRecordingView class])
                   .build())
                   .flexGrow(1)
               .build();
  });
  const CKComponentLayout firstLayout = [firstResult.component layoutThatFits:{{50, 50}, {50, 50}} parentSize:{}];
  NSSet *firstMountedComponents = CKMountComponentLayout(firstLayout, container, nil, nil).mountedComponents;

  const CKBuildComponentResult secondResult = CKBuildComponent(firstResult.scopeRoot, {}, ^{
    // Change the scope identifier for the new version of the stack. This means that the outer view's bounds change
    // shouldn't be animated; crucially, the *inner* view's bounds change should *also* not be animated, even though
    // it is recycling the same view.

    // NB: We use a plain CKComponent, not a CKBoundsAnimationComponent; otherwise the scope tokens of the child will
    // be different, and we will avoid animating the child view for that reason instead of the changing parent scope.
    CKComponentScope scope([CKFlexboxComponent class], @"bar");
    return CK::FlexboxComponentBuilder()
               .viewClass([CKBoundsAnimationRecordingView class])
               .alignItems(CKFlexboxAlignItemsStretch)
               .child(CK::ComponentBuilder()
                   .viewClass([CKBoundsAnimationRecordingView class])
                   .build())
                   .flexGrow(1)
               .build();
  });
  const CKComponentLayout secondLayout = [secondResult.component layoutThatFits:{{100, 100}, {100, 100}} parentSize:{}];
  NSSet *secondMountedComponents = CKMountComponentLayout(secondLayout, container, firstMountedComponents, nil).mountedComponents;

#if CK_ASSERTIONS_ENABLED
  CKBoundsAnimationRecordingView *v = (CKBoundsAnimationRecordingView *)secondResult.component.viewContext.view;
  CKBoundsAnimationRecordingView *subview = [[v subviews] firstObject];
  CKAssertTrue(subview != nil && subview.animatedLastBoundsChange == NO);
#endif

  CKUnmountComponents(secondMountedComponents);
}

#if CK_ASSERTIONS_ENABLED
- (void)test_StoresComponentThatProducedBoundsAnimation
{
  auto const f = ^{ return [CKBoundsAnimationComponent newWithIdentifier:@0]; };
  auto const bcr1 = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, f);
  auto const bcr2 = CKBuildComponent(bcr1.scopeRoot, {}, f);
  XCTAssertEqualObjects(bcr2.boundsAnimation.component, bcr2.component);
}
#endif

@end

@interface CKComponentBoundsAnimationTests_Equality : XCTestCase
@end

@implementation CKComponentBoundsAnimationTests_Equality

- (void)test_WhenAllFieldsForDefaultModeAreEqual_IsEqual
{
  auto const ba1 = CKComponentBoundsAnimation {
    .duration = 0.5,
    .delay = 0.2,
    .mode = CKComponentBoundsAnimationModeDefault,
    .options = UIViewAnimationOptionPreferredFramesPerSecond60,
    .timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.1 :0.9 :0.9 :0.1],
  };
  auto const ba2 = CKComponentBoundsAnimation {
    .duration = 0.5,
    .delay = 0.2,
    .options = UIViewAnimationOptionPreferredFramesPerSecond60,
    .timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.1 :0.9 :0.9 :0.1],
  };

  XCTAssert(ba1 == ba2);
}

- (void)test_WhenTimingFunctionsAreNotEqual_IsNotEqual
{
  auto const ba1 = CKComponentBoundsAnimation {
    .duration = 0.5,
    .delay = 0.2,
    .mode = CKComponentBoundsAnimationModeDefault,
    .options = UIViewAnimationOptionPreferredFramesPerSecond60,
    .timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.1 :0.9 :0.9 :0.2],
  };
  auto const ba2 = CKComponentBoundsAnimation {
    .duration = 0.5,
    .delay = 0.2,
    .options = UIViewAnimationOptionPreferredFramesPerSecond60,
    .timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.1 :0.9 :0.9 :0.1],
  };

  XCTAssert(ba1 != ba2);
}

- (void)test_WhenSpringParamsAreNotEqual_IsNotEqual
{
  auto const ba1 = CKComponentBoundsAnimation {
    .duration = 0.5,
    .delay = 0.2,
    .mode = CKComponentBoundsAnimationModeSpring,
  };
  auto const ba2 = CKComponentBoundsAnimation {
    .duration = 0.5,
    .delay = 0.2,
    .mode = CKComponentBoundsAnimationModeSpring,
    .springDampingRatio = 0.3,
    .springInitialVelocity = 10,
  };

  XCTAssertFalse(ba1 == ba2);
}

- (void)test_WhenModeIsDefault_SpringProperiesAreIgnored
{
  auto const ba1 = CKComponentBoundsAnimation {
    .duration = 0.5,
    .delay = 0.2,
    .mode = CKComponentBoundsAnimationModeDefault,
  };
  auto const ba2 = CKComponentBoundsAnimation {
    .duration = 0.5,
    .delay = 0.2,
    .springDampingRatio = 0.3,
    .springInitialVelocity = 10,
  };

  XCTAssert(ba1 == ba2);
}

@end
