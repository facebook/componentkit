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

@class CKComponent;

/**
 A component action is simply a selector. The selector may optionally take one argument: the sending component.
 
 Component actions provide a way for components to communicate to supercomponents using CKComponentActionSend. Since
 components are in the responder chain, the message will reach its supercomponents.
 */
struct CKComponentAction {
public:
  CKComponentAction() : _selector(NULL) {};
  
  /**
   TODO(ocrickard) Remove this. Implicit conversion from SEL is a temporary change to support refactoring these to
   take the scope.
   */
  CKComponentAction(SEL selector) : _selector(selector) {};
  
  /** TODO(ocrickard) Remove this. To support implicit conversion/comparison to NULL. */
  CKComponentAction(int s) : _selector(NULL) {};
  CKComponentAction(long s) : _selector(NULL) {};
  CKComponentAction(std::nullptr_t n) : _selector(NULL) {};
  
  SEL selector() const { return _selector; };
  
  bool operator==(const CKComponentAction& rhs) const { return _selector == rhs.selector(); };
  explicit operator bool() const { return _selector != NULL; }
  
private:
  SEL _selector;
};

/** TODO(ocrickard) Remove this. Present to support comparison with NULL during refactor. */
inline bool operator==(const CKComponentAction &lhs, const std::nullptr_t &rhs){ return lhs.selector() == NULL; }
inline bool operator!=(const CKComponentAction &lhs, const std::nullptr_t &rhs){ return !(lhs == rhs); }
inline bool operator==(const std::nullptr_t &lhs, const CKComponentAction &rhs){ return rhs.selector() == NULL; }
inline bool operator!=(const std::nullptr_t &lhs, const CKComponentAction &rhs){ return !(lhs == rhs); }
inline bool operator==(const CKComponentAction &lhs, const long &rhs){ return lhs.selector() == NULL; }
inline bool operator!=(const CKComponentAction &lhs, const long &rhs){ return !(lhs == rhs); }
inline bool operator==(const CKComponentAction &lhs, const int &rhs){ return lhs.selector() == NULL; }
inline bool operator!=(const CKComponentAction &lhs, const int &rhs){ return !(lhs == rhs); }

typedef NS_ENUM(NSUInteger, CKComponentActionSendBehavior) {
  /** Starts searching at the sender's next responder. Usually this is what you want to prevent infinite loops. */
  CKComponentActionSendBehaviorStartAtSenderNextResponder,
  /** If the sender itself responds to the action, invoke the action on the sender. */
  CKComponentActionSendBehaviorStartAtSender,
};

/**
 Sends a component action up the responder chain by crawling up the responder chain until it finds a responder that
 responds to the action's selector, then invokes it.
 
 @param action The action to send up the responder chain.
 @param sender The component sending the action. Traversal starts from the component itself, then its next responder.
 @param context An optional context-dependent second parameter to the component action. Defaults to nil.
 @param behavior @see CKComponentActionSendBehavior
 */
void CKComponentActionSend(const CKComponentAction &action, CKComponent *sender,
                           id context = nil,
                           CKComponentActionSendBehavior behavior = CKComponentActionSendBehaviorStartAtSenderNextResponder);

/**
 Returns a view attribute that configures a component that creates a UIControl to send the given CKComponentAction.
 You can use this with e.g. CKButtonComponent.
 
 @param action Sent up the responder chain when an event occurs. Sender is the component that created the UIControl;
 context is the UIEvent that triggered the action. May be NULL, in which case no action will be sent.
 @param controlEvents The events that should result in the action being sent. Default is touch up inside.
 */
CKComponentViewAttributeValue CKComponentActionAttribute(const CKComponentAction &action,
                                                         UIControlEvents controlEvents = UIControlEventTouchUpInside);
