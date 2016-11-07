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

template<typename... T>
struct CKTypedComponentAction {
  CKTypedComponentAction() : _variant(CKTypedComponentActionVariantRawSelector), _target(nil), _selector(NULL) {};
  CKTypedComponentAction(id target, SEL selector) : _variant(CKTypedComponentActionVariantTargetSelector), _target(target), _selector(selector)
  {
#if DEBUG
    std::vector<const char *> typeEncodings;
    _CKTypedComponentActionTypeVectorBuild(typeEncodings, _CKTypedComponentActionTypelist<T...>{});
    _CKTypedComponentDebugCheckTargetSelector(target, selector, typeEncodings);
#endif
  }
  
  /** Legacy constructor for raw selector actions. Traverse up the mount responder chain. */
  CKTypedComponentAction(SEL selector) : _variant(CKTypedComponentActionVariantRawSelector), _target(nil), _selector(selector) { };
  
  explicit operator bool() const { return _selector != NULL; };
  bool operator==(const CKTypedComponentAction& rhs) const
  {
    return _selector == rhs._selector && CKObjectIsEqual(_target, rhs._target) && _variant == rhs._variant;
  }
  
  SEL selector() const { return _selector; };
  
  void send(CKComponent *sender, T... args) const
  { this->send(sender, CKComponentActionSendBehaviorStartAtSenderNextResponder, args...); }
  void send(CKComponent *sender, CKComponentActionSendBehavior behavior, T... args) const
  {
    if (_selector == NULL) {
      return;
    }
    const id target = _variant == CKTypedComponentActionVariantRawSelector ? sender : _target;
    const id initialTarget = behavior == CKComponentActionSendBehaviorStartAtSender ? target : [target nextResponder];
    _CKComponentActionSendResponderChain(_selector, initialTarget, sender, args...);
  }
  
  /** Allows you to get a block that sends the action when executed. */
  typedef void (^CKTypedComponentActionExecutionBlock)(id sender, T... args);
  CKTypedComponentActionExecutionBlock block() const;
  
  /** We support promotion from actions that take no arguments, but we do not allow demotion. */
  CKTypedComponentAction(const CKTypedComponentAction<> &action)
  { _variant = action._variant; _target = action._target; _selector = action._selector; };
  
  /** Allows conversion from NULL actions. */
  CKTypedComponentAction(int s) : _variant(CKTypedComponentActionVariantRawSelector), _target(nil), _selector(NULL) {};
  CKTypedComponentAction(long s) : _variant(CKTypedComponentActionVariantRawSelector), _target(nil), _selector(NULL) {};
  CKTypedComponentAction(std::nullptr_t n) : _variant(CKTypedComponentActionVariantRawSelector), _target(nil), _selector(NULL) {};
  
  /** Private details, do not use. */
  CKTypedComponentActionVariant _variant;
  __weak id _target;
  SEL _selector;
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
CKComponentViewAttributeValue CKComponentActionAttribute(const CKTypedComponentAction<id> &action,
                                                         UIControlEvents controlEvents = UIControlEventTouchUpInside);
