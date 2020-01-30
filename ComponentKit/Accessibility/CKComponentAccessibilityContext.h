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
  CKComponentAccessibilityTextAttribute(NSString *text) : accessibilityLazyTextBlock(^{ return text; }) {};

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
 Separate structure to handle accessibility as we want the components infrastructure to decide wether to use it or not depending if accessibility is enabled or not.
 Not to be confused with accessibilityIdentifier which is used for automation to identify elements on the screen. To set the identifier pass in {@selector(setAccessibilityIdentifier:), @"accessibilityId"} with the viewConfiguration's attributes
 */
struct CKComponentAccessibilityContext {
  NSNumber *isAccessibilityElement;
  CKComponentAccessibilityTextAttribute accessibilityLabel;
  CKComponentAccessibilityTextAttribute accessibilityHint;
  CKComponentAccessibilityTextAttribute accessibilityValue;
  NSNumber *accessibilityTraits;
  CKAction<> accessibilityComponentAction;

  bool operator==(const CKComponentAccessibilityContext &other) const
  {
    return CKObjectIsEqual(other.isAccessibilityElement, isAccessibilityElement)
    && CKObjectIsEqual(other.accessibilityLabel.value(), accessibilityLabel.value())
    && CKObjectIsEqual(other.accessibilityHint.value(), accessibilityHint.value())
    && CKObjectIsEqual(other.accessibilityValue.value(), accessibilityValue.value())
    && CKObjectIsEqual(other.accessibilityTraits, accessibilityTraits)
    && other.accessibilityComponentAction == accessibilityComponentAction;
  }
};

#endif
