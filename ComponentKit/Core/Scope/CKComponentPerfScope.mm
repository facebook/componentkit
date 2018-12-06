/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentPerfScope.h"

#import "CKAnalyticsListener.h"
#import "CKComponentScopeRoot.h"
#import "CKThreadLocalComponentScope.h"

CKComponentPerfScope::~CKComponentPerfScope()
{
  if (_analyticsListener) {
    [_analyticsListener didBuildComponent:_componentClass];
  }
}

CKComponentPerfScope::CKComponentPerfScope(Class __unsafe_unretained componentClass) noexcept
{
  auto const threadLocalScope = CKThreadLocalComponentScope::currentScope();

  if (threadLocalScope != nullptr && threadLocalScope->enableLogging) {
    auto const analyticsListener = [threadLocalScope->newScopeRoot analyticsListener];
    if (analyticsListener)
    {
      [analyticsListener willBuildComponent:componentClass];
      _analyticsListener = analyticsListener;
      _componentClass = componentClass;
    }
  }
}
