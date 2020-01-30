/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKDefines.h>

#if CK_NOT_SWIFT

#import <UIKit/UIKit.h>

#import <ComponentKit/CKBaseRenderContext.h>
#import <ComponentKit/CKComponentViewAttribute.h>
#import <ComponentKit/CKComponentActionInternal.h>
#import <ComponentKit/CKRenderComponentProtocol.h>
#import <objc/runtime.h>

#pragma once

@class CKComponent;

namespace CK {
  namespace detail {
    template<class...> struct any_references : std::false_type {};
    template<class T> struct any_references<T> : std::is_reference<T> {};
    template<class T, class... Ts>
    struct any_references<T, Ts...>
      : std::conditional<std::is_reference<T>::value, std::true_type, any_references<Ts...>>::type {};
  }
}

/**
 CKAction is a struct that represents a method invocation that can be passed to a child component to
 trigger a method invocation on a target.

 We allow a typed specification of the parameters that will be provided as arguments to the component action at runtime
 through the variadic templated arguments. You may specify an arbitrary number of arguments to your component action,
 and you may use either object, or primitive arguments. Only trivially-constructible arguments or pointers can be used
 as types for component actions, so primitive types like int, CGRect, and NSObject * are fine. This is enforced via a
 compile time check.

 Methods will always be provided the sender as the first argument.

 Usage in your component header:

     //... inside MyComponent.h interface
     + (instancetype)newWithAction:(const CKAction<NSString *, int> &)action;

 When creating the action:

 Option 1 - Scope action. Similar to target/selector action in that it skips the responder chain from the sender, and
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
                         newWithAction:{scope, @selector(methodWithSender:)}]];
             }
             - (void)methodWithSender:(CKComponent *)sender {}

 Option 2 - Target/selector action. Ensures that the target responds to the given selector. Target must directly
            respond to the selector. Targets are captured weakly by the action. Promotion, as in option 2 above is also
            supported for target/selector actions. This constructor is useful for triggering actions on objects outside
            of the component hierarchy like view controllers. Does not depend on the mount-based responder chain to
            call on the target.

             [MyComponent newWithAction:{[SomeObject sharedInstance], @selector(methodWithNoArguments)}];
             ...
             on SomeObject: - (void)methodWithNoArguments {}

 Option 3 - (Discouraged) Raw-selector component action. Uses a raw selector which traverses upwards looking for a
            parent that implements methodWithNoArguments, and calls that method without any arguments. The component
            responder chain is only present while the component is mounted, so you should use a target/selector action
            or a scope action if your action will be fired either before or after your component is mounted. We support
            actions which accept fewer arguments than defined in the declaration of the action above. However, types of
            received parameters should be the same as the declaration, if they're present.

             [MyComponent newWithAction:{@selector(methodWithSender:)}];
             ...
             - (void)methodWithSender:(CKComponent *)sender {}

 When using the action, simply use the send() function with the sender, an optional behavior parameter, and the
 arguments defined in the declaration of the action.

 @implementation MyComponent
 {
   CKAction<NSString *, int> _action;
 }
 - (void)triggerAction
 {
   _action.send(self, @"hello", 4);
 }


 In the event that an action does not contain a target or a selector, it will no-op.
 As a result, it is the responsibility of the component to check (and possibly assert)
 when it has been given an "invalid" action.
 */
template<typename... T>
class CKAction : public CKActionBase {
  /** This constructor is private to forbid direct usage. Use actionFromBlock. */
  CKAction<T...>(void(^block)(CKComponent *, T...)) noexcept : CKActionBase((dispatch_block_t)block) {};

public:
  CKAction<T...>() noexcept : CKActionBase() {};
  CKAction<T...>(id target, SEL selector) noexcept : CKActionBase(target, selector)
  {
#if DEBUG
    std::vector<const char *> typeEncodings;
    CKActionTypeVectorBuild(typeEncodings, CKActionTypelist<T...>{});
    _CKTypedComponentDebugCheckTargetSelector(target, selector, typeEncodings);
#endif
  }

  CKAction<T...>(const CKComponentScope &scope, SEL selector) noexcept : CKActionBase(scope, selector)
  {
#if DEBUG
    std::vector<const char *> typeEncodings;
    CKActionTypeVectorBuild(typeEncodings, CKActionTypelist<T...>{});
    _CKTypedComponentDebugCheckComponentScope(scope, selector, typeEncodings);
#endif
  }

  // Changing the order of the params here, as otherwise it confuses this constructor with the target one.
  CKAction<T...>(SEL selector, id<CKRenderComponentProtocol> component) noexcept : CKActionBase(selector, component)
  {
#if DEBUG
    std::vector<const char *> typeEncodings;
    CKActionTypeVectorBuild(typeEncodings, CKActionTypelist<T...>{});
    _CKTypedComponentDebugCheckComponentScopeHandle(component.scopeHandle, selector, typeEncodings);
#endif
  }

  /** Legacy constructor for raw selector actions. Traverse up the mount responder chain. */
  CKAction(SEL selector) noexcept : CKActionBase(selector) {};

  /**
   Allows passing a block as an action. It is easy to create retain cycles with this API, always prefer scoped actions
   over this if possible.
   */
  static CKAction<T...> actionFromBlock(void(^block)(CKComponent *, T...)) {
    return CKAction<T...>(block);
  }

  /**
   Construct an action from a Render component.
   */
  static CKAction<T...> actionForRenderComponent(id<CKRenderComponentProtocol> component, SEL selector) {
    return CKAction<T...>(selector, component);
  }

