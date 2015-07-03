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
typedef SEL CKComponentAction;

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
void CKComponentActionSend(CKComponentAction action, CKComponent *sender, id context = nil,
                           CKComponentActionSendBehavior behavior = CKComponentActionSendBehaviorStartAtSenderNextResponder);

/**
 Returns a view attribute that configures a component that creates a UIControl to send the given CKComponentAction.
 You can use this with e.g. CKButtonComponent.

 @param action Sent up the responder chain when an event occurs. Sender is the component that created the UIControl;
        context is the UIEvent that triggered the action. May be NULL, in which case no action will be sent.
 @param controlEvents The events that should result in the action being sent. Default is touch up inside.
 */
CKComponentViewAttributeValue CKComponentActionAttribute(CKComponentAction action,
                                                         UIControlEvents controlEvents = UIControlEventTouchUpInside);

