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

#import <ComponentKit/CKComponentAction.h>

typedef void (*CKComponentGestureRecognizerSetupFunction)(UIGestureRecognizer *);

/**
 Returns a view attribute that creates and configures a tap gesture recognizer to send the given CKComponentAction.

 @param action Sent up the responder chain when a tap occurs. Sender is the component that created the view.
        Context is the gesture recognizer.
 */
CKComponentViewAttributeValue CKComponentTapGestureAttribute(CKComponentAction action);

/**
 Returns a view attribute that creates and configures a pan gesture recognizer to send the given CKComponentAction.

 @param action Sent up the responder chain when a pan occurs. Sender is the component that created the view.
        Context is the gesture recognizer.
 */
CKComponentViewAttributeValue CKComponentPanGestureAttribute(CKComponentAction action);

/**
 Returns a view attribute that creates and configures a long press gesture recognizer to send the given CKComponentAction.

 @param action Sent up the responder chain when a long press occurs. Sender is the component that created the view.
        Context is the gesture recognizer.
 */
CKComponentViewAttributeValue CKComponentLongPressGestureAttribute(CKComponentAction action);

/**
 Returns a view attribute that creates and configures a gesture recognizer.

 @param gestureRecognizerClass Must be a subclass of UIGestureRecognizer. Instantiated with -initWithTarget:action:.
 @param setupFunction Optional; pass nullptr if not needed. Called once for each new gesture recognizer; you may use
        this function to configure the new gesture recognizer.
 @param action Sent up the responder chain when the gesture recognizer recognizes a gesture. Sender is the component
        that created the view. Context is the gesture recognizer.
 */
CKComponentViewAttributeValue CKComponentGestureAttribute(Class gestureRecognizerClass,
                                                          CKComponentGestureRecognizerSetupFunction setupFunction,
                                                          CKComponentAction action);
