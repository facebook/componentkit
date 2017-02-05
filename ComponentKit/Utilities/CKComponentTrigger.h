/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <Foundation/Foundation.h>

#import <memory>

#import <ComponentKit/CKComponentScope.h>
#import <ComponentKit/CKComponentActionInternal.h>

class CKComponentTriggerBase {
protected:
  BOOL _resolved;
  __weak id _target;
  __weak CKComponentScopeHandle *_scopeHandle;
  SEL _selector;

  NSInvocation *invocation(CKComponent *sender) const;
public:
  CKComponentTriggerBase();
  ~CKComponentTriggerBase();
  void resolve(const CKComponentScope &scope, SEL selector);
  void resolve(id target, SEL selector);
  void resolve(void);
  explicit operator bool() const;
};

template <typename... T>
class CKComponentTrigger : CKComponentTriggerBase {
public:
#if DEBUG
  void resolve(const CKComponentScope &scope, SEL selector)
  {
    CKComponentTriggerBase::resolve(scope, selector);
    std::vector<const char *> typeEncodings;
    CKTypedComponentActionTypeVectorBuild(typeEncodings, CKTypedComponentActionTypelist<T...>{});
    _CKTypedComponentDebugCheckComponentScope(scope, selector, typeEncodings);
  }
  void resolve(id target, SEL selector)
  {
    CKComponentTriggerBase::resolve(target, selector);
    std::vector<const char *> typeEncodings;
    CKTypedComponentActionTypeVectorBuild(typeEncodings, CKTypedComponentActionTypelist<T...>{});
    _CKTypedComponentDebugCheckTargetSelector(target, selector, typeEncodings);
  }
#endif

  void trigger(CKComponent *sender, T... args)
  {
    CKCAssert(_resolved, @"Must resolve before triggering");
    if (!_resolved) {
      return;
    }
    NSInvocation *inv = invocation(sender);
    CKConfigureInvocationWithArguments(inv, 3, args...);
    [inv invoke];
  }
};

template <typename... T>
class CKComponentTriggerHandle {
  std::shared_ptr<CKComponentTrigger<T...>> _trigger;
public:
  CKComponentTriggerHandle<T...>() : _trigger(nullptr) {};
  CKComponentTriggerHandle<T...>(std::shared_ptr<CKComponentTrigger<T...>> ptr) : _trigger(ptr) {};

  static CKComponentTriggerHandle<T...> acquire()
  {
    return CKComponentTriggerHandle<T...>(std::make_shared<CKComponentTrigger<T...>>());
  }

  explicit operator bool() const { return _trigger != nullptr; };
  CKComponentTrigger<T...> *operator->() const {
    return _trigger.get();
  }
};
