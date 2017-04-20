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

/**
 CKTypedComponentAction is a struct that represents a method invocation that can be passed to a child component to
 trigger a method invocation on a target.
 
 We allow a typed specification of the parameters that will be provided as arguments to the component action at runtime
 through the variadic templated arguments. You may specify an arbitrary number of arguments to your component action,
 and you may use either object, or primitive arguments. Only trivially-constructible arguments or pointers can be used
 as types for component actions, so primitive types like int, CGRect, and NSObject * are fine. This is enforced via a
 compile time check.

 Methods will always be provided the sender as the first argument.
 
 Usage in your component header:
 
 @interface MyComponent : CKComponent
 + (instancetype)newWithAction:(const CKTypedComponentAction<NSString *, int> &)action;
 @end
 
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
   CKTypedComponentAction<NSString *, int> _action;
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
class CKTypedComponentAction : public CKTypedComponentActionBase {
  static_assert(std::is_same<
                CKTypedComponentActionBoolPack<(std::is_trivially_constructible<T>::value || std::is_pointer<T>::value)...>,
                CKTypedComponentActionBoolPack<(CKTypedComponentActionDenyType<T>::value)...>
                >::value, "You must either use a pointer (like an NSObject) or a trivially constructible type. Complex types are not allowed as arguments of component actions.");
  
  CKTypedComponentAction<T...>(void(^block)(CKComponent *, T...)) noexcept : CKTypedComponentActionBase((dispatch_block_t)block) {};
  
public:
  CKTypedComponentAction<T...>() noexcept : CKTypedComponentActionBase() {};
  CKTypedComponentAction<T...>(id target, SEL selector) noexcept : CKTypedComponentActionBase(target, selector)
  {
#if DEBUG
    std::vector<const char *> typeEncodings;
    CKTypedComponentActionTypeVectorBuild(typeEncodings, CKTypedComponentActionTypelist<T...>{});
    _CKTypedComponentDebugCheckTargetSelector(target, selector, typeEncodings);
#endif
  }

  CKTypedComponentAction<T...>(const CKComponentScope &scope, SEL selector) noexcept : CKTypedComponentActionBase(scope, selector)
  {
#if DEBUG
    std::vector<const char *> typeEncodings;
    CKTypedComponentActionTypeVectorBuild(typeEncodings, CKTypedComponentActionTypelist<T...>{});
    _CKTypedComponentDebugCheckComponentScope(scope, selector, typeEncodings);
#endif
  }

  /** Legacy constructor for raw selector actions. Traverse up the mount responder chain. */
  CKTypedComponentAction(SEL selector) noexcept : CKTypedComponentActionBase(selector) {};
  
  static CKTypedComponentAction<T...> actionFromBlock(void(^block)(CKComponent *, T...)) {
    return CKTypedComponentAction<T...>(block);
  }

  /** Allows conversion from NULL actions. */
  CKTypedComponentAction(int s) noexcept : CKTypedComponentActionBase() {};
  CKTypedComponentAction(long s) noexcept : CKTypedComponentActionBase() {};
  CKTypedComponentAction(std::nullptr_t n) noexcept : CKTypedComponentActionBase() {};

  /** We support promotion from actions that take no arguments. */
  template <typename... Ts>
  CKTypedComponentAction<Ts...>(const CKTypedComponentAction<> &action) noexcept : CKTypedComponentActionBase(action) {
    // At runtime if we provide more arguments to a block on invocation than accepted by the block, the behavior is
    // undefined. If you hit this assert, it means somewhere in your code you're doing this:
    // CKTypedComponentAction<BOOL, int> = ^(CKComponent *sender) {
    // To fix the error, you must handle all arguments:
    // CKTypedComponentAction<BOOL, int> = ^(CKComponent *sender, BOOL foo, int bar) {
    CKCAssert(_variant != CKTypedComponentActionVariant::Block, @"Block actions should not take fewer arguments than defined in the declaration of the action, you are depending on undefined behavior and will cause crashes.");
  };

  /**
   We allow demotion from actions with types to untyped actions, but only when explicit. This means arguments to the
   method specified here will have nil values at runtime. Used for interoperation with older API's.
   */
  template<typename... Ts>
  explicit CKTypedComponentAction<>(const CKTypedComponentAction<Ts...> &action) noexcept : CKTypedComponentActionBase(action) {
    CKCAssert(_variant != CKTypedComponentActionVariant::Block, @"Block actions cannot take fewer arguments than provided in the declaration of the action, you are depending on undefined behavior and will cause crashes.");
  };

  ~CKTypedComponentAction() {};

  void send(CKComponent *sender, T... args) const
  { this->send(sender, defaultBehavior(), args...); };
  void send(CKComponent *sender, CKComponentActionSendBehavior behavior, T... args) const
  {
    if (_variant == CKTypedComponentActionVariant::Block) {
      void (^block)(CKComponent *sender, T... args) = (void (^)(CKComponent *sender, T... args))_block;
      block(sender, args...);
      return;
    }
    const id target = initialTarget(sender);
    const id responder = behavior == CKComponentActionSendBehaviorStartAtSender ? target : [target nextResponder];
    CKComponentActionSendResponderChain(selector(), responder, sender, args...);
  };

  bool operator==(const CKTypedComponentAction<T...> &rhs) const noexcept {
    return isEqual(rhs);
  };

  friend void CKComponentActionSend(const CKTypedComponentAction<id> &action, CKComponent *sender, id context);
};

typedef CKTypedComponentAction<> CKComponentAction;

/** Explicit instantiation of our most commonly-used templates to avoid bloat in callsites. */
extern template class CKTypedComponentAction<>;
extern template class CKTypedComponentAction<id>;

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
                                                         UIControlEvents controlEvents = UIControlEventTouchUpInside) noexcept;

/**
 Returns a view attribute that configures a view to have custom accessibility actions.

 @param actions An ordered list of actions, each with a name and an associated CKComponentAction
 */
CKComponentViewAttributeValue CKComponentAccessibilityCustomActionsAttribute(const std::vector<std::pair<NSString *, CKComponentAction>> &actions) noexcept;
