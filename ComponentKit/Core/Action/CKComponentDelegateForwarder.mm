/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentDelegateForwarder.h"

#import <vector>
#import <objc/runtime.h>

#import <ComponentKit/CKAssert.h>

#import "CKComponent+UIView.h"
#import "CKComponentSubclass.h"

std::string CKIdentifierFromDelegateForwarderSelectors(const CKComponentForwardedSelectors& first)
{
  if (first.size() == 0) {
    return "";
  }
  std::string so = "Delegate";
  for (auto& s : first) {
    so = so + "-" + sel_getName(s);
  }
  return so;
}

@interface CKComponentDelegateForwarder () {
  @package
  CKComponentForwardedSelectors _selectors;
}

@end

@implementation CKComponentDelegateForwarder

+ (instancetype)newWithSelectors:(CKComponentForwardedSelectors)selectors
{
  CKComponentDelegateForwarder *f = [[self alloc] init];
  if (!f) return nil;

  f->_selectors = selectors;

  return f;
}

/**
 This method is never invoked, and is used to provide a dummy method signature to the forwarding system if our
 normal fast-path forwarding doesn't work because the component has been unmounted.
 */
- (void)_doNothing {}

- (BOOL)respondsToSelector:(SEL)aSelector
{
  if ([super respondsToSelector:aSelector]) {
    return YES;
  } else {
    return selectorInList(aSelector, _selectors);
  }
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
  // The delegate forwarder is applied as a component view attribute, which is not un-applied to the view on entry
  // into the reuse pool, yet the *component* property on the view will begin returning nil in this case. This would
  // turn into a hard-crash because above forwardingTargetForSelector: will return nil, and the method will be directly
  // invoked on this object. In this case, we have no option but to assert, and not crash, as we do with unhandled
  // component actions.
  SEL selector = anInvocation.selector;
  if (selectorInList(selector, _selectors)) {
    CKComponent *responder = CKMountedComponentForView(_view);
    id target = [responder targetForAction:selector withSender:responder];
    if (!target) {
      CKFailAssertWithCategory(
        CKLastMountedComponentClassNameForView(_view),
        @"Delegate method is being called on an unmounted component's view: %@ selector:%@", 
        _view,
        NSStringFromSelector(selector));
      return;
    }
    [anInvocation invokeWithTarget:target];
  } else if(selector != @selector(_doNothing)) {
    [super forwardInvocation:anInvocation];
  }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
  NSMethodSignature *sig = [super methodSignatureForSelector:aSelector];
  if (sig) {
    return sig;
  }
  if (selectorInList(aSelector, _selectors)) {
    CKComponent *responder = CKMountedComponentForView(_view);
    id target = [responder targetForAction:aSelector withSender:responder];
    // We must return a non-nil method signature even if there is no real method signature to return, or we will just
    // crash in the forwarding system. This ensures the forwardInvocation: call above is called.
    return (target ? [target methodSignatureForSelector:aSelector] : [self methodSignatureForSelector:@selector(_doNothing)]);
  }
  return nil;
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
  CKComponent *responder = CKMountedComponentForView(_view);
  return [responder targetForAction:aSelector withSender:responder];
}

static BOOL selectorInList(SEL selector, const CKComponentForwardedSelectors &selectors)
{
  return std::find(selectors.begin(), selectors.end(), selector) != selectors.end();
}

@end

static const char kCKComponentDelegateProxyKey = ' ';

auto CKDelegateProxyForObject(NSObject *obj) -> CKComponentDelegateForwarder *
{
  return objc_getAssociatedObject(obj, &kCKComponentDelegateProxyKey);
}

auto CKSetDelegateProxyForObject(NSObject *obj, CKComponentDelegateForwarder *delegateProxy) -> void
{
  objc_setAssociatedObject(obj, &kCKComponentDelegateProxyKey, delegateProxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
