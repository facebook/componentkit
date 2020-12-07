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

inline auto systraceListenerFromTLS() {
  auto const threadLocalScope = CKThreadLocalComponentScope::currentScope();
  return threadLocalScope != nullptr ? threadLocalScope->systraceListener : nil;
}

CKComponentPerfScope::~CKComponentPerfScope()
{
  [_systraceListener didBuildComponent:_componentTypeName];
}

CKComponentPerfScope::CKComponentPerfScope(id<CKSystraceListener> systraceListener, const char *componentTypeName) noexcept
  : _systraceListener(systraceListener), _componentTypeName(componentTypeName)
{
  [systraceListener willBuildComponent:_componentTypeName];
}

CKComponentPerfScope::CKComponentPerfScope(Class __unsafe_unretained componentClass) noexcept
 : CKComponentPerfScope(systraceListenerFromTLS(), class_getName(componentClass)) { }
