/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKRenderLayoutWithChildrenComponent.h"

#import "CKBuildComponent.h"
#import "CKRenderHelpers.h"
#import "CKComponentInternal.h"

@implementation CKRenderLayoutWithChildrenComponent
{
  std::vector<id<CKTreeNodeComponentProtocol>> _children;
}

- (std::vector<CKComponent *>)renderChildren:(id)state
{
  CKFailAssert(@"%@ MUST override the '%@' method.", [self class], NSStringFromSelector(_cmd));
  return {};
}

- (void)buildComponentTree:(id<CKTreeNodeWithChildrenProtocol>)parent
            previousParent:(id<CKTreeNodeWithChildrenProtocol>)previousParent
                    params:(const CKBuildComponentTreeParams &)params
      parentHasStateUpdate:(BOOL)parentHasStateUpdate
{
  CKRender::ComponentTree::RenderLayout::buildWithChildren(self, &_children ,parent, previousParent, params, parentHasStateUpdate);
}

#pragma mark - CKRenderComponentProtocol

+ (id)initialStateWithComponent:(id<CKRenderComponentProtocol>)component
{
  return [self initialState];
}

+ (id)initialState
{
  return [CKTreeNodeEmptyState emptyState];
}

- (BOOL)shouldComponentUpdate:(id<CKRenderComponentProtocol>)component
{
  return YES;
}

- (void)didReuseComponent:(id<CKRenderComponentProtocol>)component {}

- (id)componentIdentifier
{
  return nil;
}

#pragma mark - CKTreeNodeWithChildrenProtocol

- (std::vector<id<CKTreeNodeProtocol>>)children
{
  std::vector<id<CKTreeNodeProtocol>> children;
  for (auto const &child : _children) {
    children.push_back(child);
  }
  return children;
}

- (size_t)childrenSize
{
  return _children.size();
}

- (id<CKTreeNodeProtocol>)childForComponentKey:(const CKTreeNodeComponentKey &)key
{
  for (auto const &child : _children) {
    auto componentKey = [child.component componentKey];
    if (CK::TreeNode::areKeysEqual(componentKey, key)) {
      return child;
    }
    if (CK::TreeNode::isKeyEmpty(componentKey)) {
      break;
    }
  }
  return nil;
}

- (CKTreeNodeComponentKey)createComponentKeyForChildWithClass:(id<CKComponentProtocol>)componentClass
                                                   identifier:(id<NSObject>)identifier
{
  // Create **parent** based key counter.
  NSUInteger keyCounter = 0;
  for (auto const &child : _children) {
    auto childKey = child.componentKey;
    if (std::get<0>(childKey) == componentClass && CKObjectIsEqual(std::get<2>(childKey), identifier)) {
      keyCounter += 1;
    } else if (CK::TreeNode::isKeyEmpty(childKey)) {
      break;
    }
  }
  return std::make_tuple(componentClass, keyCounter, identifier);
}

- (void)setChild:(id<CKTreeNodeProtocol>)child forComponentKey:(const CKTreeNodeComponentKey &)componentKey {}

- (void)didReuseInScopeRoot:(CKComponentScopeRoot *)scopeRoot fromPreviousScopeRoot:(CKComponentScopeRoot *)previousScopeRoot
{
  [super didReuseInScopeRoot:scopeRoot fromPreviousScopeRoot:previousScopeRoot];
  for (auto const &child : _children) {
    [child didReuseInScopeRoot:scopeRoot fromPreviousScopeRoot:previousScopeRoot];
  }
}

#if DEBUG
- (NSArray<NSString *> *)debugDescriptionNodes
{
  NSMutableArray<NSString *> *debugDescriptionNodes = [NSMutableArray arrayWithArray:[super debugDescriptionNodes]];
  for (auto const &child : _children) {
    for (NSString *s in [child debugDescriptionNodes]) {
      [debugDescriptionNodes addObject:[@"  " stringByAppendingString:s]];
    }
  }
  return debugDescriptionNodes;
}
#endif

@end
