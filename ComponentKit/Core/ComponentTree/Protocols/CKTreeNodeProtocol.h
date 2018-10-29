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

#import <ComponentKit/CKBuildComponent.h>
#import <ComponentKit/CKComponentProtocol.h>
#import <ComponentKit/CKComponentScopeHandle.h>

typedef int32_t CKTreeNodeIdentifier;
typedef std::tuple<Class, NSUInteger> CKTreeNodeComponentKey;

// Data structure that holds the ids of the tree nodes, that represent the components
// on a branch that had a state update.
typedef std::unordered_set<CKTreeNodeIdentifier> CKTreeNodeDirtyIds;

/**
 Params struct for the `buildComponentTree:` method.
 **/
struct CKBuildComponentTreeParams {
  // Weak reference to the scope root of the new generation
  __weak CKComponentScopeRoot *scopeRoot;

  // A map of state updates
  const CKComponentStateUpdateMap &stateUpdates;

  // Colleciton of nodes that are marked as dirty.
  // @discussion "Dirty nodes" are used to implement optimizations as faster state updates and faster props updates.
  const CKTreeNodeDirtyIds &treeNodeDirtyIds;

  //  Enable faster state updates optimization for render components.
  BOOL enableFasterStateUpdates = NO;

  //  Enable faster props updates optimization for render components.
  BOOL enableFasterPropsUpdates = NO;

  // Enable render support in CKComponentContext
  BOOL enableContextRenderSupport = NO;

  // The trigger for initiating a new generation
  BuildTrigger buildTrigger;
};

@protocol CKTreeNodeWithChildrenProtocol;


/**
 The component that is hosted by a `CKTreeNodeProtocol`.
 It represents the component holding the the scope handle, capable of building a component tree (CKTreeNode).
 */
@protocol CKTreeNodeComponentProtocol<CKComponentProtocol>

/** Reference to the component's scope handle. */
- (CKComponentScopeHandle *)scopeHandle;

/** Ask the component to acquire a scope handle. */
- (void)acquireScopeHandle:(CKComponentScopeHandle *)scopeHandle;

/**
 This method translates the component render method into a 'CKTreeNode'; a component tree.
 It's being called by the infra during the component tree creation.
 */
- (void)buildComponentTree:(id<CKTreeNodeWithChildrenProtocol>)parent
            previousParent:(id<CKTreeNodeWithChildrenProtocol>)previousParent
                    params:(const CKBuildComponentTreeParams &)params
      parentHasStateUpdate:(BOOL)parentHasStateUpdate;

/** Returns true if the component requires scope handle */
+ (BOOL)requiresScopeHandle;

@end

/**
 This protocol represents a node in the component tree.
 Each component has a corresponding CKTreeNodeProtocol; this node holds the state of the component.
 */

@protocol CKTreeNodeProtocol <NSObject>

@property (nonatomic, strong, readonly) id<CKTreeNodeComponentProtocol> component;
@property (nonatomic, strong, readonly) CKComponentScopeHandle *handle;
@property (nonatomic, assign, readonly) CKTreeNodeIdentifier nodeIdentifier;
@property (nonatomic, weak, readonly) id<CKTreeNodeProtocol> parent;

/** Returns the component's state */
- (id)state;

/** Returns the componeny key according to its current owner */
- (const CKTreeNodeComponentKey &)componentKey;

/** Returns the initial state of the component */
- (id)initialStateWithComponent:(id<CKTreeNodeComponentProtocol>)component;

/** Returns whether component requires a scope handle */
- (BOOL)componentRequiresScopeHandle:(Class<CKTreeNodeComponentProtocol>)component;

/** Update the parent after component's reuse (this method is not thread safe - please use it carefully) */
- (void)didReuseByParent:(id<CKTreeNodeProtocol>)parent;

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

/**
 Default empty state for CKRenderComponentProtocol components.

 If a CKRenderComponentProtocol returns any state other than `CKTreeNodeEmptyState` (including nil)
 - the infra will create it a scope handle and will support a state update.
 Othwerwise, the component will be stateless.
 */
@interface CKTreeNodeEmptyState : NSObject
+ (id)emptyState;
@end
