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

#import <ComponentKit/CKCasting.h>
#import <ComponentKit/CKBuildComponent.h>
#import <ComponentKit/CKComponentEvents.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentScopeRootFactory.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKComponentAnimations.h>
#import <ComponentKit/CKCompositeComponent.h>
#import <ComponentKit/CKThreadLocalComponentScope.h>

#import "CKComponentAnimationsEquality.h"

@interface CKComponentAnimationsTests_LayoutDiffing: XCTestCase
@end

@interface ComponentWithInitialMountAnimations: CKComponent
+ (instancetype)newWithInitialMountAnimations:(std::vector<CKComponentAnimation>)animations;
@end

@interface ComponentWithAnimationsFromPreviousComponent: CKComponent
+ (instancetype)newWithAnimations:(std::vector<CKComponentAnimation>)animations
            fromPreviousComponent:(CKComponent *const)component;
@end

@interface ComponentWithAnimationOnFinalUnmount: CKComponent
+ (instancetype)newWithAnimation:(CAAnimation *const)animation;
@end

@interface CompositeComponentWithScope: CKCompositeComponent
@end

const auto sizeRange = CKSizeRange {CGSizeZero, {INFINITY, INFINITY}};

@implementation CKComponentAnimationsTests_LayoutDiffing

- (void)test_WhenPreviousTreeIsEmpty_ReturnsAllComponentsWithInitialMountAnimationsAsAppeared
{
  const auto r = CKComponentScopeRootWithDefaultPredicates(nil, nil);
  const auto bcr = CKBuildComponent(r, {}, ^{
    return CK::CompositeComponentBuilder().component([ComponentWithInitialMountAnimations new]).build();
  });
  const auto c = CK::objCForceCast<CKCompositeComponent>(bcr.component);
  const auto l = CKComputeRootComponentLayout(c, sizeRange, nil);

  const auto diff = CK::animatedComponentsBetweenLayouts(l, {});

  const auto expectedDiff = CK::ComponentTreeDiff {
    .appearedComponents = {c.child},
  };
  XCTAssert(diff == expectedDiff);
}

- (void)test_WhenPreviousTreeIsNotEmpty_ReturnsOnlyNewComponentsWithInitialMountAnimationsAsAppeared
{
  const auto bcr = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, ^{
    return CK::CompositeComponentBuilder().component([ComponentWithInitialMountAnimations new]).build();
  });
  const auto l = CKComputeRootComponentLayout(bcr.component, sizeRange, nil);
  const auto bcr2 = CKBuildComponent(bcr.scopeRoot, {}, ^{
    return CK::CompositeComponentBuilder().component([ComponentWithInitialMountAnimations new]).build();
  });
  const auto l2 = CKComputeRootComponentLayout(bcr2.component, sizeRange, nil);

  const auto diff = CK::animatedComponentsBetweenLayouts(l2, l);

  XCTAssert(diff == CK::ComponentTreeDiff {});
}

- (void)test_WhenPreviousTreeIsNotEmpty_ReturnsComponentsWithChangeAnimationsAsUpdated
{
  const auto bcr = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, ^{
    return CK::CompositeComponentBuilder().component([ComponentWithAnimationsFromPreviousComponent new]).build();
  });
  const auto c = CK::objCForceCast<CKCompositeComponent>(bcr.component);
  const auto l = CKComputeRootComponentLayout(c, sizeRange, nil);
  const auto bcr2 = CKBuildComponent(bcr.scopeRoot, {}, ^{
    return CK::CompositeComponentBuilder().component([ComponentWithAnimationsFromPreviousComponent new]).build();
  });
  const auto c2 = CK::objCForceCast<CKCompositeComponent>(bcr2.component);
  const auto l2 = CKComputeRootComponentLayout(c2, sizeRange, nil);

  const auto diff = CK::animatedComponentsBetweenLayouts(l2, l);

  const auto expectedDiff = CK::ComponentTreeDiff {
    .updatedComponents = {{c.child, c2.child}},
  };
  XCTAssert(diff == expectedDiff);
}

- (void)test_WhenPreviousTreeHasTheSameComponents_DoesNotReturnThemAsUpdated
{
  const auto bcr = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, ^{
    return CK::CompositeComponentBuilder().component([ComponentWithAnimationsFromPreviousComponent new]).build();
  });
  const auto l = CKComputeRootComponentLayout(bcr.component, sizeRange, nil);

  const auto diff = CK::animatedComponentsBetweenLayouts(l, l);

  XCTAssert(diff == CK::ComponentTreeDiff {});
}

