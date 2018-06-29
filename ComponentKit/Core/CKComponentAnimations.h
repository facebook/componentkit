/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <Foundation/Foundation.h>

#import <unordered_map>

#import <ComponentKit/CKComponentAnimation.h>
#import <ComponentKit/CKComponentTreeDiff.h>
#import <ComponentKit/CKEqualityHashHelpers.h>

@class CKComponentScopeRoot;

struct CKComponentAnimations {
  using AnimationsByComponentMap = std::unordered_map<CKComponent *, std::vector<CKComponentAnimation>, CK::hash<CKComponent *>, CK::is_equal<CKComponent *>>;

  CKComponentAnimations() {}
  CKComponentAnimations(AnimationsByComponentMap animationsOnInitialMount,
                        AnimationsByComponentMap animationsFromPreviousComponent)
  : _animationsOnInitialMount(std::move(animationsOnInitialMount)), _animationsFromPreviousComponent(std::move(animationsFromPreviousComponent)) {}

  const auto &animationsOnInitialMount() const { return _animationsOnInitialMount; }
  const auto &animationsFromPreviousComponent() const { return _animationsFromPreviousComponent; }
  auto isEmpty() const { return _animationsOnInitialMount.empty() && _animationsFromPreviousComponent.empty(); }

private:
  AnimationsByComponentMap _animationsOnInitialMount = {};
  AnimationsByComponentMap _animationsFromPreviousComponent = {};
};

namespace CK {
  auto animatedComponentsBetweenScopeRoots(CKComponentScopeRoot *const newRoot,
                                           CKComponentScopeRoot *const previousRoot) -> ComponentTreeDiff;

  auto animationsForComponents(const ComponentTreeDiff& animatedComponents) -> CKComponentAnimations;
}
