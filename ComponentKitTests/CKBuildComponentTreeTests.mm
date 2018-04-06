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
#import "CKOwnerTreeNode.h"
#import "CKThreadLocalComponentScope.h"

/** An helper class that inherits from 'CKRenderComponent'; render the component from the initializer */
@interface CKComponentTreeTestComponent_Render : CKRenderComponent
+ (instancetype)newWithComponent:(CKComponent *)component;
@end

/** Same as 'CKComponentTreeTestComponent_Render', but overrides the CKRenderComponentProtocol and returns: isOwnerComponent = NO */
@interface CKComponentTreeTestComponent_NonOwner_Render : CKComponentTreeTestComponent_Render
@end

/** An helper class that inherits from 'CKRenderWithChildrenComponent'; render the component froms the initializer */
@interface CKComponentTreeTestComponent_RenderWithChildren : CKRenderWithChildrenComponent
+ (instancetype)newWithChildren:(std::vector<CKComponent *>)children;
@end

/** Same as 'CKComponentTreeTestComponent_RenderWithChildren', but overrides the CKRenderComponentProtocol and returns: isOwnerComponent = YES */
@interface CKComponentTreeTestComponent_Owner_RenderWithChildren : CKComponentTreeTestComponent_RenderWithChildren
@end

#pragma mark - Tests

@interface CKBuildComponentTreeTests : XCTestCase
@end

@implementation CKBuildComponentTreeTests

#pragma mark - CKComponent

- (void)test_buildComponentTree_onCKComponent
{
  CKOwnerTreeNode *root = [[CKOwnerTreeNode alloc] init];
  CKComponent *c = [CKComponent newWithView:{} size:{}];
  [c buildComponentTree:root previousOwner:nil scopeRoot:nil stateUpdates:{}];

  XCTAssertEqual(root.children.size(), 1);
  XCTAssertEqual(root.children[0].component, c);

  // Simulate a second tree creation.
  CKOwnerTreeNode *root2 = [[CKOwnerTreeNode alloc] init];
  CKComponent *c2 = [CKComponent newWithView:{} size:{}];
  [c2 buildComponentTree:root2 previousOwner:root scopeRoot:nil stateUpdates:{}];
  XCTAssertTrue(areTreesEqual(root, root2));
}

#pragma mark - CKRenderComponent

- (void)test_buildComponentTree_onCKRenderComponent
{
  CKOwnerTreeNode *root = [[CKOwnerTreeNode alloc] init];
  CKComponent *c = [CKComponent newWithView:{} size:{}];
  CKRenderComponent *renderComponent = [CKComponentTreeTestComponent_Render newWithComponent:c];
  [renderComponent buildComponentTree:root previousOwner:nil scopeRoot:nil stateUpdates:{}];

  // Make sure the root has only one child.
  XCTAssertEqual(root.children.size(), 1);
  CKTreeNode *singleChildNode = root.children[0];
  verifyChildToParentConnection(root, singleChildNode, renderComponent);

  // Check the next level of the tree
  if ([singleChildNode isKindOfClass:[CKOwnerTreeNode class]]) {
    CKOwnerTreeNode *parentNode = (CKOwnerTreeNode *)singleChildNode;
    XCTAssertEqual(parentNode.children.size(), 1);
    CKTreeNode *componentNode = parentNode.children[0];
    verifyChildToParentConnection(parentNode, componentNode, c);
  } else {
    XCTFail(@"singleChildNode has to be CKOwnerTreeNode as it has children.");
  }

  // Simulate a second tree creation.
  CKOwnerTreeNode *root2 = [[CKOwnerTreeNode alloc] init];
  CKComponent *c2 = [CKComponent newWithView:{} size:{}];
  CKRenderComponent *renderComponent2 = [CKComponentTreeTestComponent_Render newWithComponent:c2];
  [renderComponent2 buildComponentTree:root2 previousOwner:root scopeRoot:nil stateUpdates:{}];
  XCTAssertTrue(areTreesEqual(root, root2));
}

- (void)test_buildComponentTree_onCKRenderComponent_overrideNonOwnerComponent
{
  CKOwnerTreeNode *root = [[CKOwnerTreeNode alloc] init];
  CKComponent *c = [CKComponent newWithView:{} size:{}];
  CKRenderComponent *renderNoOwnerComponent = [CKComponentTreeTestComponent_NonOwner_Render newWithComponent:c];
  [renderNoOwnerComponent buildComponentTree:root previousOwner:nil scopeRoot:nil stateUpdates:{}];

  // As singleChildNoOwnerComponent is not an owner, the root should have 2 children.
  XCTAssertEqual(root.children.size(), 2);
  XCTAssertTrue(verifyComponentsInNode(root, @[renderNoOwnerComponent, c]));

  // Simulate a second tree creation.
  CKOwnerTreeNode *root2 = [[CKOwnerTreeNode alloc] init];
  CKComponent *c2 = [CKComponent newWithView:{} size:{}];
  CKRenderComponent *renderNoOwnerComponent2 = [CKComponentTreeTestComponent_NonOwner_Render newWithComponent:c2];
  [renderNoOwnerComponent2 buildComponentTree:root2 previousOwner:root scopeRoot:nil stateUpdates:{}];
  XCTAssertTrue(areTreesEqual(root, root2));
}

#pragma mark - CKRenderWithChildrenComponent

