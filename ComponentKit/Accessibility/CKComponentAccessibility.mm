/*
*  Copyright (c) 2014-present, Facebook, Inc.
*  All rights reserved.
*
*  This source code is licensed under the BSD-style license found in the
*  LICENSE file in the root directory of this source tree. An additional grant
*  of patent rights can be found in the PATENTS file in the same directory.
*
*/

#import "CKComponentAccessibility.h"

#import <RenderCore/RCAssert.h>

/** Helper that converts the accessibility context characteristics to a map of component view attributes */
static CKViewComponentAttributeValueMap ViewAttributesFromAccessibilityContext(const RCAccessibilityContext &accessibilityContext)
{
  CKViewComponentAttributeValueMap accessibilityAttributes;
  if (accessibilityContext.isAccessibilityElement) {
    accessibilityAttributes[@selector(setIsAccessibilityElement:)] = accessibilityContext.isAccessibilityElement;
  }
  if (accessibilityContext.accessibilityLabel.hasText()) {
    accessibilityAttributes[@selector(setAccessibilityLabel:)] = accessibilityContext.accessibilityLabel.value();
  }
  if (accessibilityContext.accessibilityHint.hasText()) {
    accessibilityAttributes[@selector(setAccessibilityHint:)] = accessibilityContext.accessibilityHint.value();
  }
  if (accessibilityContext.accessibilityValue.hasText()) {
    accessibilityAttributes[@selector(setAccessibilityValue:)] = accessibilityContext.accessibilityValue.value();
  }
  if (accessibilityContext.accessibilityTraits) {
    accessibilityAttributes[@selector(setAccessibilityTraits:)] = accessibilityContext.accessibilityTraits;
  }
  return accessibilityAttributes;
}

CKComponentViewConfiguration CK::Component::Accessibility::AccessibleViewConfiguration(const CKComponentViewConfiguration &viewConfiguration)
{
  RCCAssertMainThread();
  // Copy is intentional so we can move later.
  RCAccessibilityContext accessibilityContext = viewConfiguration.accessibilityContext();
  const CKViewComponentAttributeValueMap &accessibilityAttributes = ViewAttributesFromAccessibilityContext(accessibilityContext);
  if (accessibilityAttributes.size() > 0) {
    CKViewComponentAttributeValueMap newAttributes(*viewConfiguration.attributes());
    newAttributes.insert(accessibilityAttributes.begin(), accessibilityAttributes.end());
    // Copy is intentional so we can move later.
    CKComponentViewClass viewClass = viewConfiguration.viewClass();
    // If the specified view class doesn't have a view, force the creation of one
    // so the accessibility attributes can be realized.
    return CKComponentViewConfiguration(viewClass.hasView() ? std::move(viewClass) : CKComponentViewClass([UIView class]),
                                        std::move(newAttributes), std::move(accessibilityContext));
  } else {
    return viewConfiguration;
  }
}

static BOOL _forceAccessibilityEnabled = NO;
static BOOL _forceAccessibilityDisabled = NO;

void CK::Component::Accessibility::SetForceAccessibilityEnabled(BOOL enabled)
{
  _forceAccessibilityEnabled = enabled;
  _forceAccessibilityDisabled = !enabled;
}

void CK::Component::Accessibility::ResetForceAccessibility()
{
  _forceAccessibilityEnabled = NO;
  _forceAccessibilityDisabled = NO;
}

BOOL CK::Component::Accessibility::IsAccessibilityEnabled()
{
  RCCAssertMainThread();
  return !_forceAccessibilityDisabled && (_forceAccessibilityEnabled || UIAccessibilityIsVoiceOverRunning());
}

NSString *const CKAccessibilityExtraActionKey = @"CKAccessibilityExtraActionKey";

id CKAccessibilityExtraActionValue(CKAction<> action)
{
  // Mostly this function exists to ensure the correct type is passed
  // (CKAction<> not CKAction<Foo>) and that the action is captured
  // by value, not by reference.
  return ^{ return action; };
}

CKAction<> CKAccessibilityActionFromExtraValue(id extraValue)
{
  CKAction<> (^block)(void) = extraValue;
  return block ? block() : CKAction<>();
}
