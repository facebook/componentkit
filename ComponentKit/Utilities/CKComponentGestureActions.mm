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
#import "CKComponentGestureActionsInternal.h"

#import <vector>
#import <objc/runtime.h>

#import "CKAssert.h"
#import "CKInternalHelpers.h"
#import "CKMutex.h"
#import "CKComponentViewInterface.h"

/** Find a UIGestureRecognizer attached to a view that has a given ck_componentAction. */
static UIGestureRecognizer *recognizerForAction(UIView *view, CKComponentAction action)
{
  for (UIGestureRecognizer *recognizer in view.gestureRecognizers) {
    if (sel_isEqual([recognizer ck_componentAction], action)) {
      return recognizer;
    }
  }
  return nil;
}

/** A simple little object that serves as a reuse pool for gesture recognizers. */
class CKGestureRecognizerReusePool {
public:
  /** Pass in a property block if you need to initialize the gesture recognizer **/
  CKGestureRecognizerReusePool(Class gestureRecognizerClass, CKComponentGestureRecognizerSetupFunction setupFunction)
  : _gestureRecognizerClass(gestureRecognizerClass), _setupFunction(setupFunction) {}
  UIGestureRecognizer *get() {
    if (_reusePool.empty()) {
      UIGestureRecognizer *ret =
      [[_gestureRecognizerClass alloc] initWithTarget:[CKComponentGestureActionForwarder sharedInstance]
                                               action:@selector(handleGesture:)];
      if (_setupFunction) {
        _setupFunction(ret);
      }
      return ret;
    } else {
      UIGestureRecognizer *value = _reusePool.back();
      _reusePool.pop_back();
      return value;
    }
  }
  void recycle(UIGestureRecognizer *recognizer) {
    static const size_t kLimit = 5;
    if (_reusePool.size() < kLimit) {
      _reusePool.push_back(recognizer);
    }
  }
private:
  Class _gestureRecognizerClass;
  CKComponentGestureRecognizerSetupFunction _setupFunction;
  std::vector<UIGestureRecognizer *> _reusePool;
};

CKComponentViewAttributeValue CKComponentTapGestureAttribute(CKComponentAction action)
{
  return CKComponentGestureAttribute([UITapGestureRecognizer class], nullptr, action);
}

CKComponentViewAttributeValue CKComponentPanGestureAttribute(CKComponentAction action)
{
  return CKComponentGestureAttribute([UIPanGestureRecognizer class], nullptr, action);
}

CKComponentViewAttributeValue CKComponentLongPressGestureAttribute(CKComponentAction action)
{
  return CKComponentGestureAttribute([UILongPressGestureRecognizer class], nullptr, action);
}

struct CKGestureRecognizerReusePoolMapKey {
  __unsafe_unretained Class gestureRecognizerClass;
  CKComponentGestureRecognizerSetupFunction setupFunction;

  bool operator==(const CKGestureRecognizerReusePoolMapKey &other) const
  {
    return other.gestureRecognizerClass == gestureRecognizerClass && other.setupFunction == setupFunction;
  }
};

namespace std {
  template<> struct hash<CKGestureRecognizerReusePoolMapKey>
  {
    size_t operator()(const CKGestureRecognizerReusePoolMapKey &k) const
    {
      return [k.gestureRecognizerClass hash] ^ std::hash<CKComponentGestureRecognizerSetupFunction>()(k.setupFunction);
    }
  };
}

