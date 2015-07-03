/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKTestActionComponent.h"

@implementation CKTestActionComponent
{
  void (^_block)(CKComponent *, id);
}

+ (instancetype)newWithBlock:(void (^)(CKComponent *sender, id context))block component:(CKComponent *)component
{
  CKTestActionComponent *c = [super newWithComponent:component];
  if (c) {
    c->_block = block;
  }
  return c;
}

- (void)testAction:(CKComponent *)sender context:(id)context
{
  _block(sender, context);
}

@end
