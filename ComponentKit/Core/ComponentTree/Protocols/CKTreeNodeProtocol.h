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
#import <ComponentKit/CKTreeNodeTypes.h>

@protocol CKSystraceListener;

/*
 Will be used to gather information reagrding reused components during debug only.
 */
struct CKTreeNodeReuseInfo {
  CKTreeNodeIdentifier parentNodeIdentifier;
  Class klass;
  Class parentKlass;
  NSUInteger reuseCounter;
};

typedef std::unordered_map<CKTreeNodeIdentifier, CKTreeNodeReuseInfo> CKTreeNodeReuseMap;

/**
 Params struct for the `buildComponentTree:` method.
 **/
struct CKBuildComponentTreeParams {
  // Weak reference to the scope root of the new generation.
  __weak CKComponentScopeRoot *scopeRoot;

  // Weak reference to the scope root of the previous generation.
  __weak CKComponentScopeRoot *previousScopeRoot;

  // A map of state updates
  const CKComponentStateUpdateMap &stateUpdates;

  // Colleciton of nodes that are marked as dirty.
  // @discussion "Dirty nodes" are used to implement optimizations as faster state updates and faster props updates.
  const CKTreeNodeDirtyIds &treeNodeDirtyIds;

  // The trigger for initiating a new generation
  BuildTrigger buildTrigger;

  // The current systrace listener. Can be nil if systrace is not enabled.
  id<CKSystraceListener> systraceListener;

  // When enabled, all the comopnents will be regenerated (no component reuse optimiztions).
  BOOL ignoreComponentReuseOptimizations = NO;
  
  // When enabled, we will cache the layout in render components and reuse it during a component reuse. */
  BOOL enableLayoutCache = NO;
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

#if DEBUG
// These two methods are in DEBUG only in order to save memory.
// Once we build the component tree (by calling `buildComponentTree:`) by default,
// we can swap the the scopeHandle ref with the treeNode one.

/** Ask the component to acquire a tree node. */
- (void)acquireTreeNode:(id<CKTreeNodeProtocol>)treeNode;

/** Reference to the component's tree node. */
- (id<CKTreeNodeProtocol>)treeNode;
#endif

@end

/**
 This protocol represents a node in the component tree.
 Each component has a corresponding CKTreeNodeProtocol; this node holds the state of the component.
 */

@protocol CKTreeNodeProtocol <NSObject>

@property (nonatomic, strong, readonly) id<CKTreeNodeComponentProtocol> component;
@property (nonatomic, strong, readonly) CKComponentScopeHandle *handle;
@property (nonatomic, assign, readonly) CKTreeNodeIdentifier nodeIdentifier;

/** Returns the component's state */
- (id)state;

/** Returns the componeny key according to its current owner */
- (const CKTreeNodeComponentKey &)componentKey;

/** This method should be called after a node has been reused */
- (void)didReuseInScopeRoot:(CKComponentScopeRoot *)scopeRoot fromPreviousScopeRoot:(CKComponentScopeRoot *)previousScopeRoot;

#if DEBUG
/** Returns a multi-line string describing this node and its children nodes */
- (NSString *)debugDescription;
- (NSArray<NSString *> *)debugDescriptionNodes;
#endif

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
- (CKTreeNodeComponentKey)createComponentKeyForChildWithClass:(id<CKComponentProtocol>)componentClass
                                                   identifier:(id<NSObject>)identifier;

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
