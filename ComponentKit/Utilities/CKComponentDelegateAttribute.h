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
#import <vector>

/** It's necessary to specify a list of selectors your delegate will implement, because we have to answer the question "respondsToSelector:" without access to the responder chain, since it's is frequently cached as an optimization in objects with delegates. */

using CKComponentDelegateAttributeDefinition = std::vector<SEL>;

/**
 Returns a view attribute that proxies the delegate onto the component responder chain.
 You must handle the method in the component for which this is an attribute, or an ancestor,
 or an assertion will fire (since there is no sensible default for a delegate method to return).
 
 Usage:

 [CKComponent
 newWithView:{[UIScrollView class], {
   CKComponentDelegateAttribute(@selector(setDelegate:), {
   @selector(scrollViewDidScroll:),
   @selector(scrollViewDidZoom:),
   })
 }}
 size:{}] ...
 
 Then you can implement -scrollViewDidScroll: in your composite component, that potentially has a number of intervening components before the scroll component.

 */
CKComponentViewAttributeValue CKComponentDelegateAttribute(SEL selector,
                                                           CKComponentDelegateAttributeDefinition definition);
