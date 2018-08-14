/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKComponentProtocol.h>

/**
 This protocol is being implemented by the components that has a render method: `CKRenderComponent` and `CKRenderWithChildrenComponent`.

 Please DO NOT implement a new component that conforms to this protocol;
 your component should subclass either from `CKRenderComponent` or `CKRenderWithChildrenComponent`.
 */
@protocol CKRenderComponentProtocol <CKComponentProtocol>

/*
 Override this method in order to provide an initialState which depends on the component's props.
 Otherwise, override `+(id)initialState` instead.
 */
+ (id)initialStateWithComponent:(id<CKRenderComponentProtocol>)component;

/*
 Override this method in order to allow the infrastructure to reuse previous components.

 You can always assume that the `component` parameter is the same type as your component.

 The default value is `NO`
 */
- (BOOL)isEqualToComponent:(id<CKRenderComponentProtocol>)component;

@end
