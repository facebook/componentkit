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

#import <ComponentKit/CKComponentScopeHandle.h>

typedef int32_t CKTreeNodeIdentifier;
typedef std::tuple<Class, NSUInteger> CKTreeNodeComponentKey;

// Data structure that holds the ids of the tree nodes, that represent the components
// on a branch that had a state update.
typedef std::unordered_set<CKTreeNodeIdentifier> CKTreeNodeDirtyIds;

/**
 This protocol represents a node in the component tree.
 Each component has a corresponding CKTreeNodeProtocol; this node holds the state of the component.
 */

@protocol CKTreeNodeProtocol <NSObject>

@property (nonatomic, strong, readonly) CKComponent *component;
@property (nonatomic, strong, readonly) CKComponentScopeHandle *handle;
@property (nonatomic, assign, readonly) CKTreeNodeIdentifier nodeIdentifier;
@property (nonatomic, weak, readonly) id<CKTreeNodeProtocol> parent;

/** Returns the component's state */
- (id)state;

/** Returns the componeny key according to its current owner */
- (const CKTreeNodeComponentKey &)componentKey;

/** Returns the initial state of the component */
- (id)initialStateWithComponent:(CKComponent *)component;

@end

/**
 This protocol represents a node with multiple children in the component tree.

 Each component that is an owner component will have a corresponding CKTreeNodeWithChildrenProtocol.
 */

@protocol CKTreeNodeWithChildrenProtocol <CKTreeNodeProtocol>

- (std::vector<id<CKTreeNodeProtocol>>)children;

- (size_t)childrenSize;

/** Returns a component tree node according to its component key */
- (id<CKTreeNodeProtocol>)childForComponentKey:(const CKTreeNodeComponentKey &)key;

/** Creates a component key for a child node according to its component class; this method is being called once during the component tree creation */
- (CKTreeNodeComponentKey)createComponentKeyForChildWithClass:(id<CKComponentProtocol>)componentClass;

/** Save a child node in the parent node according to its component key; this method is being called once during the component tree creation */
- (void)setChild:(id<CKTreeNodeProtocol>)child forComponentKey:(const CKTreeNodeComponentKey &)componentKey;

@end
