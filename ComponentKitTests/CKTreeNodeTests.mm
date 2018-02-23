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
#import "CKComponentInternal.h"
#import "CKButtonComponent.h"
#import "CKBaseTreeNode.h"
#import "CKTreeNode.h"
#import "CKThreadLocalComponentScope.h"

@interface CKTreeNodeTestComponentWithState : CKComponent
@end

@implementation CKTreeNodeTestComponentWithState
+ (id)initialState
{
  return @1;
}
@end

@interface CKTreeNodeTests : XCTestCase

@end

@implementation CKTreeNodeTests

#pragma mark - CKTreeNode

- (void)test_childForComponentKey_onCKTreeNode_withSingleChild {
  // Simulate first component tree creation
  CKTreeNode *root1 = [[CKTreeNode alloc] init];
  auto const component1 = [CKComponent newWithView:{} size:{}];
  CKBaseTreeNode *childNode1 = [[CKBaseTreeNode alloc] initWithComponent:component1
                                                                   owner:root1
                                                           previousOwner:nil
                                                               scopeRoot:nil
                                                            stateUpdates:{}];

  // Simulate a component tree creation due to a state update
  CKTreeNode *root2 = [[CKTreeNode alloc] init];
  auto const component2 = [CKComponent newWithView:{} size:{}];
  CKBaseTreeNode *childNode2 = [[CKBaseTreeNode alloc] initWithComponent:component2
                                                                   owner:root2
                                                           previousOwner:root1
                                                               scopeRoot:nil
                                                            stateUpdates:{}];

  XCTAssertTrue(verifyChildToParentConnection(root1, childNode1, component1));
  XCTAssertTrue(verifyChildToParentConnection(root2, childNode2, component2));
}

- (void)test_nodeIdentifier_onCKTreeNode_betweenGenerations_withSingleChild {
  // Simulate first component tree creation
  CKTreeNode *root1 = [[CKTreeNode alloc] init];
  auto const component1 = [CKComponent newWithView:{} size:{}];
  CKBaseTreeNode *childNode1 = [[CKBaseTreeNode alloc] initWithComponent:component1
                                                                   owner:root1
                                                           previousOwner:nil
                                                               scopeRoot:nil
                                                            stateUpdates:{}];

  // Simulate a component tree creation due to a state update
  CKTreeNode *root2 = [[CKTreeNode alloc] init];
  auto const component2 = [CKComponent newWithView:{} size:{}];
  CKBaseTreeNode *childNode2 = [[CKBaseTreeNode alloc] initWithComponent:component2
                                                                   owner:root2
                                                           previousOwner:root1
                                                               scopeRoot:nil
                                                            stateUpdates:{}];

  XCTAssertEqual(childNode1.nodeIdentifier, childNode2.nodeIdentifier);
}


- (void)test_childForComponentKey_onCKTreeNode_withMultipleChildren {
  CKTreeNode *root = [[CKTreeNode alloc] init];

  // Create 4 children components
  NSArray<CKComponent *> *components = @[[CKComponent newWithView:{} size:{}],
                                         [CKComponent newWithView:{} size:{}],
                                         [CKButtonComponent newWithView:{} size:{}],
                                         [CKComponent newWithView:{} size:{}]];

  // Create a childNode for each.
  NSMutableArray<CKBaseTreeNode*> *nodes = createsNodesForComponentsWithOwner(root, nil, components);

  // Make sure the connections between the parent to the child nodes are correct
  for (NSUInteger i=0; i<components.count; i++) {
    CKBaseTreeNode *childNode = nodes[i];
    CKComponent *component = components[i];
    XCTAssertTrue(verifyChildToParentConnection(root, childNode, component));
  }

  // Create 4 children components
  CKTreeNode *root2 = [[CKTreeNode alloc] init];
  NSArray<CKComponent *> *components2 = @[[CKComponent newWithView:{} size:{}],
                                          [CKComponent newWithView:{} size:{}],
                                          [CKButtonComponent newWithView:{} size:{}],
                                          [CKComponent newWithView:{} size:{}]];

  __unused NSMutableArray<CKBaseTreeNode*> *nodes2 = createsNodesForComponentsWithOwner(root2, root, components2);

  // Verify that the two trees are equal.
  XCTAssertTrue(areTreesEqual(root, root2));
}

