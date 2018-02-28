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
#import "CKSingleChildComponent.h"
#import "CKMultiChildComponent.h"
#import "CKComponentInternal.h"
#import "CKButtonComponent.h"
#import "CKTreeNode.h"
#import "CKOwnerTreeNode.h"
#import "CKThreadLocalComponentScope.h"

/** An helper class that inherits from 'CKSingleChildComponent'; render the component from the initializer */
@interface CKComponentTreeTestComponent_SingleChild : CKSingleChildComponent
+ (instancetype)newWithComponent:(CKComponent *)component;
@end

/** Same as 'CKComponentTreeTestComponent_SingleChild', but overrides the CKRenderComponent and returns: isOwnerComponent = NO */
@interface CKComponentTreeTestComponent_NonOwner_SingleChild : CKComponentTreeTestComponent_SingleChild
@end

/** An helper class that inherits from 'CKMultiChildComponent'; render the component froms the initializer */
@interface CKComponentTreeTestComponent_MultiChild : CKMultiChildComponent
+ (instancetype)newWithChildren:(std::vector<CKComponent *>)children;
@end

/** Same as 'CKComponentTreeTestComponent_MultiChild', but overrides the CKRenderComponent and returns: isOwnerComponent = YES */
@interface CKComponentTreeTestComponent_Owner_MultiChild : CKComponentTreeTestComponent_MultiChild
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

#pragma mark - CKSingleChildComponent

- (void)test_buildComponentTree_onCKSingleChildComponent
{
  CKOwnerTreeNode *root = [[CKOwnerTreeNode alloc] init];
  CKComponent *c = [CKComponent newWithView:{} size:{}];
  CKSingleChildComponent *singleChildComponent = [CKComponentTreeTestComponent_SingleChild newWithComponent:c];
  [singleChildComponent buildComponentTree:root previousOwner:nil scopeRoot:nil stateUpdates:{}];

  // Make sure the root has only one child.
  XCTAssertEqual(root.children.size(), 1);
  CKTreeNode *singleChildNode = root.children[0];
  verifyChildToParentConnection(root, singleChildNode, singleChildComponent);

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
  CKSingleChildComponent *singleChildComponent2 = [CKComponentTreeTestComponent_SingleChild newWithComponent:c2];
  [singleChildComponent2 buildComponentTree:root2 previousOwner:root scopeRoot:nil stateUpdates:{}];
  XCTAssertTrue(areTreesEqual(root, root2));
}

- (void)test_buildComponentTree_onCKSingleChildComponent_overrideNonOwnerComponent
{
  CKOwnerTreeNode *root = [[CKOwnerTreeNode alloc] init];
  CKComponent *c = [CKComponent newWithView:{} size:{}];
  CKSingleChildComponent *singleChildNoOwnerComponent = [CKComponentTreeTestComponent_NonOwner_SingleChild newWithComponent:c];
  [singleChildNoOwnerComponent buildComponentTree:root previousOwner:nil scopeRoot:nil stateUpdates:{}];

  // As singleChildNoOwnerComponent is not an owner, the root should have 2 children.
  XCTAssertEqual(root.children.size(), 2);
  XCTAssertTrue(verifyComponentsInNode(root, @[singleChildNoOwnerComponent, c]));

  // Simulate a second tree creation.
  CKOwnerTreeNode *root2 = [[CKOwnerTreeNode alloc] init];
  CKComponent *c2 = [CKComponent newWithView:{} size:{}];
  CKSingleChildComponent *singleChildNoOwnerComponent2 = [CKComponentTreeTestComponent_NonOwner_SingleChild newWithComponent:c2];
  [singleChildNoOwnerComponent2 buildComponentTree:root2 previousOwner:root scopeRoot:nil stateUpdates:{}];
  XCTAssertTrue(areTreesEqual(root, root2));
}

#pragma mark - CKMultiChildComponent

- (void)test_buildComponentTree_onCKMultiChildComponent
{
  CKOwnerTreeNode *root = [[CKOwnerTreeNode alloc] init];
  CKComponent *c10 = [CKComponent newWithView:{} size:{}];
  CKComponent *c11 = [CKComponent newWithView:{} size:{}];
  CKMultiChildComponent *groupComponent = [CKComponentTreeTestComponent_MultiChild newWithChildren:{c10, c11}];
  [groupComponent buildComponentTree:root previousOwner:nil scopeRoot:nil stateUpdates:{}];

  XCTAssertEqual(root.children.size(), 3);
  XCTAssertTrue(verifyComponentsInNode(root, @[groupComponent, c10, c11]));

  // Simulate a second tree creation.
  CKOwnerTreeNode *root2 = [[CKOwnerTreeNode alloc] init];
  CKComponent *c20 = [CKComponent newWithView:{} size:{}];
  CKComponent *c21 = [CKComponent newWithView:{} size:{}];
  CKMultiChildComponent *groupComponent2 = [CKComponentTreeTestComponent_MultiChild newWithChildren:{c20, c21}];
  [groupComponent2 buildComponentTree:root2 previousOwner:root scopeRoot:nil stateUpdates:{}];
  XCTAssertTrue(areTreesEqual(root, root2));
}

- (void)test_buildComponentTree_onCKMultiChildComponent_MakeGroupAnOwnerComponent
{
  CKOwnerTreeNode *root = [[CKOwnerTreeNode alloc] init];
  CKComponent *c10 = [CKComponent newWithView:{} size:{}];
  CKComponent *c11 = [CKComponent newWithView:{} size:{}];
  CKMultiChildComponent *groupComponent = [CKComponentTreeTestComponent_Owner_MultiChild newWithChildren:{c10, c11}];
  [groupComponent buildComponentTree:root previousOwner:nil scopeRoot:nil stateUpdates:{}];

  XCTAssertEqual(root.children.size(), 1);
  XCTAssertTrue(verifyComponentsInNode(root, @[groupComponent]));

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
  CKMultiChildComponent *groupComponent2 = [CKComponentTreeTestComponent_Owner_MultiChild newWithChildren:{c20, c21}];
  [groupComponent2 buildComponentTree:root2 previousOwner:root scopeRoot:nil stateUpdates:{}];
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

@implementation CKComponentTreeTestComponent_SingleChild
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

@implementation CKComponentTreeTestComponent_NonOwner_SingleChild
+ (BOOL)isOwnerComponent
{
  return NO;
}
@end

@implementation CKComponentTreeTestComponent_MultiChild
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

@implementation CKComponentTreeTestComponent_Owner_MultiChild
+ (BOOL)isOwnerComponent
{
  return YES;
}
@end
