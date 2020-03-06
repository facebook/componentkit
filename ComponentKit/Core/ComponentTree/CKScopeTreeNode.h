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

#import <ComponentKit/CKTreeNode.h>
#import <ComponentKit/CKTreeNodeProtocol.h>
#import <ComponentKit/CKComponentScopeFrame.h>

extern NSUInteger const kTreeNodeParentBaseKey;
extern NSUInteger const kTreeNodeOwnerBaseKey;

@protocol CKTreeNodeProtocol;

/**
 This object is a bridge between CKComponentScope and CKTreeNode.

 It represents a node with children in the component tree.
 */
@interface CKScopeTreeNode : CKTreeNode <CKTreeNodeWithChildrenProtocol, CKComponentScopeFrameProtocol>
{
  @package
  std::vector<std::tuple<CKTreeNodeComponentKey, id<CKTreeNodeProtocol>>> _children;
}

- (CKTreeNodeComponentKey)createKeyForComponentClass:(Class<CKComponentProtocol>)componentClass
                                          identifier:(id)identifier
                                                keys:(const std::vector<id<NSObject>> &)keys;
- (CKScopeTreeNode *)childScopeForComponentKey:(const CKTreeNodeComponentKey &)scopeNodeKey;
- (void)setChildScope:(CKScopeTreeNode *)child forComponentKey:(const CKTreeNodeComponentKey &)componentKey;

@end

#endif
