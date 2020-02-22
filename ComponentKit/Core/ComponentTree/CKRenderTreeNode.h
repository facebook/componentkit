/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKDefines.h>

#if CK_NOT_SWIFT

#import <ComponentKit/CKScopeTreeNode.h>

@protocol CKTreeNodeComponentProtocol;

/**
 This object is a bridge between CKComponentScope and CKTreeNode.

 It represents a node for CKRenderComponent component in the component tree.
 */
@interface CKRenderTreeNode : CKScopeTreeNode

/** Will be called after buildComponentTree: */
+ (void)didBuildComponentTree:(id<CKTreeNodeProtocol>)node;

/** Will be called after component reuse */
- (void)didReuseRenderNode:(CKRenderTreeNode *)node
                 scopeRoot:(CKComponentScopeRoot *)scopeRoot
         previousScopeRoot:(CKComponentScopeRoot *)previousScopeRoot
       mergeTreeNodesLinks:(BOOL)mergeTreeNodesLinks;

@end

#endif