  /**
  Constructs an action for a controller from a render context.
  */
  static CKAction<T...> actionForController(CK::BaseRenderContext context, SEL selector) {
    id<CKRenderComponentProtocol> component = (id)context._component;
#if DEBUG
    CKCAssert([context._component conformsToProtocol:@protocol(CKRenderComponentProtocol)], @"RenderContext contains non render component");
    std::vector<const char *> typeEncodings;
    CKActionTypeVectorBuild(typeEncodings, CKActionTypelist<T...>{});
    _CKTypedComponentDebugCheckComponentScopeHandle(component.scopeHandle, selector, typeEncodings);
#endif
    return CKAction<T...>(component.scopeHandle.controller, selector);
  }

  /** Like actionFromBlock, but allows passing a block that doesn't take a sender component. */
  static CKAction<T...> actionFromSenderlessBlock(void (^block)(T...)) {
    if (!block) {
      return {};
    }
    return CKAction<T...>::actionFromBlock(^(CKComponent* sender, T... args) {
      block(args...);
    });
  }

  /**
   Allows demoting an action to a simpler action while supplying defaults for the values that won't be passed in.
   */
  template<typename... U>
  static CKAction<T...> demotedFrom(CKAction<T..., U...> action, U... defaults) {
    static_assert(!CK::detail::any_references<U...>::value, "Demoting an action with reference defaults is not allowed");
    if (!action) {
      return {};
    }
    return CKAction<T...>::actionFromBlock(^(CKComponent *sender, T... args) {
      action.send(sender, args..., defaults...);
    });
  }

  template<typename... U>
  static CKAction<T..., U...> promotedFrom(CKAction<T...> action) {
    if (!action) {
      return {};
    }
    return CKAction<T..., U...>::actionFromBlock(^(CKComponent* sender, T... argsT, U... argsU) {
      action.send(sender, argsT...);
    });
  }

  /**
   Allows explicit null actions. NULL can cause ambiguity in constructor resolution and is best avoided where
   nullptr is available.
   */
  CKAction(std::nullptr_t n) noexcept : CKActionBase() {};

  /** We support promotion from actions that take no arguments. */
  template <typename... Ts>
  CKAction<Ts...>(const CKAction<> &action) noexcept : CKActionBase(action) {};

  /**
   We allow demotion from actions with types to untyped actions, but only when explicit. This means arguments to the
   method specified here will have nil values at runtime. Used for interoperation with older API's.
   */
  template<typename... Ts>
  explicit CKAction<>(const CKAction<Ts...> &action) noexcept : CKActionBase(action) {
    CKCAssert(_variant != CKActionVariant::Block, @"Block actions cannot take fewer arguments than provided in the declaration of the action, you are depending on undefined behavior and will cause crashes.");
  };

  ~CKAction() {};

  void send(CKComponent *sender, T... args) const
  { this->send(sender, defaultBehavior(), args...); };

  void send(CK::BaseRenderContext context, T... args) const
  {
    CKCAssertNotNil(context._component, @"RenderContext contains nil component");
    this->send((CKComponent *)context._component, defaultBehavior(), args...);
  };

  void send(CKComponent *sender, CKActionSendBehavior behavior, T... args) const
  {
    if (_variant == CKActionVariant::Block) {
      void (^block)(CKComponent *sender, T... args) = (void (^)(CKComponent *sender, T... args))_block;
      block(sender, args...);
      return;
    }
    const id target = initialTarget(sender);
    const id responder = behavior == CKActionSendBehaviorStartAtSender ? target : [target nextResponder];
    CKActionSendResponderChain(selector(), responder, sender, args...);
  };

  bool operator==(const CKAction<T...> &rhs) const noexcept {
    return isEqual(rhs);
  };

  friend void CKActionSend(const CKAction<id> &action, CKComponent *sender, id context);
};

BOOL checkMethodSignatureAgainstTypeEncodings(SEL selector,
                                              Method method,
                                              const std::vector<const char *> &typeEncodings);

typedef CKAction<> CKUntypedComponentAction;

/** Explicit instantiation of our most commonly-used templates to avoid bloat in callsites. */
extern template class CKAction<>;
extern template class CKAction<id>;

/**
 Sends a component action up the responder chain by crawling up the responder chain until it finds a responder that
 responds to the action's selector, then invokes it. These remain for legacy reasons, and simply call action.send(...);

 @param action The action to send up the responder chain.
 @param sender The component sending the action. Traversal starts from the component itself, then its next responder.
 @param context An optional context-dependent second parameter to the component action.
 @param behavior An enum specifies how to send the action. @see CKActionSendBehavior
 */
void CKActionSend(const CKAction<id> &action, CKComponent *sender, id context, CKActionSendBehavior behavior);
void CKActionSend(const CKAction<id> &action, CKComponent *sender, id context);
void CKActionSend(const CKAction<> &action, CKComponent *sender, CKActionSendBehavior behavior);
void CKActionSend(const CKAction<> &action, CKComponent *sender);

/**
 Returns a view attribute that configures a component that creates a UIControl to send the given CKComponentAction.
 You can use this with e.g. CKButtonComponent.

 @param action Sent up the responder chain when an event occurs. Sender is the component that created the UIControl;
 context is the UIEvent that triggered the action. May be NULL, in which case no action will be sent.
 @param controlEvents The events that should result in the action being sent. Default is touch up inside.
 */
CKComponentViewAttributeValue CKComponentActionAttribute(const CKAction<UIEvent *> action,
                                                         UIControlEvents controlEvents = UIControlEventTouchUpInside) noexcept;

/**
 Returns a view attribute that configures a view to have custom accessibility actions.

 @param actions An ordered list of actions, each with a name and an associated CKAction<>
 */
CKComponentViewAttributeValue CKComponentAccessibilityCustomActionsAttribute(const std::vector<std::pair<NSString *, CKAction<>>> &actions) noexcept;

#endif
