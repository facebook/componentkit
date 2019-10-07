/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKTransitions.h"

#import <ComponentKit/CKComponent.h>
#import "CKAnimationComponent+Internal.h"

template <typename T>
static CAAnimation *toCA(const CK::Optional<T>& a) {
  return a.mapToPtr([](const T& a) { return a.toCA(); });
}

auto CKTransitions::areEmpty() const -> bool {
  return onInitialMount.hasValue() == false && onFinalUnmount.hasValue() == false;
}

CKComponent *CKComponentWithTransitions(CKComponent *component, const CKTransitions& transitions) {
  // Wrap in CKAnimationComponent if needed.
  if (transitions.areEmpty() || component == nil) {
    return component;
  } else {
    return [CKAnimationComponent newWithComponent:component
                          animationOnInitialMount:toCA(transitions.onInitialMount)
                          animationOnFinalUnmount:toCA(transitions.onFinalUnmount)];
  }
}