#pragma mark - State

- (void)test_CKTreeNode_state
{
  // The 'resolve' method in CKComponentScopeHandle requires a CKThreadLocalComponentScope.
  // We should get rid of this assert once we move to the render method only.
  CKThreadLocalComponentScope threadScope(nil, {});

  // Simulate first component tree creation
  CKTreeNode *root1 = [[CKTreeNode alloc] init];
  auto const component1 = [CKTreeNodeTestComponentWithState newWithView:{} size:{}];
  CKBaseTreeNode *childNode = [[CKBaseTreeNode alloc] initWithComponent:component1
                                                                  owner:root1
                                                          previousOwner:nil
                                                              scopeRoot:nil
                                                           stateUpdates:{}];

  // Verify that the initial state is correct.
  XCTAssertTrue([childNode.state isEqualToNumber:[[component1 class] initialState]]);

  // Simulate a component tree creation due to a state update
  CKTreeNode *root2 = [[CKTreeNode alloc] init];
  auto const component2 = [CKTreeNodeTestComponentWithState newWithView:{} size:{}];

  // Simulate a state update
  auto const newState = @2;
  auto const scopeHandle = childNode.handle;
  CKComponentStateUpdateMap stateUpdates;
  stateUpdates[scopeHandle].push_back(^(id){
    return newState;
  });
  CKBaseTreeNode *childNode2 = [[CKBaseTreeNode alloc] initWithComponent:component2
                                                                   owner:root2
                                                           previousOwner:root1
                                                               scopeRoot:nil
                                                            stateUpdates:stateUpdates];

  XCTAssertTrue([childNode2.state isEqualToNumber:newState]);
}

static BOOL verifyChildToParentConnection(CKTreeNode * parentNode, CKBaseTreeNode *childNode, CKComponent *c) {
  auto const componentKey = [childNode componentKey];
  auto const childComponent = [parentNode childForComponentKey:componentKey].component;
  return [childComponent isEqual:c];
}

static NSMutableArray<CKBaseTreeNode*> *createsNodesForComponentsWithOwner(CKTreeNode *owner,
                                                                           CKTreeNode *previousOwner,
                                                                           NSArray<CKComponent *> *components) {
  NSMutableArray<CKBaseTreeNode*> *nodes = [NSMutableArray array];
  for (CKComponent *component in components) {
    CKBaseTreeNode *childNode = [[CKBaseTreeNode alloc] initWithComponent:component
                                                                    owner:owner
                                                            previousOwner:previousOwner
                                                                scopeRoot:nil
                                                             stateUpdates:{}];
    [nodes addObject:childNode];
  }
  return nodes;
}

/** Compare the children of the trees recursively; returns true if the two trees are equal */
static BOOL areTreesEqual(CKTreeNode *lhs, CKTreeNode *rhs) {
  NSMutableSet<NSString *> *lhsChildrenIdentifiers = [NSMutableSet set];
  treeChildrenIdentifiers(lhs, lhsChildrenIdentifiers, 0);
  NSMutableSet<NSString *> *rhsChildrenIdentifiers = [NSMutableSet set];
  treeChildrenIdentifiers(rhs, rhsChildrenIdentifiers, 0);
  return [lhsChildrenIdentifiers isEqualToSet:rhsChildrenIdentifiers];
}

/** Iterate recursively over the tree and add its node identifiers to the set */
static void treeChildrenIdentifiers(CKTreeNode *node, NSMutableSet<NSString *> *identifiers, int level) {
  for (auto const childNode : node.children) {
    // We add the child identifier + its level in the tree.
    [identifiers addObject:[NSString stringWithFormat:@"%d-%d",childNode.nodeIdentifier, level]];
    if ([childNode isKindOfClass:[CKTreeNode class]]) {
      treeChildrenIdentifiers((CKTreeNode *)childNode, identifiers, level+1);
    }
  }
}

@end
