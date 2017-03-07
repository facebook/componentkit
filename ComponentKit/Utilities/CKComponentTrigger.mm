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

CKComponentTriggerTargetBase::CKComponentTriggerTargetBase() : _resolved(NO), _scopeHandle(nil), _selector(NULL) {}
CKComponentTriggerTargetBase::~CKComponentTriggerTargetBase() {
  CKCAssert(_resolved, @"Triggers must be resolved before destruction");
}

void CKComponentTriggerTargetBase::resolve(void)
{
  CKCAssert(!_resolved, @"Triggers may be resolved once, and only once");
  _resolved = YES;
}

void CKComponentTriggerTargetBase::resolve(const CKComponentScope &scope, SEL selector)
{
  resolve();
  _scopeHandle = scope.scopeHandle();
  _selector = selector;
}

bool CKComponentTriggerTargetBase::isValid() const
{
  return _resolved && _selector != nil && _scopeHandle;
};

NSInvocation *CKComponentTriggerTargetBase::invocation(CKComponent *sender) const
{
  return CKComponentActionSendResponderInvocationPrepare(_selector, _scopeHandle.responder, sender);
}

CKComponentTriggerBase::CKComponentTriggerBase() : _target(nullptr), _validate(NO) {}

CKComponentTriggerBase::CKComponentTriggerBase(std::shared_ptr<CKComponentTriggerTargetBase> ptr) : _target(ptr), _validate(YES) {}

CKComponentTriggerBase::CKComponentTriggerBase(const CKComponentTriggerBase &other) : _target(other._target), _validate(NO) {}

CKComponentTriggerBase::~CKComponentTriggerBase()
{
  CKCAssert(!_validate || (_target != nullptr && _target->isValid()), @"Trigger was not resolved");
}

#pragma mark - Template instantiations

template class CKTypedComponentTrigger<>;
template class CKTypedComponentTrigger<id>;
