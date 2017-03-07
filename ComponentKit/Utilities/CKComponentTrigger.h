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

#import <ComponentKit/CKComponentTriggerInternal.h>

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
 
     + (instancetype)newWithTrigger:(const CKTypedComponentTrigger<BOOL> &)someTrigger
     {
       CKComponentScope scope(self);
       someTrigger.resolve(scope, @selector(someMethodWithSender:booleanParameter:));
       return [super new...];
     }
 
 Component triggers must be resolved with a component scope. This allows a CKComponent to register itself or its
 controller with the trigger. If the selector is not implemented on the component itself, it will be invoked on the 
 controller associated with that component. At runtime in DEBUG mode the trigger will validate that your component or 
 controller implements the selector, and that the parameter types match.

       CKComponentScope scope(self);
       someTriggerHandle.resolve(scope, @selector(someMethodWithSender:booleanParameter:));
 
 Triggers are created in parent scopes through CKComponentTriggerAcquire<T...>.

     + (instancetype)new
     {
       CKTypedComponentTrigger<BOOL> trigger = CKComponentTriggerAcquire<BOOL>();
       FooComponent *c = [super newWithComponent:
                          [BarComponent
                           newWithTrigger:trigger]];
       if (c) {
         c->_trigger = trigger;
       }
       return c;
     }
   
     - (void)invokeTrigger
     {
       _trigger->invoke(self, YES);
     }
 */

template <typename... T>
class CKTypedComponentTrigger : public CKComponentTriggerBase {
  CKTypedComponentTriggerTarget<T...> *get() const {
    return static_cast<CKTypedComponentTriggerTarget<T...> *>(_target.get());
  }
public:
  using CKComponentTriggerBase::CKComponentTriggerBase;

  void resolve(const CKComponentScope &scope, SEL selector) const
  {
    if (_target != nullptr) {
      get()->resolve(scope, selector);
    }
  }

  void invoke(CKComponent *sender, T... args) const
  {
    if (_target != nullptr) {
      get()->invoke(sender, args...);
    }
  }
};

template <typename... T>
CKTypedComponentTrigger<T...> CKComponentTriggerAcquire()
{
  return CKTypedComponentTrigger<T...>(std::static_pointer_cast<CKComponentTriggerTargetBase>(std::make_shared<CKTypedComponentTriggerTarget<T...>>()));
}

/** Convenience typedefs for triggers that have no arguments. */
typedef CKTypedComponentTrigger<> CKComponentTrigger;

extern template class CKTypedComponentTrigger<>;
extern template class CKTypedComponentTrigger<id>;
