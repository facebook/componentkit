/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentGestureActionHelper.h"
#import "CKComponentGestureActionsInternal.h"

#import <ComponentKit/CKAction.h>
#import <ComponentKit/CKMutex.h>

#import "CKComponent+UIView.h"

/** Pass in a property block if you need to initialize the gesture recognizer **/
CKGestureRecognizerReusePool::CKGestureRecognizerReusePool(Class gestureRecognizerClass, CKComponentGestureRecognizerSetupFunction setupFunction)
: _gestureRecognizerClass(gestureRecognizerClass), _setupFunction(setupFunction) {}

UIGestureRecognizer *CKGestureRecognizerReusePool::get() {
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

void CKGestureRecognizerReusePool::recycle(UIGestureRecognizer *recognizer) {
  static const size_t kLimit = 5;
  if (_reusePool.size() < kLimit) {
    _reusePool.push_back(recognizer);
  }
}

struct CKGestureRecognizerReusePoolMapKey {
  __unsafe_unretained Class gestureRecognizerClass;
  CKComponentGestureRecognizerSetupFunction setupFunction;

  bool operator==(const CKGestureRecognizerReusePoolMapKey &other) const {
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

CKGestureRecognizerReusePool* CKCreateOrGetReusePool(Class gestureRecognizerClass, CKComponentGestureRecognizerSetupFunction setupFunction){
  static auto *reusePoolMap = new std::unordered_map<CKGestureRecognizerReusePoolMapKey, CKGestureRecognizerReusePool *>();
  static CK::StaticMutex reusePoolMapMutex = CK_MUTEX_INITIALIZER;
  CK::StaticMutexLocker l(reusePoolMapMutex);
  auto &reusePool = (*reusePoolMap)[{gestureRecognizerClass, setupFunction}];
  if (reusePool == nullptr) {
    reusePool = new CKGestureRecognizerReusePool(gestureRecognizerClass, setupFunction);
  }
  return reusePool;
}


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

static const char kCKComponentActionGestureRecognizerKey = ' ';

CKAction<UIGestureRecognizer *> CKComponentGestureGetAction(UIGestureRecognizer *gRecognizer)
{
  _CKGestureActionWrapper *wrapper = objc_getAssociatedObject(gRecognizer, &kCKComponentActionGestureRecognizerKey);
  if (wrapper) {
    return wrapper.action;
  } else {
    return {};
  }
};

/** This is for internal use by the framework only. */
void CKSetComponentActionForGestureRecognizer(UIGestureRecognizer *gRecognizer, const CKAction<UIGestureRecognizer *> &action)
{
  _CKGestureActionWrapper *wrapper = [[_CKGestureActionWrapper alloc] initWithGestureAction:action];
  objc_setAssociatedObject(gRecognizer, &kCKComponentActionGestureRecognizerKey, wrapper, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

void CKUnsetComponentActionForGestureRecognizer(UIGestureRecognizer *gRecognizer)
{
  objc_setAssociatedObject(gRecognizer, &kCKComponentActionGestureRecognizerKey, nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
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
  auto mountedView = CKMountedComponentForView(recognizer.view);
  if (mountedView) {
    // If the action can be handled by the sender itself, send it there instead of looking up the chain.
    CKComponentGestureGetAction(recognizer).send(mountedView, CKActionSendBehaviorStartAtSender, recognizer);
  }
}

@end

/** Find a UIGestureRecognizer attached to a view that has a given component action as associated object. */
UIGestureRecognizer *CKRecognizerForAction(UIView *view, CKAction<UIGestureRecognizer *> action)
{
  for (UIGestureRecognizer *recognizer in view.gestureRecognizers) {
    if (CKComponentGestureGetAction(recognizer) == action) {
      return recognizer;
    }
  }
  return nil;
}
