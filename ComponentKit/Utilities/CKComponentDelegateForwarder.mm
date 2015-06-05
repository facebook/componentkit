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

#import "CKAssert.h"
#import "CKComponentViewInterface.h"
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

@implementation CKComponentDelegateForwarder : NSObject

+ (instancetype)newWithSelectors:(CKComponentForwardedSelectors)selectors
{
  CKComponentDelegateForwarder *f = [[self alloc] init];
  if (!f) return nil;

  f->_selectors = selectors;

  return f;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
  if ([super respondsToSelector:aSelector]) {
    return YES;
  } else {
    BOOL responds = std::find(_selectors.begin(), _selectors.end(), aSelector) != std::end(_selectors);
    return responds;
  }
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
  CKComponent *responder = _view.ck_component;
  return [responder targetForAction:aSelector withSender:responder];
}

@end


@implementation NSObject (CKComponentDelegateForwarder)

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
