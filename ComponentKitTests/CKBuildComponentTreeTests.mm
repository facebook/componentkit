/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <XCTest/XCTest.h>

#import "CKComponent.h"
#import "CKRenderComponent.h"
#import "CKRenderWithChildrenComponent.h"
#import "CKComponentInternal.h"
#import "CKButtonComponent.h"
#import "CKTreeNode.h"
#import "CKRenderTreeNodeWithChild.h"
#import "CKRenderTreeNodeWithChildren.h"
#import "CKThreadLocalComponentScope.h"

/** An helper class that inherits from 'CKRenderComponent'; render the component from the initializer */
@interface CKComponentTreeTestComponent_Render : CKRenderComponent
+ (instancetype)newWithComponent:(CKComponent *)component;
@end

/** An helper class that inherits from 'CKRenderWithChildrenComponent'; render the component froms the initializer */
@interface CKComponentTreeTestComponent_RenderWithChildren : CKRenderWithChildrenComponent
+ (instancetype)newWithChildren:(std::vector<CKComponent *>)children;
@end

#pragma mark - Tests

@interface CKBuildComponentTreeTests : XCTestCase
@end

@implementation CKBuildComponentTreeTests
{
  CKBuildComponentConfig _config;
}

#pragma mark - CKComponent

- (void)test_buildComponentTree_onCKComponent
{
  CKRenderTreeNodeWithChildren *root = [[CKRenderTreeNodeWithChildren alloc] init];
  CKComponent *c = [CKComponent newWithView:{} size:{}];
  [c buildComponentTree:root previousParent:nil params:{
    .scopeRoot = nil,
    .stateUpdates = {},
    .buildTrigger = BuildTrigger::NewTree,
    .treeNodeDirtyIds = {},
  } config:_config hasDirtyParent:NO];

  XCTAssertEqual(root.children.size(), 1);
  XCTAssertEqual(root.children[0].component, c);

  // Simulate a second tree creation.
  CKRenderTreeNodeWithChildren *root2 = [[CKRenderTreeNodeWithChildren alloc] init];
  CKComponent *c2 = [CKComponent newWithView:{} size:{}];
  [c2 buildComponentTree:root2 previousParent:root params:{
    .scopeRoot = nil,
    .stateUpdates = {},
    .buildTrigger = BuildTrigger::PropsUpdate,
    .treeNodeDirtyIds = {},
  } config:_config hasDirtyParent:NO];
  XCTAssertTrue(areTreesEqual(root, root2));
}

#pragma mark - CKRenderComponent

- (void)test_buildComponentTree_onCKRenderComponent
{
  CKRenderTreeNodeWithChildren *root = [[CKRenderTreeNodeWithChildren alloc] init];
  CKComponent *c = [CKComponent newWithView:{} size:{}];
  CKRenderComponent *renderComponent = [CKComponentTreeTestComponent_Render newWithComponent:c];
  [renderComponent buildComponentTree:root previousParent:nil params:{
    .scopeRoot = nil,
    .stateUpdates = {},
    .buildTrigger = BuildTrigger::NewTree,
    .treeNodeDirtyIds = {},
  } config:_config hasDirtyParent:NO];

  // Make sure the root has only one child.
  XCTAssertEqual(root.children.size(), 1);
  CKTreeNode *singleChildNode = root.children[0];
  verifyChildToParentConnection(root, singleChildNode, renderComponent);

  // Check the next level of the tree
  if ([singleChildNode isKindOfClass:[CKRenderTreeNodeWithChild class]]) {
    CKRenderTreeNodeWithChildren *parentNode = (CKRenderTreeNodeWithChildren *)singleChildNode;
    XCTAssertEqual(parentNode.children.size(), 1);
    CKTreeNode *componentNode = parentNode.children[0];
    verifyChildToParentConnection(parentNode, componentNode, c);
  } else {
    XCTFail(@"singleChildNode has to be CKRenderTreeNodeWithChild as it has a child.");
  }

  // Simulate a second tree creation.
  CKRenderTreeNodeWithChildren *root2 = [[CKRenderTreeNodeWithChildren alloc] init];
  CKComponent *c2 = [CKComponent newWithView:{} size:{}];
  CKRenderComponent *renderComponent2 = [CKComponentTreeTestComponent_Render newWithComponent:c2];
  [renderComponent2 buildComponentTree:root2 previousParent:root params:{
    .scopeRoot = nil,
    .stateUpdates = {},
    .buildTrigger = BuildTrigger::PropsUpdate,
    .treeNodeDirtyIds = {},
  } config:_config hasDirtyParent:NO];
  XCTAssertTrue(areTreesEqual(root, root2));
}

#pragma mark - CKRenderWithChildrenComponent

