/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKDefines.h>

#if CK_NOT_SWIFT

#import <Foundation/Foundation.h>

#import <unordered_map>

#import <ComponentKit/CKComponentAnimation.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentTreeDiff.h>
#import <ComponentKit/CKEqualityHelpers.h>

@class CKComponentScopeRoot;

struct CKComponentAnimations {
  using AnimationsByComponentMap = std::unordered_map<CKComponent *, std::vector<CKComponentAnimation>, CK::hash<CKComponent *>, CK::is_equal<CKComponent *>>;

  CKComponentAnimations() {}
  CKComponentAnimations(AnimationsByComponentMap animationsOnInitialMount,
                        AnimationsByComponentMap animationsFromPreviousComponent,
                        AnimationsByComponentMap animationsOnFinalUnmount):
  _animationsOnInitialMount(std::move(animationsOnInitialMount)),
  _animationsFromPreviousComponent(std::move(animationsFromPreviousComponent)),
  _animationsOnFinalUnmount(std::move(animationsOnFinalUnmount)) {}

  const auto &animationsOnInitialMount() const { return _animationsOnInitialMount; }
  const auto &animationsFromPreviousComponent() const { return _animationsFromPreviousComponent; }
  const auto &animationsOnFinalUnmount() const { return _animationsOnFinalUnmount; }
  auto isEmpty() const
  {
    return
    _animationsOnInitialMount.empty() &&
    _animationsFromPreviousComponent.empty() &&
    _animationsOnFinalUnmount.empty();
  }
  auto description() const -> NSString *;

private:
  AnimationsByComponentMap _animationsOnInitialMount = {};
  AnimationsByComponentMap _animationsFromPreviousComponent = {};
  AnimationsByComponentMap _animationsOnFinalUnmount = {};
};

namespace CK {
  auto animatedComponentsBetweenLayouts(const CKComponentRootLayout &newLayout,
                                        const CKComponentRootLayout &previousLayout) -> ComponentTreeDiff;

  auto animationsForComponents(const ComponentTreeDiff& animatedComponents, UIView *const hostView) -> CKComponentAnimations;
}

#endif
