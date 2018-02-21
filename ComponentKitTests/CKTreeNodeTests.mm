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

- (void)test_CKTreeNode_childForComponentKey_betweenGenerations {
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

- (void)test_CKTreeNode_nodeIdentifier_betweenGenerations {
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

- (void)test_CKTreeNode_childForComponentKey_signleChild {
  CKTreeNode *root = [[CKTreeNode alloc] init];

  auto const component = [CKComponent newWithView:{} size:{}];
  CKBaseTreeNode *childNode = [[CKBaseTreeNode alloc] initWithComponent:component
                                                                  owner:root
                                                          previousOwner:nil
                                                              scopeRoot:nil
                                                           stateUpdates:{}];

  XCTAssertTrue(verifyChildToParentConnection(root, childNode, component));
}

- (void)test_CKTreeNode_childForComponentKey_multipleChildren {
  CKTreeNode *root = [[CKTreeNode alloc] init];

  // Create 4 children components
  NSArray<CKComponent *> *components = @[[CKComponent newWithView:{} size:{}],
                                         [CKComponent newWithView:{} size:{}],
                                         [CKButtonComponent newWithView:{} size:{}],
                                         [CKComponent newWithView:{} size:{}]];

  // Creaste a childNode for each.
  NSMutableArray<CKBaseTreeNode*> *nodes = [NSMutableArray array];
  for (CKComponent *component in components) {
    CKBaseTreeNode *childNode = [[CKBaseTreeNode alloc] initWithComponent:component
                                                                    owner:root
                                                            previousOwner:nil
                                                                scopeRoot:nil
                                                             stateUpdates:{}];
    [nodes addObject:childNode];
  }

  // Make sure the connections between the parent to the child node are correct
  for (NSUInteger i=0; i<components.count; i++) {
    CKBaseTreeNode *childNode = nodes[i];
    CKComponent *component = components[i];
    XCTAssertTrue(verifyChildToParentConnection(root, childNode, component));
  }
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

@end