- (void)test_buildComponentTree_onCKRenderWithChildrenComponent
{
  CKRenderTreeNodeWithChildren *root = [[CKRenderTreeNodeWithChildren alloc] init];
  CKComponent *c10 = [CKComponent newWithView:{} size:{}];
  CKComponent *c11 = [CKComponent newWithView:{} size:{}];
  CKRenderWithChildrenComponent *renderWithChidlrenComponent = [CKComponentTreeTestComponent_RenderWithChildren newWithChildren:{c10, c11}];
  [renderWithChidlrenComponent buildComponentTree:root previousParent:nil params:{
    .scopeRoot = nil,
    .stateUpdates = {},
    .buildTrigger = BuildTrigger::NewTree,
    .treeNodeDirtyIds = {},
  } config:{} hasDirtyParent:NO];

  XCTAssertEqual(root.children.size(), 1);
  XCTAssertTrue(verifyComponentsInNode(root, @[renderWithChidlrenComponent]));

  // Verify that the child component has 2 children nodes.
  CKTreeNode *childNode = root.children[0];
  // Check the next level of the tree
  if ([childNode isKindOfClass:[CKRenderTreeNodeWithChildren class]]) {
    CKRenderTreeNodeWithChildren *parentNode = (CKRenderTreeNodeWithChildren *)childNode;
    XCTAssertEqual(parentNode.children.size(), 2);
    XCTAssertTrue(verifyComponentsInNode(parentNode, @[c10, c11]));
  } else {
    XCTFail(@"childNode has to be CKRenderTreeNodeWithChildren as it has children.");
  }

  // Simulate a second tree creation.
  CKRenderTreeNodeWithChildren *root2 = [[CKRenderTreeNodeWithChildren alloc] init];
  CKComponent *c20 = [CKComponent newWithView:{} size:{}];
  CKComponent *c21 = [CKComponent newWithView:{} size:{}];
  CKRenderWithChildrenComponent *renderWithChidlrenComponent2 = [CKComponentTreeTestComponent_RenderWithChildren newWithChildren:{c20, c21}];
  [renderWithChidlrenComponent2 buildComponentTree:root2 previousParent:root params:{
    .scopeRoot = nil,
    .stateUpdates = {},
    .buildTrigger = BuildTrigger::PropsUpdate,
    .treeNodeDirtyIds = {},
  } config:{} hasDirtyParent:NO];
  XCTAssertTrue(areTreesEqual(root, root2));
}

#pragma mark - Helpers

static BOOL verifyChildToParentConnection(id<CKTreeNodeWithChildrenProtocol> parentNode, CKTreeNode *childNode, CKComponent *c) {
  auto const componentKey = [childNode componentKey];
  auto const childComponent = [parentNode childForComponentKey:componentKey].component;
  return [childComponent isEqual:c];
}

/** Compare the components array to the components in the children nodes of 'parentNode' */
static BOOL verifyComponentsInNode(id<CKTreeNodeWithChildrenProtocol> parentNode, NSArray<CKComponent *> *components) {
  // Verify that the root holds two components has its direct children
  NSMutableSet<CKComponent *> *componentsFromTheTree = [NSMutableSet set];
  for (auto const node : parentNode.children) {
    [componentsFromTheTree addObject:node.component];
  }
  NSSet<CKComponent *> *componentsSet = [NSSet setWithArray:components];
  return [componentsSet isEqualToSet:componentsFromTheTree];
}

/** Compare the children of the trees recursively; returns true if the two trees are equal */
static BOOL areTreesEqual(id<CKTreeNodeWithChildrenProtocol> lhs, id<CKTreeNodeWithChildrenProtocol> rhs) {
  NSMutableSet<NSString *> *lhsChildrenIdentifiers = [NSMutableSet set];
  treeChildrenIdentifiers(lhs, lhsChildrenIdentifiers, 0);
  NSMutableSet<NSString *> *rhsChildrenIdentifiers = [NSMutableSet set];
  treeChildrenIdentifiers(rhs, rhsChildrenIdentifiers, 0);
  return [lhsChildrenIdentifiers isEqualToSet:rhsChildrenIdentifiers];
}

/** Iterate recursively over the tree and add its node identifiers to the set */
static void treeChildrenIdentifiers(id<CKTreeNodeWithChildrenProtocol> node, NSMutableSet<NSString *> *identifiers, int level) {
  for (auto const childNode : node.children) {
    // We add the child identifier + its level in the tree.
    [identifiers addObject:[NSString stringWithFormat:@"%d-%d",childNode.nodeIdentifier, level]];
    if ([childNode isKindOfClass:[CKRenderTreeNodeWithChildren class]]) {
      treeChildrenIdentifiers((CKRenderTreeNodeWithChildren *)childNode, identifiers, level+1);
    }
  }
}

@end

#pragma mark - Helper classes

@implementation CKComponentTreeTestComponent_Render
{
  CKComponent *_component;
}
+ (instancetype)newWithComponent:(CKComponent *)component
{
  auto const c = [super newWithView:{} size:{}];
  if (c) {
    c->_component = component;
  }
  return c;
}
- (CKComponent *)render:(id)state
{
  return _component;
}
@end

@implementation CKComponentTreeTestComponent_RenderWithChildren
{
  std::vector<CKComponent *> _children;
}
+ (instancetype)newWithChildren:(std::vector<CKComponent *>)children
{
  auto const c = [super newWithView:{} size:{}];
  if (c) {
    c->_children = children;
  }
  return c;
}
- (std::vector<CKComponent *>)renderChildren:(id)state
{
  return _children;
}
@end
