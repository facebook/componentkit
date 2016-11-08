/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <UIKit/UIKit.h>

#import <ComponentKit/CKComponentViewAttribute.h>
#import <ComponentKit/CKComponentActionInternal.h>

@class CKComponent;

typedef NS_ENUM(NSUInteger, CKComponentActionSendBehavior) {
  /** Starts searching at the sender's next responder. Usually this is what you want to prevent infinite loops. */
  CKComponentActionSendBehaviorStartAtSenderNextResponder,
  /** If the sender itself responds to the action, invoke the action on the sender. */
  CKComponentActionSendBehaviorStartAtSender,
};

/**
 CKTypedComponentAction is a struct that represents a method invocation that can be passed to a child component to
 trigger a method invocation on a target.
 
 We allow a typed specification of the parameters that will be provided as arguments to the component action at runtime
 through the variadic templated arguments. You may specify an arbitrary number of arguments to your component action,
 and you may use either object, or primitive arguments. You should not use C++ references as arguments because the block
 API will likely result in corrupted memory access. Pass C++ structs by value as arguments to action sending.

 Methods will always be provided the sender as the first argument.
 
 Usage in your component header:
 
 @interface MyComponent : CKComponent
 + (instancetype)newWithAction:(const CKTypedComponentAction<NSString *, int> &)action;
 @end
 
 When creating the action:
 
 Option 1 - Promoted raw-selector component action. Uses a raw selector which traverses upwards looking for a parent
            that implements methodWithNoArguments, and calls that method without any arguments. The component responder
            chain is only present while the component is mounted, so you should use a target/selector action or a
            scope action if your action will be fired either before or after your component is mounted. We support
            actions which accept fewer arguments than defined in the declaration of the action above. However, types of
            received parameters should be the same as the declaration, if they're present.

 [MyComponent newWithAction:{@selector(methodWithNoArguments)}];
 ...
 - (void)methodWithNoArguments {}

 
 Option 2 - Exact raw-selector component action. Uses a raw selector which also traverses upwards using the responder
            chain, but accepts the arguments defined in the interface.

 [MyComponent newWithAction:{@selector(methodWithSender:string:integer:)}];
 ...
 - (void)methodWithSender:(CKComponent *)sender string:(NSString *)string integer:(int)integer {}

 
 Option 3 - Target/selector action. Ensures that the target responds to the given selector. Target must directly
            respond to the selector. Targets are captured weakly by the action. Promotion, as in option 2 above is also
            supported for target/selector actions. This constructor is useful for triggering actions on objects outside
            of the component hierarchy like view controllers. Does not depend on the mount-based responder chain to
            call on the target.
 
 [MyComponent newWithAction:{[SomeObject sharedInstance], @selector(methodWithNoArguments)}];
 ...
 on SomeObject: - (void)methodWithNoArguments {}
 

 Option 4 - Scope action. Similar to target/selector action in that it skips the responder chain from the sender, and
            directly invokes the selector on the component or controller corresponding with the scope. Promotion is also
            supported for scope-based actions. Scope actions weakly capture the component or controller. Does not
            depend on the mount-based responder chain to call on the component or controller. Action may be implemented
            on either component or controller.
 
 + (instancetype)new
 {
    CKComponentScope scope(self);
    return [super
            newWithComponent:
             [MyComponent 
              newWithAction:{scope, @selector(methodWithNoArguments)}]];
 }
 - (void)methodWithNoArguments {}
 */
template<typename... T>
struct CKTypedComponentAction {
  CKTypedComponentAction<T...>() : _variant(_CKTypedComponentActionVariantRawSelector), _target(nil), _selector(NULL) {};
  CKTypedComponentAction<T...>(id target, SEL selector) : _variant(_CKTypedComponentActionVariantTargetSelector), _target(target), _selector(selector)
  {
#if DEBUG
    std::vector<const char *> typeEncodings;
    _CKTypedComponentActionTypeVectorBuild(typeEncodings, _CKTypedComponentActionTypelist<T...>{});
    _CKTypedComponentDebugCheckTargetSelector(target, selector, typeEncodings);
#endif
  }

  CKTypedComponentAction<T...>(const CKComponentScope &scope, SEL selector) : _variant(_CKTypedComponentActionVariantComponentScope), _target(nil), _selector(selector), _scopeHandle(scope.scopeHandle())
  {
#if DEBUG
    std::vector<const char *> typeEncodings;
    _CKTypedComponentActionTypeVectorBuild(typeEncodings, _CKTypedComponentActionTypelist<T...>{});
    _CKTypedComponentDebugCheckComponentScope(scope, selector, typeEncodings);
#endif
  }
  
  /** Legacy constructor for raw selector actions. Traverse up the mount responder chain. */
  CKTypedComponentAction(SEL selector) : _variant(_CKTypedComponentActionVariantRawSelector), _target(nil), _selector(selector) { };

  /** We support promotion from actions that take no arguments. */
  template <typename T1, typename... Ts>
  CKTypedComponentAction<T1, Ts...>(const CKTypedComponentAction<> &action)
  { _variant = action._variant; _target = action._target; _selector = action._selector; }

