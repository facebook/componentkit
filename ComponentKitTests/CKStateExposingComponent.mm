/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKStateExposingComponent.h"

#import <ComponentKit/CKComponentScope.h>

@implementation CKStateExposingComponent
+ (id)initialState
{
  return @12345;
}
+ (instancetype)new
{
  CKComponentScope scope(self);
  CKStateExposingComponent *c = [super newWithView:{} size:{}];
  if (c) {
    c->_state = scope.state();
  }
  return c;
}
@end
