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
#import <ComponentKit/CKDefines.h>
#import <ComponentKit/CKBuildComponent.h>
#import <ComponentKit/CKComponentProtocol.h>
#import <ComponentKit/CKComponentScopeHandle.h>
#import <ComponentKit/CKGlobalConfig.h>
#import <ComponentKit/RCIterable.h>
#import <ComponentKit/CKTreeNodeTypes.h>
#import <ComponentKit/CKBuildComponentTreeParams.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CKSystraceListener;
@protocol CKDebugAnalyticsListener;
@class CKTreeNode;
@class CKTreeNode;

#if CK_NOT_SWIFT

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

#endif

/**
 The component that is hosted by a `CKTreeNodeProtocol`.
 It represents the component holding the the scope handle, capable of building a component tree (CKTreeNode).
 */
NS_SWIFT_NAME(TreeNodeComponentProtocol)
@protocol CKTreeNodeComponentProtocol<CKComponentProtocol, RCIterable>

#if CK_NOT_SWIFT

/** Reference to the component's scope handle. */
@property (nonatomic, strong, readonly, nullable) CKComponentScopeHandle *scopeHandle;

/**
 This method translates the component render method into a 'CKTreeNode'; a component tree.
 It's being called by the infra during the component tree creation.
 */
- (void)buildComponentTree:(CKTreeNode *)parent
            previousParent:(CKTreeNode *_Nullable)previousParent
                    params:(const CKBuildComponentTreeParams &)params
      parentHasStateUpdate:(BOOL)parentHasStateUpdate;

#endif

/** Ask the component to acquire a tree node. */
- (void)acquireTreeNode:(CKTreeNode *)treeNode;

/** Reference to the component's tree node. */
@property (nonatomic, strong, readonly, nullable) CKTreeNode *treeNode;

/** Get child at index; can be nil */
- (id<CKTreeNodeComponentProtocol> _Nullable)childAtIndex:(unsigned int)index;

@end

#if CK_NOT_SWIFT

/**
 A marker used as a performance optimization by CKRenderComponentProtocol components.

 If a component conforming to CKRenderComponentProtocol returns this value as its initial state,
 the infrastructure will SKIP creating a tree node, disabling state updates -- unless some other
 attribute of the component requires it (e.g. it has a controller).

 This is a performance optimization, since tree nodes are not free.
 */
id CKTreeNodeEmptyState(void);

#endif

NS_ASSUME_NONNULL_END
