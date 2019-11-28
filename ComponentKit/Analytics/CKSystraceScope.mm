/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKSystraceScope.h"

#import <ComponentKit/CKGlobalConfig.h>

#import "CKAnalyticsListener.h"
#import "CKComponentScopeRoot.h"
#import "CKThreadLocalComponentScope.h"

CKSystraceScope::~CKSystraceScope()
{
  if (_isAsync) {
    [_systraceListener didEndAsyncBlockTrace:_blockName];
  } else {
    [_systraceListener didEndBlockTrace:_blockName];
  }
}

CKSystraceScope::CKSystraceScope(const char *const blockName) noexcept : _blockName(blockName), _isAsync(false)
{
  auto const systraceListener = CKReadGlobalConfig().defaultAnalyticsListener.systraceListener;
  if (systraceListener)
  {
    [systraceListener willStartBlockTrace:blockName];
    _systraceListener = systraceListener;
  }
}

CKSystraceScope::CKSystraceScope(const CK::Analytics::AsyncBlock &asyncBlock) noexcept : _blockName(asyncBlock.name), _systraceListener(CKReadGlobalConfig().defaultAnalyticsListener.systraceListener), _isAsync(true)
{
  if (asyncBlock.didStartBlock != nullptr) {
    asyncBlock.didStartBlock();
  }
}
