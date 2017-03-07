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
#import <ComponentKit/CKComponentAction.h>

/** An implementation detail class. Should not be used directly. */
class CKComponentTriggerTargetBase {
protected:
  BOOL _resolved;
  __weak CKComponentScopeHandle *_scopeHandle;
  SEL _selector;

  NSInvocation *invocation(CKComponent *sender) const;

  void resolve(void);

  CKComponentTriggerTargetBase();
  ~CKComponentTriggerTargetBase();
  void resolve(const CKComponentScope &scope, SEL selector);
  bool isValid() const;

  friend class CKComponentTriggerBase;
};

template <typename... T>
class CKTypedComponentTrigger;

template <typename... T>
class CKTypedComponentTriggerTarget : public CKComponentTriggerTargetBase {
  static_assert(std::is_same<
                CKTypedComponentActionBoolPack<(std::is_trivially_constructible<T>::value || std::is_pointer<T>::value)...>,
                CKTypedComponentActionBoolPack<(CKTypedComponentActionDenyType<T>::value)...>
                >::value, "You must either use a pointer (like an NSObject) or a trivially constructible type. Complex types are not allowed as arguments of component triggers.");

  void resolve(const CKComponentScope &scope, SEL selector)
  {
    CKComponentTriggerTargetBase::resolve(scope, selector);
#if DEBUG
    std::vector<const char *> typeEncodings;
    CKTypedComponentActionTypeVectorBuild(typeEncodings, CKTypedComponentActionTypelist<T...>{});
    _CKTypedComponentDebugCheckComponentScope(scope, selector, typeEncodings);
#endif
  }

  void invoke(CKComponent *sender, T... args)
  {
    CKCAssert(_resolved, @"Must resolve before invoking");
    if (!_resolved) {
      return;
    }
    NSInvocation *inv = invocation(sender);
    CKConfigureInvocationWithArguments(inv, 3, args...);
    [inv invoke];
  }

  friend class CKTypedComponentTrigger<T...>;
};

/** The base class for triggers. Exists to outline the constructors needed by the templated type. */
class CKComponentTriggerBase {
protected:
  std::shared_ptr<CKComponentTriggerTargetBase> _target;
  BOOL _validate;
public:
  CKComponentTriggerBase();
  CKComponentTriggerBase(std::shared_ptr<CKComponentTriggerTargetBase> ptr);
  CKComponentTriggerBase(const CKComponentTriggerBase &other);
  ~CKComponentTriggerBase();
};
