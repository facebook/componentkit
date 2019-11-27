/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentKey.h"

#import <ComponentKit/CKAssert.h>

CKComponentKey::CKComponentKey(id<NSObject> key) noexcept
: _threadLocalScope(CKThreadLocalComponentScope::currentScope()), _key(key)
{
  if (_threadLocalScope && _key) {
    _threadLocalScope->keys.top().push_back(key);
  }
}

CKComponentKey::~CKComponentKey() noexcept
{
  if (_threadLocalScope && _key) {
    CKCAssert(_threadLocalScope->keys.top().back() == _key, @"Key mismatch: %@ vs %@",
              _threadLocalScope->keys.top().back(), _key);
    _threadLocalScope->keys.top().pop_back();
  }
}
