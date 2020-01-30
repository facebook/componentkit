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
#import <UIKit/UIKit.h>

#import <ComponentKit/CKAction.h>

UIGestureRecognizer *CKRecognizerForAction(UIView *view, CKAction<UIGestureRecognizer *> action);

typedef void (*CKComponentGestureRecognizerSetupFunction)(UIGestureRecognizer *);

/**
 Allows mapping a UIGestureRecognizer back to the original CKComponentAction selector,
 since ComponentKit internally changes the selector to be able send to the component responder chain.
 */
CKAction<UIGestureRecognizer *> CKComponentGestureGetAction(UIGestureRecognizer *gesture);

/** This is for internal use by the framework only. */
void CKSetComponentActionForGestureRecognizer(UIGestureRecognizer *gRecognizer, const CKAction<UIGestureRecognizer *> &action);

void CKUnsetComponentActionForGestureRecognizer(UIGestureRecognizer *gRecognizer);

/** A simple little object that serves as a reuse pool for gesture recognizers. */
class CKGestureRecognizerReusePool {
public:
  /** Pass in a property block if you need to initialize the gesture recognizer **/
  CKGestureRecognizerReusePool(Class gestureRecognizerClass, CKComponentGestureRecognizerSetupFunction setupFunction);
  UIGestureRecognizer *get();
  void recycle(UIGestureRecognizer *recognizer);
private:
  Class _gestureRecognizerClass;
  CKComponentGestureRecognizerSetupFunction _setupFunction;
  std::vector<UIGestureRecognizer *> _reusePool;
};

CKGestureRecognizerReusePool* CKCreateOrGetReusePool(Class gestureRecognizerClass, CKComponentGestureRecognizerSetupFunction setupFunction);

#endif
