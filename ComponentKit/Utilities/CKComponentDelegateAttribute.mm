/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentDelegateAttribute.h"

#import <vector>
#import <objc/runtime.h>

#import "CKAssert.h"
#import "CKComponentViewInterface.h"
#import "CKComponentSubclass.h"

std::string identifierFromDefinition(const CKComponentDelegateAttributeDefinition& first)
{
  std::string so = "Delegate";
  for (auto& s : first) {
    so = so + "-" + sel_getName(s);
  }
  return so;
}

@interface CKComponentDelegateForwarder : NSObject {
  @package
  // Weak ref to our view, to grab the component.
  __weak UIView *_view;
  CKComponentDelegateAttributeDefinition _defn;
}

@end

@interface UIView (CKDelegateProxy)

@property (nonatomic, strong, setter=ck_setDelegateProxy:) CKComponentDelegateForwarder *ck_delegateProxy;

@end

CKComponentViewAttributeValue CKComponentDelegateAttribute(SEL selector,
                                                           CKComponentDelegateAttributeDefinition definition)
{
  if (selector == NULL) {
    return {
      {
        std::string("Delegate-noop-") + sel_getName(selector) + "-",
        ^(UIView *view, id value) {}, ^(UIView *view, id value) {}
      },
      @YES  // Bogus value, we don't use it.
    };
  }

  return {
    {
      std::string(sel_getName(selector)) + identifierFromDefinition(definition),
      ^(UIView *view, id value){

        // Create a proxy for this set of selectors

        CKCAssertNil(view.ck_delegateProxy,
                     @"Unsupported: registered two delegate proxies for the same view: %@ %@", view, view.ck_delegateProxy);

        CKComponentDelegateForwarder *proxy = [[CKComponentDelegateForwarder alloc] init];
        proxy->_view = view;
        proxy->_defn = definition;
        view.ck_delegateProxy = proxy;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [view performSelector:selector withObject:proxy];
#pragma clang diagnostic pop

      },
      ^(UIView *view, id value){

        // When unapplied, remove association with the view
        CKComponentDelegateForwarder *proxy = view.ck_delegateProxy;
        proxy->_view = nil;
        view.ck_delegateProxy = nil;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [view performSelector:selector withObject:nil];
#pragma clang diagnostic pop

      }
    },
    @YES // Bogus value, we don't use it.
  };
}

@implementation CKComponentDelegateForwarder : NSObject

- (BOOL)respondsToSelector:(SEL)aSelector
{
  if ([super respondsToSelector:aSelector]) {
    return YES;
  } else {
    return std::find(_defn.begin(), _defn.end(), aSelector) != std::end(_defn);
  }
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
  CKComponent *responder = _view.ck_component;
  return [responder targetForAction:aSelector withSender:responder];
}

@end


@implementation UIView (CKDelegateProxy)

static const char kCKComponentDelegateProxyKey = ' ';

- (CKComponentDelegateForwarder *)ck_delegateProxy
{
  return objc_getAssociatedObject(self, &kCKComponentDelegateProxyKey);
}

- (void)ck_setDelegateProxy:(CKComponentDelegateForwarder *)delegateProxy
{
  objc_setAssociatedObject(self, &kCKComponentDelegateProxyKey, delegateProxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