CKComponentViewAttributeValue CKComponentGestureAttribute(Class gestureRecognizerClass,
                                                          CKComponentGestureRecognizerSetupFunction setupFunction,
                                                          CKComponentAction action,
                                                          CKComponentForwardedSelectors delegateSelectors)
{
  if (action == NULL) {
    return {
      {
        std::string(class_getName(gestureRecognizerClass)) + "-"
        + CKStringFromPointer((const void *)setupFunction) + "-no-op",
        ^(UIView *view, id value) {}, ^(UIView *view, id value) {}
      },
      @YES  // Bogus value, we don't use it.
    };
  }

  static auto *reusePoolMap = new std::unordered_map<CKGestureRecognizerReusePoolMapKey, CKGestureRecognizerReusePool *>();
  static CK::StaticMutex reusePoolMapMutex = CK_MUTEX_INITIALIZER;
  CK::StaticMutexLocker l(reusePoolMapMutex);
  auto &reusePool = (*reusePoolMap)[{gestureRecognizerClass, setupFunction}];
  if (reusePool == nullptr) {
    reusePool = new CKGestureRecognizerReusePool(gestureRecognizerClass, setupFunction);
  }
  return {
    {
      std::string(class_getName(gestureRecognizerClass))
      + "-" + CKStringFromPointer((const void *)setupFunction)
      + "-" + std::string(sel_getName(action))
      + CKIdentifierFromDelegateForwarderSelectors(delegateSelectors),
      ^(UIView *view, id value){
        CKCAssertNil(recognizerForAction(view, action),
                     @"Registered two gesture recognizers with the same action %@", NSStringFromSelector(action));
        UIGestureRecognizer *gestureRecognizer = reusePool->get();
        [gestureRecognizer ck_setComponentAction:action];

        // Setup delegate proxying if applicable
        if (delegateSelectors.size() > 0) {
          CKCAssertNil(gestureRecognizer.delegate, @"Doesn't make sense to set the gesture delegate and provide selectors to proxy");
          CKComponentDelegateForwarder *proxy = [CKComponentDelegateForwarder newWithSelectors:delegateSelectors];
          proxy.view = view;
          gestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)proxy;
          // This will retain it
          gestureRecognizer.ck_delegateProxy = proxy;
        }
        [view addGestureRecognizer:gestureRecognizer];
      },
      ^(UIView *view, id value){
        UIGestureRecognizer *recognizer = recognizerForAction(view, action);
        CKCAssertNotNil(recognizer, @"Expected to find recognizer for %@ on teardown", NSStringFromSelector(action));
        [view removeGestureRecognizer:recognizer];
        [recognizer ck_setComponentAction:NULL];

        // Tear down delegate proxying if applicable
        if (delegateSelectors.size() > 0) {
          CKComponentDelegateForwarder *proxy = recognizer.ck_delegateProxy;
          proxy.view = nil;
          recognizer.delegate = nil;
          recognizer.ck_delegateProxy = nil;
        }
        reusePool->recycle(recognizer);
      }
    },
    @YES // Bogus value, we don't use it.
  };
}

@implementation CKComponentGestureActionForwarder

+ (instancetype)sharedInstance
{
  static CKComponentGestureActionForwarder *forwarder;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    forwarder = [[CKComponentGestureActionForwarder alloc] init];
  });
  return forwarder;
}

- (void)handleGesture:(UIGestureRecognizer *)recognizer
{
  // If the action can be handled by the sender itself, send it there instead of looking up the chain.
  CKComponentActionSend([recognizer ck_componentAction], recognizer.view.ck_component, recognizer,
                        CKComponentActionSendBehaviorStartAtSender);
}

@end

CKComponentAction CKComponentGestureGetAction(UIGestureRecognizer *gesture)
{
  return [gesture ck_componentAction];
};

@implementation UIGestureRecognizer (CKComponent)

static const char kCKComponentActionGestureRecognizerKey = ' ';

- (CKComponentAction)ck_componentAction
{
  NSString *action = objc_getAssociatedObject(self, &kCKComponentActionGestureRecognizerKey);
  if (action) {
    return NSSelectorFromString(action);
  } else {
    return NULL;
  }
}

- (void)ck_setComponentAction:(CKComponentAction)action
{
  NSString *actionString = (action == NULL) ? nil : NSStringFromSelector(action);
  objc_setAssociatedObject(self, &kCKComponentActionGestureRecognizerKey, actionString, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
