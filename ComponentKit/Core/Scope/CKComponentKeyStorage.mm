/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentKeyStorage.h"

#import "CKComponentContext.h"

@implementation CKComponentKeyStorage

+ (instancetype)newWithAdditionalKey:(id)key
{
  CKComponentKeyStorage *const current = CKComponentContext<CKComponentKeyStorage>::get();
  if (key == nil) {
    return current;
  }

  CKComponentKeyStorage *const updated = [CKComponentKeyStorage new];
  if (updated) {
    updated->_keys = [current.keys ?: @[] arrayByAddingObject:key];
  }
  return updated;
}

+ (NSArray<id> *)currentKeys
{
  return CKComponentContext<CKComponentKeyStorage>::get().keys ?: @[];
}

@end
