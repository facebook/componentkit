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

@interface UIView (CKDelegateProxy)

@property (nonatomic, strong, setter=ck_setDelegateProxy:) CKComponentDelegateForwarder *ck_delegateProxy;

@end

CKComponentViewAttributeValue CKComponentDelegateAttribute(SEL selector,
                                                           CKComponentForwardedSelectors selectors)
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
      std::string(sel_getName(selector)) + CKIdentifierFromDelegateForwarderSelectors(selectors),
      ^(UIView *view, id value){

        // Create a proxy for this set of selectors

        CKCAssertNil(view.ck_delegateProxy,
                     @"Unsupported: registered two delegate proxies for the same view: %@ %@", view, view.ck_delegateProxy);

        CKComponentDelegateForwarder *proxy = [CKComponentDelegateForwarder newWithSelectors:selectors];
        proxy.view = view;
        view.ck_delegateProxy = proxy;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [view performSelector:selector withObject:proxy];
#pragma clang diagnostic pop

      },
      ^(UIView *view, id value){

        // When unapplied, remove association with the view
        CKComponentDelegateForwarder *proxy = view.ck_delegateProxy;
        proxy.view = nil;
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