- (void)test_WhenPreviousTreeIsNotEmpty_ReturnsOnlyDisappearedComponentsWithDisappearAnimation
{
  __block ComponentWithAnimationOnFinalUnmount *c;
  const auto bcr = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, ^{
    c = [ComponentWithAnimationOnFinalUnmount new];
    return CK::CompositeComponentBuilder().component([CompositeComponentWithScope newWithComponent:c]).build();
  });
  const auto l = CKComputeRootComponentLayout(bcr.component, sizeRange, nil);
  const auto bcr2 = CKBuildComponent(bcr.scopeRoot, {}, ^{
    // Compared to the previous tree there are two components that have disappeared: CompositeComponentWithScope and
    // ComponentWithDisappearAnimation. However, we should get only the latter in ComponentTreeDiff::disappearedComponents
    // since the former doesn't define any disappear animation.
    return CK::CompositeComponentBuilder().component([CKComponent new]).build();
  });
  const auto l2 = CKComputeRootComponentLayout(bcr2.component, sizeRange, nil);

  const auto diff = CK::animatedComponentsBetweenLayouts(l2, l);

  const auto expectedDiff = CK::ComponentTreeDiff {
    .disappearedComponents = {c},
  };
  XCTAssert(diff == expectedDiff);
}

@end

@interface CKComponentAnimationsTests: XCTestCase
@end

@implementation CKComponentAnimationsTests

- (void)test_WhenThereAreNoComponentsToAnimate_ThereAreNoAnimations
{
  const auto as = CK::animationsForComponents({}, [UIView new]);

  const auto expected = CKComponentAnimations::AnimationsByComponentMap {};
  XCTAssert(animationsAreEqual(as.animationsOnInitialMount(), expected));
}

- (void)test_ForAllAppearedComponents_AnimationsOnInitialMountAreCollected
{
  const auto a1 = CKComponentAnimation([CKComponent new], [CAAnimation new]);
  const auto c1 = [ComponentWithInitialMountAnimations newWithInitialMountAnimations:{a1}];
  const auto a2 = CKComponentAnimation([CKComponent new], [CAAnimation new]);
  const auto c2 = [ComponentWithInitialMountAnimations newWithInitialMountAnimations:{a2}];
  const auto diff = CK::ComponentTreeDiff {
    .appearedComponents = {
      c1,
      c2,
    },
  };

  const auto as = animationsForComponents(diff, [UIView new]);

  const auto expected = CKComponentAnimations::AnimationsByComponentMap {
    {c1, {a1}},
    {c2, {a2}},
  };
  XCTAssert(animationsAreEqual(as.animationsOnInitialMount(), expected));
}

- (void)test_ForAllUpdatedComponents_AnimationsFromPreviousComponentAreCollected
{
  const auto a1 = CKComponentAnimation([CKComponent new], [CAAnimation new]);
  const auto pc1 = [CKComponent new];
  const auto c1 = [ComponentWithAnimationsFromPreviousComponent newWithAnimations:{a1} fromPreviousComponent:pc1];
  const auto a2 = CKComponentAnimation([CKComponent new], [CAAnimation new]);
  const auto pc2 = [CKComponent new];
  const auto c2 = [ComponentWithAnimationsFromPreviousComponent newWithAnimations:{a2} fromPreviousComponent:pc2];
  const auto componentPairs = std::vector<CK::ComponentTreeDiff::Pair> {
    {pc1, c1},
    {pc2, c2},
  };
  const auto diff = CK::ComponentTreeDiff {
    .updatedComponents = componentPairs,
  };

  const auto as = animationsForComponents(diff, [UIView new]);

  const auto expected = CKComponentAnimations::AnimationsByComponentMap {
    {c1, {a1}},
    {c2, {a2}},
  };
  XCTAssert(animationsAreEqual(as.animationsFromPreviousComponent(), expected));
}

- (void)test_ForAllDisappearedComponents_AnimationsOnFinalUnmountAreCollected
{
  const auto a1 = [CAAnimation new];
  const auto c1 = [ComponentWithAnimationOnFinalUnmount newWithAnimation:a1];
  const auto a2 = [CAAnimation new];
  const auto c2 = [ComponentWithAnimationOnFinalUnmount newWithAnimation:a2];
  const auto diff = CK::ComponentTreeDiff {
    .disappearedComponents = {
      c1,
      c2,
    },
  };

  const auto as = animationsForComponents(diff, [UIView new]);

  XCTAssert(as.animationsOnFinalUnmount().size() == diff.disappearedComponents.size());
}

- (void)test_DefaultInitialised_IsEmpty
{
  XCTAssert(CKComponentAnimations {}.isEmpty());
}

- (void)test_IfHasInitialAnimations_IsNotEmpty
{
  const auto a1 = CKComponentAnimation([CKComponent new], [CAAnimation new]);
  const auto c1 = [ComponentWithInitialMountAnimations newWithInitialMountAnimations:{a1}];
  const auto as = CKComponentAnimations {
    {
      {c1, {a1}},
    },
    {},
    {}
  };

  XCTAssertFalse(as.isEmpty());
}

- (void)test_IfHasAnimationsFromPreviousComponent_IsNotEmpty
{
  const auto a1 = CKComponentAnimation([CKComponent new], [CAAnimation new]);
  const auto c1 = [ComponentWithInitialMountAnimations newWithInitialMountAnimations:{a1}];
  const auto as = CKComponentAnimations {
    {},
    {
      {c1, {a1}},
    },
    {}
  };

  XCTAssertFalse(as.isEmpty());
}

