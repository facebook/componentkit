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

#import "CKAnalyticsListener.h"
#import "CKComponentScopeRoot.h"
#import "CKGlobalConfig.h"
#import "CKThreadLocalComponentScope.h"

CKSystraceScope::~CKSystraceScope()
{
  [_systraceListener didEndBlockTrace:_blockName];
}

CKSystraceScope::CKSystraceScope(const char *const blockName) noexcept : _blockName(blockName)
{
  auto const systraceListener = CKReadGlobalConfig().defaultAnalyticsListener.systraceListener;
  if (systraceListener)
  {
    [systraceListener willStartBlockTrace:blockName];
    _systraceListener = systraceListener;
  }
}
