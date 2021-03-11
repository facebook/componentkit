/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKCompositeComponent.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Factory function that creates an array of UIAccessibilityElement's given
 * the container view. The view is mounted in the hierarchy when the factory
 * function is called.
 */
typedef NSArray<UIAccessibilityElement *> * _Nonnull (^CKAccessibilityElementsFactory)(
  UIView * _Nonnull containerView);

/**
 * Creates a wrapper component which always mounts an accessibility
 * container view which exposes an array of `accessibilityElements`.
 * The view is not an accessibility element by itself.
 *
 * Unlike using `.accessibilityAggregateAttributes()` Builder attribute,
 * this class allows call sites to completetely control how accessibility
 * elements are created via the provided factory function.
 */
CKComponent *CKAccessibilityContainerComponentWrapper(
  CKComponent * _Nullable component,
  CKAccessibilityElementsFactory factory);

NS_ASSUME_NONNULL_END
