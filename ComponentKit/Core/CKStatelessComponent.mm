/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKStatelessComponent.h"

@implementation CKStatelessComponent

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view component:(CKComponent *)component identifier:(NSString *)identifier
{
  const auto c = [super newWithView:view component:component];

  if (c) {
    c->_identifier = [identifier copy];
  }

  return c;
}

@end

CKComponent *CKCreateStatelessComponent(CKComponent *component, NSString *debugIdentifier)
{
#if CK_ASSERTIONS_ENABLED
  return [CKStatelessComponent newWithView:{} component:component identifier:debugIdentifier];
#else
  return component;
#endif
}