- (void)test_IfComponentHasNoInitialAnimations_IsEmpty
{
  const auto diff = CK::ComponentTreeDiff {
    .appearedComponents = {
      [ComponentWithInitialMountAnimations newWithInitialMountAnimations:{}],
    },
  };

  const auto as = animationsForComponents(diff, [UIView new]);

  XCTAssert(as.isEmpty());
}

- (void)test_IfComponentHasNoAnimationsFromPreviousComponent_IsEmpty
{
  const auto pc1 = [CKComponent new];
  const auto c1 = [ComponentWithAnimationsFromPreviousComponent newWithAnimations:{} fromPreviousComponent:pc1];
  const auto diff = CK::ComponentTreeDiff {
    .updatedComponents = {
      {pc1, c1},
    }
  };

  const auto as = animationsForComponents(diff, [UIView new]);

  XCTAssert(as.isEmpty());
}

- (void)test_IfComponentHasNoFinalUnmountAnimations_IsEmpty
{
  const auto diff = CK::ComponentTreeDiff {
    .disappearedComponents = {
      [ComponentWithAnimationOnFinalUnmount newWithAnimation:nil],
    },
  };

  const auto as = animationsForComponents(diff, [UIView new]);

  XCTAssert(as.isEmpty());
}

@end

@implementation ComponentWithInitialMountAnimations {
  std::vector<CKComponentAnimation> _animations;
}

+ (instancetype)new
{
  return [self newWithInitialMountAnimations:{}];
}

+ (instancetype)newWithInitialMountAnimations:(std::vector<CKComponentAnimation>)animations
{
  CKComponentScope s(self);
  const auto c = [super new];
  c->_animations = std::move(animations);
  return c;
}

- (std::vector<CKComponentAnimation>)animationsOnInitialMount { return _animations; }
@end

@implementation ComponentWithAnimationsFromPreviousComponent{
  std::vector<CKComponentAnimation> _animations;
  CKComponent *_previousComponent;
}

+ (instancetype)new
{
  return [self newWithAnimations:{} fromPreviousComponent:nil];
}

+ (instancetype)newWithAnimations:(std::vector<CKComponentAnimation>)animations
            fromPreviousComponent:(CKComponent *const)component
{
  CKComponentScope s(self);
  const auto c = [super new];
  c->_animations = std::move(animations);
  c->_previousComponent = component;
  return c;
}

- (std::vector<CKComponentAnimation>)animationsFromPreviousComponent:(CKComponent *)previousComponent
{
  if (previousComponent == _previousComponent) {
    return _animations;
  } else {
    return {};
  };
}
@end

@implementation ComponentWithAnimationOnFinalUnmount
{
  CAAnimation *_animation;
}

+ (instancetype)new
{
  CKComponentScope s(self);
  return [self newWithAnimation:nil];
}

+ (instancetype)newWithAnimation:(CAAnimation *const)animation
{
  const auto c = [super new];
  if (c) {
    c->_animation = animation;
  }
  return c;
}

- (std::vector<CKComponentFinalUnmountAnimation>)animationsOnFinalUnmount
{
  if (!_animation) {
    return {};
  } else {
    return {{self, _animation}};
  }
}
@end

@implementation CompositeComponentWithScope
+ (instancetype)newWithComponent:(CKComponent *)component
{
  CKComponentScope s(self);
  return [super newWithComponent:component];
}
@end

@interface CKComponentAnimationTests : XCTestCase
@end

@implementation CKComponentAnimationTests

- (void)test_WhenInitialisedWithComponentAndAnimation_CallsCompletionFromCleanup
{
  __block auto numCompletionCalls = 0;
  auto const a = CKComponentAnimation {
    [CKComponent new],
    [CAAnimation new],
    nil,
    ^{ ++numCompletionCalls; }
  };

  a.cleanup(nil);

  XCTAssertEqual(numCompletionCalls, 1);
}

- (void)test_WhenInitialisedWithFinalUnmountAnimation_CallsCompletionFromCleanup
{
  __block auto numCompletionCalls = 0;
  auto const a = CKComponentAnimation {
    CKComponentFinalUnmountAnimation {
      [CKComponent new], [CAAnimation new], ^{ ++numCompletionCalls; }
    },
    [UIView new]
  };

  a.cleanup(nil);

  XCTAssertEqual(numCompletionCalls, 1);
}

- (void)test_WhenInitialisedWithHooks_CallsCompletionFromCleanup
{
  __block auto numCompletionCalls = 0;
  auto const a = CKComponentAnimation {
    CKComponentAnimationHooks {
      ^id(){ return nil; },
      ^id(id){ return nil; },
      ^(id){}
    },
    ^{ ++numCompletionCalls; }
  };

  a.cleanup(nil);

  XCTAssertEqual(numCompletionCalls, 1);
}

@end
