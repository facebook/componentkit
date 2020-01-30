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

#import <ComponentKit/CKAnimation.h>

@class CKComponent;

/**
 Holds the initialMount/finalUnmount animations for a component.
 */
struct CKTransitions {
  CK::Optional<CK::Animation::Initial> onInitialMount;
  CK::Optional<CK::Animation::Final> onFinalUnmount;

  /** Returns true if no animations are present. */
  auto areEmpty() const -> bool;
};

/**
 Conditionally wraps the component in an animation component.

 @param component The component to wrap.
 @param transitions The animations to apply to the component.
 */
CKComponent *CKComponentWithTransitions(CKComponent *component, const CKTransitions& transitions);

#endif
