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
#import <ComponentKit/CKComponentScopeRootFactory.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKComponentAnimations.h>
#import <ComponentKit/CKCompositeComponentInternal.h>
#import <ComponentKit/CKThreadLocalComponentScope.h>

@interface CKComponentAnimationsTests_Diffing : XCTestCase
@end

@interface ComponentWithScope: CKCompositeComponent
@end

@interface ComponentWithInitialMountAnimations: CKComponent
+ (instancetype)newWithInitialMountAnimations:(std::vector<CKComponentAnimation>)animations;
@end

@interface ComponentWithAnimationsFromPreviousComponent: CKComponent
+ (instancetype)newWithAnimations:(std::vector<CKComponentAnimation>)animations
            fromPreviousComponent:(CKComponent *const)component;
@end

@implementation CKComponentAnimationsTests_Diffing

- (void)test_WhenPreviousTreeIsEmpty_ReturnsAllComponentsWithInitialMountAnimationsAsAppeared
{
  const auto r = CKComponentScopeRootWithDefaultPredicates(nil, nil, YES);
  const auto bcr = CKBuildComponent(r, {}, ^{
    return [ComponentWithScope newWithComponent:[ComponentWithInitialMountAnimations new]];
  });
  const auto c = CK::objCForceCast<ComponentWithScope>(bcr.component);

  const auto diff = CK::animatedComponentsBetweenScopeRoots(bcr.scopeRoot, r);

  const auto expectedDiff = CK::ComponentTreeDiff {
    .appearedComponents = {c.component},
  };
  XCTAssert(diff == expectedDiff);
}

- (void)test_WhenPreviousTreeIsNotEmpty_ReturnsOnlyNewComponentsWithInitialMountAnimationsAsAppeared
{
  const auto bcr = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil, YES), {}, ^{
    return [ComponentWithScope newWithComponent:[ComponentWithInitialMountAnimations new]];
  });
  const auto bcr2 = CKBuildComponent(bcr.scopeRoot, {}, ^{
    return [ComponentWithScope newWithComponent:[ComponentWithInitialMountAnimations new]];
  });

  const auto diff = CK::animatedComponentsBetweenScopeRoots(bcr2.scopeRoot, bcr.scopeRoot);

  XCTAssert(diff == CK::ComponentTreeDiff {});
}

- (void)test_WhenPreviousTreeIsNotEmpty_ReturnsComponentsWithChangeAnimationsAsUpdated
{
  const auto bcr = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil, YES), {}, ^{
    return [ComponentWithScope newWithComponent:[ComponentWithAnimationsFromPreviousComponent new]];
  });
  const auto c = CK::objCForceCast<ComponentWithScope>(bcr.component);
  const auto bcr2 = CKBuildComponent(bcr.scopeRoot, {}, ^{
    return [ComponentWithScope newWithComponent:[ComponentWithAnimationsFromPreviousComponent new]];
  });
  const auto c2 = CK::objCForceCast<ComponentWithScope>(bcr2.component);

  const auto diff = CK::animatedComponentsBetweenScopeRoots(bcr2.scopeRoot, bcr.scopeRoot);

  const auto expectedDiff = CK::ComponentTreeDiff {
    .updatedComponents = {{c.component, c2.component}},
  };
  XCTAssert(diff == expectedDiff);
}

@end

@interface CKComponentAnimationsTests: XCTestCase
@end

@implementation CKComponentAnimationsTests

static auto animationsAreEqual(const std::vector<CKComponentAnimation> &as1,
                               const std::vector<CKComponentAnimation> &as2) -> bool
{
  if (as1.size() != as2.size()) {
    return false;
  }

  for (auto i = 0; i < as1.size(); i++) {
    if (!as1[i].isIdenticalTo(as2[i])) {
      return false;
    }
  }

  return true;
}

- (void)test_WhenThereAreNoComponentsToAnimate_ThereAreNoAnimations
{
  const auto as = CK::animationsForComponents({});

  const auto expected = std::vector<CKComponentAnimation> {};
  XCTAssert(animationsAreEqual(as.animationsOnInitialMount(), expected));
}

- (void)test_ForAllAppearedComponents_AnimationsOnInitialMountAreCollected
{
  const auto a1 = CKComponentAnimation([CKComponent new], [CAAnimation new]);
  const auto a2 = CKComponentAnimation([CKComponent new], [CAAnimation new]);
  const auto diff = CK::ComponentTreeDiff {
    .appearedComponents = {
      [ComponentWithInitialMountAnimations newWithInitialMountAnimations:{a1}],
      [ComponentWithInitialMountAnimations newWithInitialMountAnimations:{a2}],
    },
  };

  const auto as = CK::animationsForComponents(diff);

  const auto expected = std::vector<CKComponentAnimation> {a1, a2};
  XCTAssert(animationsAreEqual(as.animationsOnInitialMount(), expected));
}

- (void)test_ForAllUpdatedComponents_AnimationsFromPreviousComponentAreCollected
{
  const auto a1 = CKComponentAnimation([CKComponent new], [CAAnimation new]);
  const auto pc1 = [CKComponent new];
  const auto a2 = CKComponentAnimation([CKComponent new], [CAAnimation new]);
  const auto pc2 = [CKComponent new];
  const auto componentPairs = std::vector<CK::ComponentTreeDiff::Pair> {
    {pc1, [ComponentWithAnimationsFromPreviousComponent newWithAnimations:{a1} fromPreviousComponent:pc1]},
    {pc2, [ComponentWithAnimationsFromPreviousComponent newWithAnimations:{a2} fromPreviousComponent:pc2]},
  };
  const auto diff = CK::ComponentTreeDiff {
    .updatedComponents = componentPairs,
  };

  const auto as = CK::animationsForComponents(diff);

  const auto expected = std::vector<CKComponentAnimation> {a1, a2};
  XCTAssert(animationsAreEqual(as.animationsFromPreviousComponent(), expected));
}

@end

@implementation ComponentWithScope
+ (instancetype)newWithComponent:(CKComponent *)component
{
  CKComponentScope s(self);
  return [super newWithComponent:component];
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
