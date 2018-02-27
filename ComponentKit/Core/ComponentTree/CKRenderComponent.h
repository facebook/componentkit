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
 This protocol is being implemented by the components that has a render method: `CKSingleChildComponent` and `CKMultiChildComponent`.

 Please DO NOT implement a new component that conforms to this protocol;
 your component should subclass either from `CKSingleChildComponent` or `CKMultiChildComponent`.
 */
@protocol CKRenderComponent <CKComponentProtocol>

/*
 This method defines how a component behaves when the component tree is being constructed with
 'buildComponentTree:previousOwner:scopeRoot:stateUpdates'.

 Each component has a corresponding CKBaseTreeNode; this node holds the component's state and its children nodes.
 If a component is an owner component, its children nodes (CKBaseTreeNode) will be attached to its corresponding node.
 Otherwise, they will be attached to the component's owner.

 Return yes in case your component is the owner of its children components.
 Owner means that the component creates its children directly in its render method.

 For example:
 CKSingleChildComponent is an owner component.
 CKFlexboxComponent isn't; it receives its children as props in its constructor.

 Default values:
 CKSingleChildComponent returns YES
 CKMultiChildComponent returns NO
 */
+ (BOOL)isOwnerComponent;

@end
