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

#import <ComponentKit/CKAction.h>

typedef NSString *(^CKAccessibilityLazyTextBlock)();

/**
 A text attribute used for accessibility, this attribute can be initialized in two ways :
 - If some computation needs to be done like aggregation or other string manipulations you can provide a block that
   will be lazily executed when the component is mounted only when voiceover is enabled, this way we don't do
   unnecessary computations when VoiceOver is not enabled.
 - Use an NSString directly; reserve this for when no computation is needed to get the string
 */
struct CKComponentAccessibilityTextAttribute {
  CKComponentAccessibilityTextAttribute() {};
  CKComponentAccessibilityTextAttribute(CKAccessibilityLazyTextBlock textBlock) : accessibilityLazyTextBlock(textBlock) {};
  CKComponentAccessibilityTextAttribute(NSString *text) : accessibilityLazyTextBlock(text ? ^{ return text; } : (CKAccessibilityLazyTextBlock)nil) {};

  BOOL hasText() const {
    return accessibilityLazyTextBlock != nil;
  }

  NSString *value() const {
    return accessibilityLazyTextBlock ? accessibilityLazyTextBlock() : nil;
  };

private:
  CKAccessibilityLazyTextBlock accessibilityLazyTextBlock;
};

/**
 Holds values that are only applied to a view if VoiceOver is enabled.

 The accessibility identifier is often used by end-to-end tests even
 when VoiceOver is disabled, so it is not set here. To set the
 accessibility identifier, pass it as a normal view attribute:

 ```
 {@selector(setAccessibilityIdentifier:), @"accessibilityId"}
 ```
 */
struct CKComponentAccessibilityContext {
  NSNumber *isAccessibilityElement;
  CKComponentAccessibilityTextAttribute accessibilityLabel;
  CKComponentAccessibilityTextAttribute accessibilityHint;
  CKComponentAccessibilityTextAttribute accessibilityValue;
  NSNumber *accessibilityTraits;
  CKAction<> accessibilityComponentAction;
  /**
   Arbitrary extra data about accessibility. ComponentKit ignores this data,
   but you may use it for accessibility-related abstractions.
   */
  NSDictionary *extra;

  BOOL isEmpty() const {
    return isAccessibilityElement == nil
        && !accessibilityLabel.hasText()
        && !accessibilityHint.hasText()
        && !accessibilityValue.hasText()
        && accessibilityTraits == nil
        && !accessibilityComponentAction
        && extra == nil;
  }
};

#endif
