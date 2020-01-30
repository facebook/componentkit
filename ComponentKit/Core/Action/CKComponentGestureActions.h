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

#import <Foundation/Foundation.h>

#import <ComponentKit/CKComponentDelegateForwarder.h>

#import <ComponentKit/CKComponentGestureActionHelper.h>

/**
 Returns a view attribute that creates and configures a tap gesture recognizer to send the given CKAction.

 @param action Sent up the responder chain when a tap occurs. Sender is the component that created the view.
 Context is the gesture recognizer. May be NULL, in which case no action will be sent.
 */
CKComponentViewAttributeValue CKComponentTapGestureAttribute(CKAction<UIGestureRecognizer *> action);

/**
 Returns a view attribute that creates and configures a pan gesture recognizer to send the given CKAction.

 @param action Sent up the responder chain when a pan occurs. Sender is the component that created the view.
 Context is the gesture recognizer. May be NULL, in which case no action will be sent.
 */
CKComponentViewAttributeValue CKComponentPanGestureAttribute(CKAction<UIGestureRecognizer *> action);

/**
 Returns a view attribute that creates and configures a long press gesture recognizer to send the given CKAction.

 @param action Sent up the responder chain when a long press occurs. Sender is the component that created the view.
 Context is the gesture recognizer. May be NULL, in which case no action will be sent.
 */
CKComponentViewAttributeValue CKComponentLongPressGestureAttribute(CKAction<UIGestureRecognizer *> action);

/**
 Returns a view attribute that creates and configures a gesture recognizer.

 @param gestureRecognizerClass Must be a subclass of UIGestureRecognizer. Instantiated with -initWithTarget:action:.
 @param setupFunction Optional; pass nullptr if not needed. Called once for each new gesture recognizer; you may use
 this function to configure the new gesture recognizer.
 @param action Sent up the responder chain when the gesture recognizer recognizes a gesture. Sender is the component
 that created the view. Context is the gesture recognizer. May be NULL, in which case no action will be sent.
 */
CKComponentViewAttributeValue CKComponentGestureAttribute(Class gestureRecognizerClass,
                                                          CKComponentGestureRecognizerSetupFunction setupFunction,
                                                          CKAction<UIGestureRecognizer *> action,
                                                          CKComponentForwardedSelectors delegateSelectors = {});

#endif
