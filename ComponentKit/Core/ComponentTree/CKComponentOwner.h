/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

/**
 This protocol defines how a component behaves when the component tree is being constructed by infrastructure:
 'buildComponentTree:previousOwner:scopeRootstateUpdates'.

 Each component has a corresponding CKBaseTreeNode; this node holds the state of the component and its children nodes.
 If a component is an owner component, its children nodes (CKBaseTreeNode) will be attached to its corresponding node.
 Otherwise, they will be attached to the same owner as the component itself.
 */
@protocol CKComponentOwner <NSObject>

/*
 Return yes in case your component is the owner of its children components.
 Owner means that the component creates its children directly in its render method.

 For example:
 CKSingleChildComponent is an owner component.
 CKFlexboxComponent isn't; it receives its children as props in its constructor.

 Default values:
 CKSingleChildComponent returns YES
 CKMultiChildComponent returns NO
 */
- (BOOL)isOwnerComponent;

@end
