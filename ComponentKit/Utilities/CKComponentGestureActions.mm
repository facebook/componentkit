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
#import "CKComponent+UIView.h"
#import "CKInternalHelpers.h"
#import "CKMutex.h"

/** Find a UIGestureRecognizer attached to a view that has a given ck_componentAction. */
static UIGestureRecognizer *recognizerForAction(UIView *view, CKAction<UIGestureRecognizer *> action)
{
  for (UIGestureRecognizer *recognizer in view.gestureRecognizers) {
    if ([recognizer ck_componentAction] == action) {
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
  
  static auto *reusePoolMap = new std::unordered_map<CKGestureRecognizerReusePoolMapKey, CKGestureRecognizerReusePool *>();
  static CK::StaticMutex reusePoolMapMutex = CK_MUTEX_INITIALIZER;
  CK::StaticMutexLocker l(reusePoolMapMutex);
  auto &reusePool = (*reusePoolMap)[{gestureRecognizerClass, setupFunction}];
  if (reusePool == nullptr) {
    reusePool = new CKGestureRecognizerReusePool(gestureRecognizerClass, setupFunction);
  }
  CKAction<UIGestureRecognizer *> blockAction = action;
  return {
    {
      std::string(class_getName(gestureRecognizerClass))
      + "-" + CKStringFromPointer((const void *)setupFunction)
      + "-" + action.identifier()
      + CKIdentifierFromDelegateForwarderSelectors(delegateSelectors),
      ^(UIView *view, id value){
        CKCAssertNil(recognizerForAction(view, blockAction),
                     @"Registered two gesture recognizers with the same action %@", NSStringFromSelector(blockAction.selector()));
        UIGestureRecognizer *gestureRecognizer = reusePool->get();
        [gestureRecognizer ck_setComponentAction:blockAction];
        
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
        UIGestureRecognizer *recognizer = recognizerForAction(view, blockAction);
        if (recognizer == nil) {
          return;
        }
        
        [view removeGestureRecognizer:recognizer];
        [recognizer ck_setComponentAction:nullptr];
        
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
  if (recognizer.view.ck_component) {
    // If the action can be handled by the sender itself, send it there instead of looking up the chain.
    [recognizer ck_componentAction].send(recognizer.view.ck_component, CKComponentActionSendBehaviorStartAtSender, recognizer);
  }
}

@end

@interface _CKGestureActionWrapper : NSObject <NSCopying>

- (instancetype)initWithGestureAction:(const CKAction<UIGestureRecognizer *> &)action;

- (CKAction<UIGestureRecognizer *>)action;

@end

@implementation _CKGestureActionWrapper
{
  CKAction<UIGestureRecognizer *> _action;
}

- (instancetype)initWithGestureAction:(const CKAction<UIGestureRecognizer *> &)action
{
  if (self = [super init]) {
    _action = action;
  }
  return self;
}

- (CKAction<UIGestureRecognizer *>)action
{ return _action; }

- (id)copyWithZone:(NSZone *)zone
{ return self; }

@end

CKAction<UIGestureRecognizer *> CKComponentGestureGetAction(UIGestureRecognizer *gesture)
{
  return [gesture ck_componentAction];
};

@implementation UIGestureRecognizer (CKComponent)

static const char kCKComponentActionGestureRecognizerKey = ' ';

- (CKAction<UIGestureRecognizer *>)ck_componentAction
{
  _CKGestureActionWrapper *wrapper = objc_getAssociatedObject(self, &kCKComponentActionGestureRecognizerKey);
  if (wrapper) {
    return wrapper.action;
  } else {
    return {};
  }
}

- (void)ck_setComponentAction:(const CKAction<UIGestureRecognizer *> &)action
{
  _CKGestureActionWrapper *wrapper = [[_CKGestureActionWrapper alloc] initWithGestureAction:action];
  objc_setAssociatedObject(self, &kCKComponentActionGestureRecognizerKey, wrapper, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
