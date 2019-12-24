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
#import <ComponentKit/CKGlobalConfig.h>
#import <ComponentKit/CKIterable.h>
#import <ComponentKit/CKTreeNodeTypes.h>

@protocol CKSystraceListener;
@protocol CKDebugAnalyticsListener;

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
  CKBuildTrigger buildTrigger;

  // The current systrace listener. Can be nil if systrace is not enabled.
  id<CKSystraceListener> systraceListener;

  // Collect tree node information for logging.
  BOOL shouldCollectTreeNodeCreationInformation;

  // When disabled, all the comopnents will be regenerated (no component reuse optimiztions). Enabled by default.
  BOOL enableComponentReuseOptimizations = YES;
};

@protocol CKTreeNodeWithChildrenProtocol;

/**
 The component that is hosted by a `CKTreeNodeProtocol`.
 It represents the component holding the the scope handle, capable of building a component tree (CKTreeNode).
 */
@protocol CKTreeNodeComponentProtocol<CKComponentProtocol, CKIterable>

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

/** Get child at index; can be nil */
- (id<CKTreeNodeComponentProtocol>)childAtIndex:(unsigned int)index;
#endif

@end

/**
 This protocol represents a node in the component tree.
 Each component has a corresponding CKTreeNodeProtocol; this node holds the state of the component.
 */

@protocol CKTreeNodeProtocol <NSObject>

- (id<CKTreeNodeComponentProtocol>)component;
- (CKComponentScopeHandle *)scopeHandle;
- (CKTreeNodeIdentifier)nodeIdentifier;

/** Returns the component's state */
- (id)state;

/** Returns the componeny key according to its current owner */
- (const CKTreeNodeComponentKey &)componentKey;

/** This method should be called after a node has been reused */
- (void)didReuseInScopeRoot:(CKComponentScopeRoot *)scopeRoot fromPreviousScopeRoot:(CKComponentScopeRoot *)previousScopeRoot;

/** This method should be called on nodes that have been created from CKComponentScope */
- (void)linkComponent:(id<CKTreeNodeComponentProtocol>)component
             toParent:(id<CKTreeNodeWithChildrenProtocol>)parent
       previousParent:(id<CKTreeNodeWithChildrenProtocol>)previousParent
               params:(const CKBuildComponentTreeParams &)params;

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
 A marker used as a performance optimization by CKRenderComponentProtocol components.

 If a component conforming to CKRenderComponentProtocol returns this value as its initial state,
 the infrastructure will SKIP creating a tree node, disabling state updates -- unless some other
 attribute of the component requires it (e.g. it has a controller).

 This is a performance optimization, since tree nodes are not free.
 */
id CKTreeNodeEmptyState(void);
