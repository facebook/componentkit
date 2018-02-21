/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKBaseTreeNode.h"

#include <vector>

/**
 This object represents a node with multiple children in the component tree.

 Each component that is an owner component will have a corresponding CKOwnerTreeNode.
 */

@interface CKTreeNode : CKBaseTreeNode

- (std::vector<CKBaseTreeNode *>)children;

/** Returns a component tree node according to its component key */
- (CKBaseTreeNode *)childForComponentKey:(const CKComponentKey &)key;

/** Creates a component key for a child node according to its component class; this method is being called once during the component tree creation */
- (CKComponentKey)createComponentKeyForChildWithClass:(id<CKComponentProtocol>)componentClass;

/** Save a child node in the parent node according to its component key; this method is being called once during the component tree creation */
- (void)setChild:(CKBaseTreeNode *)child forComponentKey:(const CKComponentKey &)componentKey;

@end
