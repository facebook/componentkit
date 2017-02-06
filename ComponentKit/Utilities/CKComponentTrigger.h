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

/**
 A component trigger is the opposite of an action. It is used by a parent component to trigger some side effect in a
 child component.
 
 Similar to an action, it is created in a parent scope, and is threaded down to a child component. Unlike an action
 though, triggers activate **downward** from a parent component onto a child. Actions are triggered by a child, and
 cause side-effects in parent components.
 
 Triggers are an alternative to manually exposing methods on parent components that invoke on child components. Instead
 triggers can be passed through many layers of components.
 
 Triggers use the same pattern as component actions to allow parameters to be passed to targets. The first argument to
 a trigger selector will always be the sender of the trigger invocation, the next arguments types are determined by
 the variadic template types. This allows passing of data down to the trigger invocation method.
 
 Triggers passed into a component **must** be resolved once, and only once. Resolution assigns a target and selector
 with the trigger for invocation. Here's an example:
 
     + (instancetype)newWithTriggerHandle:(CKTypedComponentTriggerHandle<BOOL>)someTriggerHandle
     {
       CKComponentScope scope(self);
       if (someTriggerHandle) {
         someTriggerHandle.resolve(scope, @selector(someMethodWithSender:booleanParameter:));
       }
       return [super new...];
     }
 
 Component triggers may be resolved in three different ways:
 
   1. (Preferred) Scope resolution. Allows a CKComponent to register itself or its controller with the trigger.
      If the selector is not implemented on the component itself, it will be invoked on the controller associated with
      that component. At runtime in DEBUG mode the trigger will validate that your component or controller implements
      the selector, and that the parameter types match.
 
       CKComponentScope scope(self);
       someTriggerHandle.resolve(scope, @selector(someMethodWithSender:booleanParameter:));

   2. (Discouraged) Target resolution. Allows an arbitrary object to receive a trigger invocation. This object is weakly
      held by the trigger.
 
       Foo *foo = ...;
       someTriggerHandle.resolve(foo, @selector(someMethodWithSender:booleanParameter:));
 
   3. No-op resolution. Since triggers *must* be resolved, this allows a component to resolve the trigger with no
      target. This means when the trigger is invoked, nothing will be called.
 
 Triggers are created in parent scopes through acquiring a CKTypedComponentTriggerHandle.

     + (instancetype)new
     {
       CKTypedComponentTriggerHandle<BOOL> handle = CKTypedComponentTriggerHandle<BOOL>::acquire();
       FooComponent *c = [super newWithComponent:
                          [BarComponent
                           newWithTriggerHandle:handle]];
       if (c) {
         c->_handle = handle;
       }
       return c;
     }
   
     - (void)activateTrigger
     {
       _handle->invoke(self, YES);
     }
 */

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
class CKTypedComponentTrigger : public CKComponentTriggerBase {
  static_assert(std::is_same<
                CKTypedComponentActionBoolPack<(std::is_trivially_constructible<T>::value || std::is_pointer<T>::value)...>,
                CKTypedComponentActionBoolPack<(CKTypedComponentActionDenyType<T>::value)...>
                >::value, "You must either use a pointer (like an NSObject) or a trivially constructible type. Complex types are not allowed as arguments of component triggers.");
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

  void invoke(CKComponent *sender, T... args)
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
class CKTypedComponentTriggerHandle {
  std::shared_ptr<CKTypedComponentTrigger<T...>> _trigger;
  BOOL _validate;
public:
  CKTypedComponentTriggerHandle<T...>() : _trigger(nullptr), _validate(NO) {};
  CKTypedComponentTriggerHandle<T...>(std::shared_ptr<CKTypedComponentTrigger<T...>> ptr) : _trigger(ptr), _validate(YES) {};
  CKTypedComponentTriggerHandle<T...>(const CKTypedComponentTriggerHandle<T...> &other) : _trigger(other._trigger), _validate(NO) {};
  ~CKTypedComponentTriggerHandle<T...>() {
#if DEBUG
    if (_validate) {
      CKCAssert(_trigger != nullptr && (BOOL)*_trigger, @"Trigger was not resolved");
    }
#endif
  }

  static CKTypedComponentTriggerHandle<T...> acquire()
  {
    return CKTypedComponentTriggerHandle<T...>(std::make_shared<CKTypedComponentTrigger<T...>>());
  }

  explicit operator bool() const { return _trigger != nullptr; };
  CKTypedComponentTrigger<T...> *operator->() const {
    return _trigger.get();
  }
};

/** Convenience typedefs for triggers that have no arguments. */
typedef CKTypedComponentTrigger<> CKComponentTrigger;
typedef CKTypedComponentTriggerHandle<> CKComponentTriggerHandle;

extern template class CKTypedComponentTrigger<>;
extern template class CKTypedComponentTrigger<id>;
