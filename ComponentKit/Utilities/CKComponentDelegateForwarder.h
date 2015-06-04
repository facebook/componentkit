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

using CKComponentForwardedSelectors = std::vector<SEL>;

std::string CKIdentifierFromDelegateForwarderSelectors(const CKComponentForwardedSelectors& first);


/**
 This is intended for ComponentKit internal use only. This will make an object that forwards
 */
@interface CKComponentDelegateForwarder : NSObject

+ (instancetype)newWithSelectors:(CKComponentForwardedSelectors)selectors;

/**
 The view is used to find out where to start looking in the component responder chain.

 The forwarder will call [view.ck_component targetForAction: withSender:] to proxy to the responder chain, so this needs to be accurate.
 */
@property (nonatomic, weak) UIView *view;

@end


@interface NSObject (CKComponentDelegateProxy)

@property (nonatomic, strong, setter=ck_setDelegateProxy:) CKComponentDelegateForwarder *ck_delegateProxy;

@end

