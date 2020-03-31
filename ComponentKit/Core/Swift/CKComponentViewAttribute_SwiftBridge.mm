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
#import <ComponentKit/CKDelayedInitialisationWrapper.h>

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

@end
