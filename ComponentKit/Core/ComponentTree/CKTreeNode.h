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

#import <Foundation/Foundation.h>

#import <ComponentKit/CKComponentScopeTypes.h>
#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKComponentScopeHandle.h>
#import <ComponentKit/CKTreeNodeProtocol.h>

@protocol CKRenderComponentProtocol;

namespace CK {
namespace TreeNode {
  /**
  This function looks to see if the currently defined scope matches that of the given component; if so it returns the
  node corresponding to the current scope. Otherwise it returns nil.
  This is only meant to be called when constructing a component and as part of the implementation itself.
  */
  id<CKTreeNodeProtocol> nodeForComponent(id<CKComponentProtocol> component);
}
}

/**
 This object represents a node in the component tree.

 Each component has a corresponding CKTreeNode; this node holds the component's state.

 CKTreeNode is the base class of a tree node. It will be attached non-render components (CKComponent & CKCompositeComponent).
 */
@interface CKTreeNode : NSObject <CKTreeNodeProtocol>
{
  @package
  CKTreeNodeComponentKey _componentKey;
}

/** Base initializer */
- (instancetype)initWithPreviousNode:(id<CKTreeNodeProtocol>)previousNode
                         scopeHandle:(CKComponentScopeHandle *)scopeHandle;

/** Render initializer */
- (instancetype)initWithComponent:(id<CKRenderComponentProtocol>)component
                           parent:(id<CKTreeNodeWithChildrenProtocol>)parent
                   previousParent:(id<CKTreeNodeWithChildrenProtocol>)previousParent
                        scopeRoot:(CKComponentScopeRoot *)scopeRoot
                     stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates;

@property (nonatomic, strong, readonly) CKComponentScopeHandle *scopeHandle;

@end

#endif
