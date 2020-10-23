/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKComponentViewAttribute_SwiftBridge.h>
#import <ComponentKit/CKComponentViewAttribute_SwiftBridge+Internal.h>

#import <ComponentKit/CKCasting.h>
#import <ComponentKit/CKComponentGestureActions.h>
#import <ComponentKit/CKDelayedInitialisationWrapper.h>
#import <ComponentKit/CKAction_SwiftBridge+Internal.h>

@implementation CKComponentViewAttribute_SwiftBridge {
  CK::DelayedInitialisationWrapper<CKComponentViewAttribute> _viewAttribute;
}

- (instancetype)initWithViewAttribute:(const CKComponentViewAttribute &)viewAttribute
{
  if (self = [super init]) {
    _viewAttribute = viewAttribute;
  }
  return self;
}

- (instancetype)initWithIdentifier:(NSString *)identifier applicator:(void(^)(UIView *))applicator
{
  return [self initWithViewAttribute:{identifier.UTF8String, ^(id view, id){ applicator(view); }}];
}

- (const CKComponentViewAttribute &)viewAttribute
{
  return _viewAttribute;
}

- (BOOL)isEqual:(id)other
{
  if (other == nil) {
    return NO;
  }

  if (other == self) {
    return YES;
  }

  if (![other isKindOfClass:[CKComponentViewAttribute_SwiftBridge class]]) {
    return NO;
  }

  const CKComponentViewAttribute &lhs = _viewAttribute;
  const CKComponentViewAttribute &rhs = CK::objCForceCast<CKComponentViewAttribute_SwiftBridge>(other)->_viewAttribute;
  return lhs == rhs;
}

- (NSUInteger)hash
{
  return std::hash<CKComponentViewAttribute>{}(_viewAttribute);
}

#pragma mark - Gestures

typedef CKComponentViewAttributeValue (*CKComponentViewAttributeValueGestureProvider)(CKAction<UIGestureRecognizer *>);
static CKComponentViewAttributeValueGestureProvider providerFromGesture(CKComponentViewAttributeGesture_SwiftBridge gesture) {
  switch (gesture) {
    case CKComponentViewAttributeGesture_SwiftBridgeTap:
      return &CKComponentTapGestureAttribute;
    case CKComponentViewAttributeGesture_SwiftBridgePan:
      return &CKComponentPanGestureAttribute;
    case CKComponentViewAttributeGesture_SwiftBridgeLongPress:
      return &CKComponentLongPressGestureAttribute;
  }
}

- (instancetype)initWithGesture:(CKComponentViewAttributeGesture_SwiftBridge)gesture swiftAction:(CKActionWithId_SwiftBridge)swiftAction
{
  const auto provider = providerFromGesture(gesture);
  return [self initWithViewAttribute:provider(CKSwiftActionUnsafeBridgeToObjectiveC<UIGestureRecognizer *>(swiftAction)).first];
}

@end

auto CKComponentViewAttribute_SwiftBridgeToMap(NSArray<CKComponentViewAttribute_SwiftBridge *> *swiftAttributes) -> CKViewComponentAttributeValueMap
{
  auto attrMap = CKViewComponentAttributeValueMap{};
  attrMap.reserve(swiftAttributes.count);
  for (CKComponentViewAttribute_SwiftBridge *swiftAttribute in swiftAttributes) {
    attrMap.insert({
      swiftAttribute.viewAttribute,
      @YES // Bogus value, not actually used
    });
  }
  return attrMap;
}
