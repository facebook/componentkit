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

#import <ComponentKit/CKComponentAnimation.h>
#import <ComponentKit/CKComponentTreeDiff.h>

@class CKComponentScopeRoot;

struct CKComponentAnimations {
  CKComponentAnimations() {}
  CKComponentAnimations(std::vector<CKComponentAnimation> animationsOnInitialMount,
                        std::vector<CKComponentAnimation> animationsFromPreviousComponent)
  : _animationsOnInitialMount(std::move(animationsOnInitialMount)), _animationsFromPreviousComponent(std::move(animationsFromPreviousComponent))
  {}

  const auto &animationsOnInitialMount() const { return _animationsOnInitialMount; }
  const auto &animationsFromPreviousComponent() const { return _animationsFromPreviousComponent; }

private:
  std::vector<CKComponentAnimation> _animationsOnInitialMount = {};
  std::vector<CKComponentAnimation> _animationsFromPreviousComponent = {};
};

namespace CK {
  auto animatedComponentsBetweenScopeRoots(CKComponentScopeRoot *const newRoot,
                                           CKComponentScopeRoot *const previousRoot) -> ComponentTreeDiff;

  auto animationsForComponents(const ComponentTreeDiff& animatedComponents) -> CKComponentAnimations;
}
