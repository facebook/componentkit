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
@end

@interface ComponentWithAnimationsFromPreviousComponent: CKComponent
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

@implementation ComponentWithScope
+ (instancetype)newWithComponent:(CKComponent *)component
{
  CKComponentScope s(self);
  return [super newWithComponent:component];
}
@end

@implementation ComponentWithInitialMountAnimations
+ (instancetype)new
{
  CKComponentScope s(self);
  return [super new];
}

- (std::vector<CKComponentAnimation>)animationsOnInitialMount { return {}; }
@end

@implementation ComponentWithAnimationsFromPreviousComponent
+ (instancetype)new
{
  CKComponentScope s(self);
  return [super new];
}

- (std::vector<CKComponentAnimation>)animationsFromPreviousComponent:(CKComponent *)previousComponent { return {}; }
@end