- (void)test_buildComponentTree_onCKRenderWithChildrenComponent
{
  CKOwnerTreeNode *root = [[CKOwnerTreeNode alloc] init];
  CKComponent *c10 = [CKComponent newWithView:{} size:{}];
  CKComponent *c11 = [CKComponent newWithView:{} size:{}];
  CKRenderWithChildrenComponent *renderWithChidlrenComponent = [CKComponentTreeTestComponent_RenderWithChildren newWithChildren:{c10, c11}];
  [renderWithChidlrenComponent buildComponentTree:root previousOwner:nil scopeRoot:nil stateUpdates:{}];

  XCTAssertEqual(root.children.size(), 3);
  XCTAssertTrue(verifyComponentsInNode(root, @[renderWithChidlrenComponent, c10, c11]));

  // Simulate a second tree creation.
  CKOwnerTreeNode *root2 = [[CKOwnerTreeNode alloc] init];
  CKComponent *c20 = [CKComponent newWithView:{} size:{}];
  CKComponent *c21 = [CKComponent newWithView:{} size:{}];
  CKRenderWithChildrenComponent *renderWithChidlrenComponent2 = [CKComponentTreeTestComponent_RenderWithChildren newWithChildren:{c20, c21}];
  [renderWithChidlrenComponent2 buildComponentTree:root2 previousOwner:root scopeRoot:nil stateUpdates:{}];
  XCTAssertTrue(areTreesEqual(root, root2));
}

- (void)test_buildComponentTree_onCKRenderWithChildrenComponent_MakeGroupAnOwnerComponent
{
  CKOwnerTreeNode *root = [[CKOwnerTreeNode alloc] init];
  CKComponent *c10 = [CKComponent newWithView:{} size:{}];
  CKComponent *c11 = [CKComponent newWithView:{} size:{}];
  CKRenderWithChildrenComponent *renderWithChidlrenComponent = [CKComponentTreeTestComponent_Owner_RenderWithChildren newWithChildren:{c10, c11}];
  [renderWithChidlrenComponent buildComponentTree:root previousOwner:nil scopeRoot:nil stateUpdates:{}];

  XCTAssertEqual(root.children.size(), 1);
  XCTAssertTrue(verifyComponentsInNode(root, @[renderWithChidlrenComponent]));

  // Verify that the child component has 2 children nodes.
  CKTreeNode *childNode = root.children[0];
  // Check the next level of the tree
  if ([childNode isKindOfClass:[CKOwnerTreeNode class]]) {
    CKOwnerTreeNode *parentNode = (CKOwnerTreeNode *)childNode;
    XCTAssertEqual(parentNode.children.size(), 2);
    XCTAssertTrue(verifyComponentsInNode(parentNode, @[c10, c11]));
  } else {
    XCTFail(@"childNode has to be CKOwnerTreeNode as it has children.");
  }

  // Simulate a second tree creation.
  CKOwnerTreeNode *root2 = [[CKOwnerTreeNode alloc] init];
  CKComponent *c20 = [CKComponent newWithView:{} size:{}];
  CKComponent *c21 = [CKComponent newWithView:{} size:{}];
  CKRenderWithChildrenComponent *renderWithChidlrenComponent2 = [CKComponentTreeTestComponent_Owner_RenderWithChildren newWithChildren:{c20, c21}];
  [renderWithChidlrenComponent2 buildComponentTree:root2 previousOwner:root scopeRoot:nil stateUpdates:{}];
  XCTAssertTrue(areTreesEqual(root, root2));
}

#pragma mark - Helpers

static BOOL verifyChildToParentConnection(CKOwnerTreeNode * parentNode, CKTreeNode *childNode, CKComponent *c) {
  auto const componentKey = [childNode componentKey];
  auto const childComponent = [parentNode childForComponentKey:componentKey].component;
  return [childComponent isEqual:c];
}

/** Compare the components array to the components in the children nodes of 'parentNode' */
static BOOL verifyComponentsInNode(CKOwnerTreeNode *parentNode, NSArray<CKComponent *> *components) {
  // Verify that the root holds two components has its direct children
  NSMutableSet<CKComponent *> *componentsFromTheTree = [NSMutableSet set];
  for (auto const node : parentNode.children) {
    [componentsFromTheTree addObject:node.component];
  }
  NSSet<CKComponent *> *componentsSet = [NSSet setWithArray:components];
  return [componentsSet isEqualToSet:componentsFromTheTree];
}

/** Compare the children of the trees recursively; returns true if the two trees are equal */
static BOOL areTreesEqual(CKOwnerTreeNode *lhs, CKOwnerTreeNode *rhs) {
  NSMutableSet<NSString *> *lhsChildrenIdentifiers = [NSMutableSet set];
  treeChildrenIdentifiers(lhs, lhsChildrenIdentifiers, 0);
  NSMutableSet<NSString *> *rhsChildrenIdentifiers = [NSMutableSet set];
  treeChildrenIdentifiers(rhs, rhsChildrenIdentifiers, 0);
  return [lhsChildrenIdentifiers isEqualToSet:rhsChildrenIdentifiers];
}

/** Iterate recursively over the tree and add its node identifiers to the set */
static void treeChildrenIdentifiers(CKOwnerTreeNode *node, NSMutableSet<NSString *> *identifiers, int level) {
  for (auto const childNode : node.children) {
    // We add the child identifier + its level in the tree.
    [identifiers addObject:[NSString stringWithFormat:@"%d-%d",childNode.nodeIdentifier, level]];
    if ([childNode isKindOfClass:[CKOwnerTreeNode class]]) {
      treeChildrenIdentifiers((CKOwnerTreeNode *)childNode, identifiers, level+1);
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

@implementation CKComponentTreeTestComponent_NonOwner_Render
+ (BOOL)isOwnerComponent
{
  return NO;
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

@implementation CKComponentTreeTestComponent_Owner_RenderWithChildren
+ (BOOL)isOwnerComponent
{
  return YES;
}
@end
