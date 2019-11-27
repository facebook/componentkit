/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentGestureActions.h"
#import "CKComponentGestureActionHelper.h"

#import <vector>
#import <objc/runtime.h>

#import "CKFatal.h"
#import "CKComponent+UIView.h"

#import <ComponentKit/CKInternalHelpers.h>
#import <ComponentKit/CKComponentInternal.h>

CKComponentViewAttributeValue CKComponentTapGestureAttribute(CKAction<UIGestureRecognizer *> action)
{
  return CKComponentGestureAttribute([UITapGestureRecognizer class], nullptr, action);
}

CKComponentViewAttributeValue CKComponentPanGestureAttribute(CKAction<UIGestureRecognizer *> action)
{
  return CKComponentGestureAttribute([UIPanGestureRecognizer class], nullptr, action);
}

CKComponentViewAttributeValue CKComponentLongPressGestureAttribute(CKAction<UIGestureRecognizer *> action)
{
  return CKComponentGestureAttribute([UILongPressGestureRecognizer class], nullptr, action);
}

CKComponentViewAttributeValue CKComponentGestureAttribute(Class gestureRecognizerClass,
                                                          CKComponentGestureRecognizerSetupFunction setupFunction,
                                                          CKAction<UIGestureRecognizer *> action,
                                                          CKComponentForwardedSelectors delegateSelectors)
{
  if (!action || gestureRecognizerClass == Nil) {
    return {
      {
        std::string(class_getName(gestureRecognizerClass)) + "-"
        + CKStringFromPointer((const void *)setupFunction) + "-no-op",
        ^(UIView *view, id value) {}, ^(UIView *view, id value) {}
      },
      @YES  // Bogus value, we don't use it.
    };
  }

  auto reusePool = CKCreateOrGetReusePool(gestureRecognizerClass, setupFunction);
  CKAction<UIGestureRecognizer *> blockAction = action;
  return {
    {
      std::string(class_getName(gestureRecognizerClass))
      + "-" + CKStringFromPointer((const void *)setupFunction)
      + "-" + action.identifier()
      + CKIdentifierFromDelegateForwarderSelectors(delegateSelectors),
      ^(UIView *view, id value){
        CKCAssertNil(CKRecognizerForAction(view, blockAction),
                     @"Registered two gesture recognizers with the same action %@", NSStringFromSelector(blockAction.selector()));
        UIGestureRecognizer *gestureRecognizer = reusePool->get();
        CKSetComponentActionForGestureRecognizer(gestureRecognizer, blockAction);

        // Setup delegate proxying if applicable
        if (delegateSelectors.size() > 0) {
          CKCAssertNil(gestureRecognizer.delegate, @"Doesn't make sense to set the gesture delegate and provide selectors to proxy");
          CKComponentDelegateForwarder *proxy = [CKComponentDelegateForwarder newWithSelectors:delegateSelectors];
          proxy.view = view;
          gestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)proxy;
          // This will retain it
          CKSetDelegateProxyForObject(gestureRecognizer, proxy);
        }
        
        @try {
          [view addGestureRecognizer:gestureRecognizer];
        }
        @catch (NSException *ex) {
          CKComponent *mountedComponent = CKMountedComponentForView(view);
          NSString *fatalMsg = @"View does not have a mountedComponent";
          if (mountedComponent) {
            fatalMsg = [mountedComponent backtraceStackDescription];
          }
          CKCFatalWithCategory(mountedComponent.class, @"%@ while mounting \n%@", ex, fatalMsg);
        }
      },
      ^(UIView *view, id value){
        UIGestureRecognizer *recognizer = CKRecognizerForAction(view, blockAction);
        if (recognizer == nil) {
          return;
        }

        [view removeGestureRecognizer:recognizer];
        CKUnsetComponentActionForGestureRecognizer(recognizer);

        // Tear down delegate proxying if applicable
        if (delegateSelectors.size() > 0) {
          CKComponentDelegateForwarder *proxy = CKDelegateProxyForObject(recognizer);
          proxy.view = nil;
          recognizer.delegate = nil;
          CKSetDelegateProxyForObject(recognizer, nil);
        }
        reusePool->recycle(recognizer);
      }
    },
    @YES // Bogus value, we don't use it.
  };
}
