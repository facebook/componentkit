/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentTrigger.h"

#import "CKAssert.h"
#import "CKComponentActionInternal.h"
#import "CKComponentScopeHandle.h"

CKComponentTriggerBase::CKComponentTriggerBase() : _resolved(NO), _target(nil), _scopeHandle(nil), _selector(NULL) {}
CKComponentTriggerBase::~CKComponentTriggerBase() {
  CKCAssert(_resolved, @"Triggers must be resolved before destruction");
}

void CKComponentTriggerBase::resolve(const CKComponentScope &scope, SEL selector)
{
  CKCAssert(!_resolved, @"Triggers may be resolved once, and only once");
  _resolved = YES;
  _scopeHandle = scope.scopeHandle();
  _selector = selector;
}

void CKComponentTriggerBase::resolve(id target, SEL selector)
{
  CKCAssert(!_resolved, @"Triggers may be resolved once, and only once");
  _resolved = YES;
  _target = target;
  _selector = selector;
}

void CKComponentTriggerBase::resolve(void)
{
  CKCAssert(!_resolved, @"Triggers may be resolved once, and only once");
  _resolved = YES;
}

CKComponentTriggerBase::operator bool() const
{
  return _resolved && _selector != nil && (_target || _scopeHandle);
};

NSInvocation *CKComponentTriggerBase::invocation(CKComponent *sender) const
{
  return CKComponentActionSendResponderInvocationPrepare(_selector, _target ?: _scopeHandle.responder, sender);
}