  /** Const copy constructor to allow for block capture of the struct. */
  CKTypedComponentAction<T...>(const CKTypedComponentAction<T...> &action)
  { _variant = action._variant; _target = action._target; _selector = action._selector; }

  /**
   We allow demotion from actions with types to untyped actions, but only when explicit. This means arguments to the
   method specified here will have nil values at runtime. Used for interoperation with older API's.
   */
  template<typename... Ts>
  explicit CKTypedComponentAction<>(const CKTypedComponentAction<Ts...> &action)
  { _variant = action._variant; _target = action._target; _selector = action._selector; }

  /** Allows conversion from NULL actions. */
  CKTypedComponentAction(int s) : _variant(_CKTypedComponentActionVariantRawSelector), _target(nil), _selector(NULL) {};
  CKTypedComponentAction(long s) : _variant(_CKTypedComponentActionVariantRawSelector), _target(nil), _selector(NULL) {};
  CKTypedComponentAction(std::nullptr_t n) : _variant(_CKTypedComponentActionVariantRawSelector), _target(nil), _selector(NULL) {};
  
  explicit operator bool() const { return _selector != NULL; };
  bool operator==(const CKTypedComponentAction& rhs) const
  {
    return _selector == rhs._selector && CKObjectIsEqual(_target, rhs._target) && _variant == rhs._variant;
  }
  
  SEL selector() const { return _selector; };
  
  void send(CKComponent *sender, T... args) const
  { this->send(sender, (_variant == _CKTypedComponentActionVariantRawSelector
                        ? CKComponentActionSendBehaviorStartAtSenderNextResponder
                        : CKComponentActionSendBehaviorStartAtSender), args...); }
  void send(CKComponent *sender, CKComponentActionSendBehavior behavior, T... args) const
  {
    if (_selector == NULL) {
      return;
    }
    const id target = _CKTypedComponentActionTarget(_variant, sender, _target, _scopeHandle);
    const id initialTarget = behavior == CKComponentActionSendBehaviorStartAtSender ? target : [target nextResponder];
    _CKComponentActionSendResponderChain(_selector, initialTarget, sender, args...);
  }
  
  /** Allows you to get a block that sends the action when executed. */
  typedef void (^CKTypedComponentActionExecutionBlock)(id sender, CKComponentActionSendBehavior behavior, T... args);
  CKTypedComponentActionExecutionBlock block() const
  {
    CKTypedComponentAction<T...> copy {*this};
    return ^(id sender, CKComponentActionSendBehavior behavior, T... args) {
      copy.send(sender, behavior, args...);
    };
  }
  typedef void (^CKTypedComponentActionCurriedSenderExecutionBlock)(T... args);
  CKTypedComponentActionCurriedSenderExecutionBlock curriedSenderBlock(id sender, CKComponentActionSendBehavior behavior) const
  {
    CKCAssertNotNil(sender, @"Must provide a sender to curry.");
    __weak id weakSender = sender;
    CKTypedComponentAction<T...> copy {*this};
    return ^(T... args) {
      id strongSender = weakSender;
      CKCAssert(strongSender, @"Curried sender should be retained by caller.");
      copy.send(strongSender, behavior, args...);
    };
  }

  /** Private details, do not use. */
  _CKTypedComponentActionVariant _variant;
  __weak id _target;
  SEL _selector;
  __weak CKComponentScopeHandle *_scopeHandle;
};

typedef CKTypedComponentAction<> CKComponentAction;

/**
 Sends a component action up the responder chain by crawling up the responder chain until it finds a responder that
 responds to the action's selector, then invokes it. These remain for legacy reasons, and simply call action.send(...);
 
 @param action The action to send up the responder chain.
 @param sender The component sending the action. Traversal starts from the component itself, then its next responder.
 @param context An optional context-dependent second parameter to the component action.
 @param behavior @see CKComponentActionSendBehavior
 */
void CKComponentActionSend(const CKComponentAction &action, CKComponent *sender);
void CKComponentActionSend(const CKComponentAction &action, CKComponent *sender, CKComponentActionSendBehavior behavior);
void CKComponentActionSend(const CKTypedComponentAction<id> &action, CKComponent *sender, id context);
void CKComponentActionSend(const CKTypedComponentAction<id> &action, CKComponent *sender, id context, CKComponentActionSendBehavior behavior);

/**
 Returns a view attribute that configures a component that creates a UIControl to send the given CKComponentAction.
 You can use this with e.g. CKButtonComponent.
 
 @param action Sent up the responder chain when an event occurs. Sender is the component that created the UIControl;
 context is the UIEvent that triggered the action. May be NULL, in which case no action will be sent.
 @param controlEvents The events that should result in the action being sent. Default is touch up inside.
 */
CKComponentViewAttributeValue CKComponentActionAttribute(const CKTypedComponentAction<UIEvent *> &action,
                                                         UIControlEvents controlEvents = UIControlEventTouchUpInside);
