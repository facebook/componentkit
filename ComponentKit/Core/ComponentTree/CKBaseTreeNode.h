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

#import <ComponentKit/CKComponentScopeTypes.h>
#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKComponentScopeHandle.h>

typedef int32_t CKTreeNodeIdentifier;
typedef std::tuple<Class, NSUInteger> CKComponentKey;

@class CKTreeNode;

/**
 This object represents a node in the component tree.

 Each component has a corresponding CKBaseTreeNode; this node holds the state of the component and its children nodes.

 CKBaseTreeNodeis the base class of a tree node. It will be atatched to leaf components only (CKComponent).
 */
@interface CKBaseTreeNode: NSObject

- (instancetype)initWithComponent:(CKComponent *)component
                            owner:(CKTreeNode *)owner
                    previousOwner:(CKTreeNode *)previousOwner
                        scopeRoot:(CKComponentScopeRoot *)scopeRoot
                     stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates;

@property (nonatomic, strong, readonly) CKComponent *component;
@property (nonatomic, strong, readonly) CKComponentScopeHandle *handle;
@property (nonatomic, assign, readonly) CKTreeNodeIdentifier nodeIdentifier;

/** Returns the component's state */
- (id)state;

/** Returns the componeny key according to its current owner */
- (const CKComponentKey &)componentKey;

@end
