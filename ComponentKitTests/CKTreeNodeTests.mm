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

#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKComponentScopeRootFactory.h>

#import "CKComponent.h"
#import "CKCompositeComponent.h"
#import "CKRenderWithChildrenComponent.h"
#import "CKRenderComponent.h"
#import "CKComponentInternal.h"
#import "CKButtonComponent.h"
#import "CKTreeNode.h"
#import "CKRenderTreeNode.h"
#import "CKRenderTreeNodeWithChild.h"
#import "CKRenderTreeNodeWithChildren.h"
#import "CKThreadLocalComponentScope.h"
#import "CKBuildComponent.h"

@interface CKTreeNodeTest_Component_WithScope : CKComponent
@end

@interface CKTreeNodeTest_RenderComponent_WithChild : CKRenderComponent
{
  CKComponent *_child;
}
+ (instancetype)newWithComponent:(CKComponent *)component;
@end

@interface CKTreeNodeTest_Component_WithState : CKComponent
@end

@interface CKTreeNodeTest_RenderWithChildrenComponent_WithState : CKRenderWithChildrenComponent
@end

@interface CKTreeNodeTest_RenderComponent_WithState : CKRenderComponent
@end

@interface CKTreeNodeTest_RenderWithChildrenComponent_WithStateFromProps : CKRenderWithChildrenComponent
+ (instancetype)newWithProp:(id)prop;
@end

@interface CKTreeNodeTest_RenderComponent_WithStateFromProps : CKRenderComponent
+ (instancetype)newWithProp:(id)prop;
@end

@interface CKTreeNodeTest_RenderWithChildrenComponent_WithNilState : CKRenderWithChildrenComponent
@end

@interface CKTreeNodeTest_RenderComponent_WithNilState : CKRenderComponent
@end

@interface CKTreeNodeTests : XCTestCase
@end

@implementation CKTreeNodeTests

#pragma mark - CKRenderTreeNodeWithChildren

- (void)test_childForComponentKey_onCKRenderTreeNodeWithChildren_withSingleChild {
  // Simulate first component tree creation
  CKRenderTreeNodeWithChildren *root1 = [[CKRenderTreeNodeWithChildren alloc] init];
  auto const component1 = [CKComponent newWithView:{} size:{}];
  CKTreeNode *childNode1 = [[CKTreeNode alloc] initWithComponent:component1
                                                          parent:root1
                                                  previousParent:nil
                                                       scopeRoot:nil
                                                    stateUpdates:{}];

  // Simulate a component tree creation due to a state update
  CKRenderTreeNodeWithChildren *root2 = [[CKRenderTreeNodeWithChildren alloc] init];
  auto const component2 = [CKComponent newWithView:{} size:{}];
  CKTreeNode *childNode2 = [[CKTreeNode alloc] initWithComponent:component2
                                                          parent:root2
                                                  previousParent:root1
                                                       scopeRoot:nil
                                                    stateUpdates:{}];

  XCTAssertTrue(verifyChildToParentConnection(root1, childNode1, component1));
  XCTAssertTrue(verifyChildToParentConnection(root2, childNode2, component2));
}

- (void)test_nodeIdentifier_onCKRenderTreeNodeWithChildren_betweenGenerations_withSingleChild {
  // Simulate first component tree creation
  CKRenderTreeNodeWithChildren *root1 = [[CKRenderTreeNodeWithChildren alloc] init];
  auto const component1 = [CKComponent newWithView:{} size:{}];
  CKTreeNode *childNode1 = [[CKTreeNode alloc] initWithComponent:component1
                                                          parent:root1
                                                  previousParent:nil
                                                       scopeRoot:nil
                                                    stateUpdates:{}];

  // Simulate a component tree creation due to a state update
  CKRenderTreeNodeWithChildren *root2 = [[CKRenderTreeNodeWithChildren alloc] init];
  auto const component2 = [CKComponent newWithView:{} size:{}];
  CKTreeNode *childNode2 = [[CKTreeNode alloc] initWithComponent:component2
                                                          parent:root2
                                                  previousParent:root1
                                                       scopeRoot:nil
                                                    stateUpdates:{}];

  XCTAssertEqual(childNode1.nodeIdentifier, childNode2.nodeIdentifier);
}


- (void)test_childForComponentKey_onCKRenderTreeNodeWithChildren_withMultipleChildren {
  CKRenderTreeNodeWithChildren *root = [[CKRenderTreeNodeWithChildren alloc] init];

  // Create 4 children components
  NSArray<CKComponent *> *components = @[[CKComponent newWithView:{} size:{}],
                                         [CKComponent newWithView:{} size:{}],
                                         [CKButtonComponent newWithView:{} size:{}],
                                         [CKComponent newWithView:{} size:{}]];

  // Create a childNode for each.
  NSMutableArray<CKTreeNode*> *nodes = createsNodesForComponentsWithOwner(root, nil, components);

  // Make sure the connections between the parent to the child nodes are correct
  for (NSUInteger i=0; i<components.count; i++) {
    CKTreeNode *childNode = nodes[i];
    CKComponent *component = components[i];
    XCTAssertTrue(verifyChildToParentConnection(root, childNode, component));
  }

  // Create 4 children components
  CKRenderTreeNodeWithChildren *root2 = [[CKRenderTreeNodeWithChildren alloc] init];
  NSArray<CKComponent *> *components2 = @[[CKComponent newWithView:{} size:{}],
                                          [CKComponent newWithView:{} size:{}],
                                          [CKButtonComponent newWithView:{} size:{}],
                                          [CKComponent newWithView:{} size:{}]];

  __unused NSMutableArray<CKTreeNode*> *nodes2 = createsNodesForComponentsWithOwner(root2, root, components2);

  // Verify that the two trees are equal.
  XCTAssertTrue(areTreesEqual(root, root2));
}

- (void)test_childForComponentKey_onCKRenderTreeNodeWithChildren_withDifferentChildOverGenerations
{
  // Simulate first component tree creation
  CKRenderTreeNodeWithChildren *root1 = [[CKRenderTreeNodeWithChildren alloc] init];
  auto const component1 = [CKComponent newWithView:{} size:{}];
  CKTreeNode *childNode1 = [[CKTreeNode alloc] initWithComponent:component1
                                                          parent:root1
                                                  previousParent:nil
                                                       scopeRoot:nil
                                                    stateUpdates:{}];

  // Simulate a component tree creation with a DIFFRENT child
  CKRenderTreeNodeWithChildren *root2 = [[CKRenderTreeNodeWithChildren alloc] init];
  auto const component2 = [CKRenderComponent newWithView:{} size:{}];
  CKTreeNode *childNode2 = [[CKRenderTreeNode alloc] initWithComponent:component2
                                                                parent:root2
                                                        previousParent:root1
                                                             scopeRoot:nil
                                                          stateUpdates:{}];

  XCTAssertTrue(verifyChildToParentConnection(root1, childNode1, component1));
  XCTAssertTrue(verifyChildToParentConnection(root2, childNode2, component2));
  XCTAssertNotEqual(childNode1.nodeIdentifier, childNode2.nodeIdentifier);
}

#pragma mark - CKRenderTreeNodeWithChild

- (void)test_childForComponentKey_onCKRenderTreeNodeWithChild {
  // Simulate first component tree creation
  CKRenderTreeNodeWithChild *root1 = [[CKRenderTreeNodeWithChild alloc] init];
  auto const component1 = [CKComponent newWithView:{} size:{}];
  CKTreeNode *childNode1 = [[CKTreeNode alloc] initWithComponent:component1
                                                          parent:root1
                                                  previousParent:nil
                                                       scopeRoot:nil
                                                    stateUpdates:{}];

  // Simulate a component tree creation due to a state update
  CKRenderTreeNodeWithChild *root2 = [[CKRenderTreeNodeWithChild alloc] init];
  auto const component2 = [CKComponent newWithView:{} size:{}];
  CKTreeNode *childNode2 = [[CKTreeNode alloc] initWithComponent:component2
                                                          parent:root2
                                                  previousParent:root1
                                                       scopeRoot:nil
                                                    stateUpdates:{}];

  XCTAssertTrue(verifyChildToParentConnection(root1, childNode1, component1));
  XCTAssertTrue(verifyChildToParentConnection(root2, childNode2, component2));
}

- (void)test_nodeIdentifier_onCKRenderTreeNodeWithChild_betweenGenerations {
  // Simulate first component tree creation
  CKRenderTreeNodeWithChild *root1 = [[CKRenderTreeNodeWithChild alloc] init];
  auto const component1 = [CKComponent newWithView:{} size:{}];
  CKTreeNode *childNode1 = [[CKTreeNode alloc] initWithComponent:component1
                                                          parent:root1
                                                  previousParent:nil
                                                       scopeRoot:nil
                                                    stateUpdates:{}];

  // Simulate a component tree creation due to a state update
  CKRenderTreeNodeWithChild *root2 = [[CKRenderTreeNodeWithChild alloc] init];
  auto const component2 = [CKComponent newWithView:{} size:{}];
  CKTreeNode *childNode2 = [[CKTreeNode alloc] initWithComponent:component2
                                                          parent:root2
                                                  previousParent:root1
                                                       scopeRoot:nil
                                                    stateUpdates:{}];

  XCTAssertEqual(childNode1.nodeIdentifier, childNode2.nodeIdentifier);
}

#pragma mark - State

- (void)test_stateUpdate_onCKTreeNode
{
  // The 'resolve' method in CKComponentScopeHandle requires a CKThreadLocalComponentScope.
  // We should get rid of this assert once we move to the render method only.
  CKThreadLocalComponentScope threadScope(nil, {});

  // Simulate first component tree creation
  CKRenderTreeNodeWithChildren *root1 = [[CKRenderTreeNodeWithChildren alloc] init];
  auto const component1 = [CKTreeNodeTest_Component_WithState newWithView:{} size:{}];
  CKTreeNode *childNode = [[CKTreeNode alloc] initWithComponent:component1
                                                         parent:root1
                                                 previousParent:nil
                                                      scopeRoot:nil
                                                   stateUpdates:{}];

  // Verify that the initial state is correct.
  XCTAssertTrue([childNode.state isEqualToNumber:[[component1 class] initialState]]);

  // Simulate a component tree creation due to a state update
  CKRenderTreeNodeWithChildren *root2 = [[CKRenderTreeNodeWithChildren alloc] init];
  auto const component2 = [CKTreeNodeTest_Component_WithState newWithView:{} size:{}];

  // Simulate a state update
  auto const newState = @2;
  auto const scopeHandle = childNode.handle;
  CKComponentStateUpdateMap stateUpdates;
  stateUpdates[scopeHandle].push_back(^(id){
    return newState;
  });
  CKTreeNode *childNode2 = [[CKTreeNode alloc] initWithComponent:component2
                                                          parent:root2
                                                  previousParent:root1
                                                       scopeRoot:nil
                                                    stateUpdates:stateUpdates];

  XCTAssertTrue([childNode2.state isEqualToNumber:newState]);
}

- (void)test_nonNil_initialState_onCKTreeNode_withCKComponentSubclass
{
  auto const c = [CKTreeNodeTest_Component_WithState new];
  [self _test_nonNil_initialState_withComponent:c andNodeClass:[CKTreeNode class]];
}

- (void)test_emptyInitialState_onCKTreeNode_withCKComponentSubclass
{
  auto const c = [CKComponent new];
  [self _test_emptyInitialState_withComponent:c andNodeClass:[CKTreeNode class]];
}

- (void)test_nonNil_initialState_onCKRenderTreeNode_withCKRenderComponent
{
  auto const c = [CKTreeNodeTest_RenderComponent_WithState new];
  [self _test_nonNil_initialState_withComponent:c andNodeClass:[CKRenderTreeNode class]];
}

- (void)test_nonNil_initialState_onCKRenderTreeNode_withCKRenderWithChildrenComponent
{
  auto const c = [CKTreeNodeTest_RenderWithChildrenComponent_WithState new];
  [self _test_nonNil_initialState_withComponent:c andNodeClass:[CKRenderTreeNode class]];
}

- (void)test_emptyInitialState_onCKRenderTreeNode_withCKRenderComponent
{
  auto const c = [CKRenderComponent new];
  [self _test_emptyInitialState_withComponent:c andNodeClass:[CKRenderTreeNode class]];
}

- (void)test_emptyInitialState_onCKRenderTreeNode_withCKRenderWithChildrenComponent
{
  auto const c = [CKRenderWithChildrenComponent new];
  [self _test_emptyInitialState_withComponent:c andNodeClass:[CKRenderTreeNode class]];
}

- (void)test_initialStateFromPtops_onCKRenderTreeNode_withCKRenderWithChildrenComponent
{
  id prop = @1;
  auto const c = [CKTreeNodeTest_RenderWithChildrenComponent_WithStateFromProps newWithProp:prop];
  [self _test_initialState_withComponent:c initialState:prop andNodeClass:[CKRenderTreeNode class]];
}

- (void)test_initialStateFromPtops_onCKRenderTreeNode_withCKRenderComponent
{
  id prop = @1;
  auto const c = [CKTreeNodeTest_RenderComponent_WithStateFromProps newWithProp:prop];
  [self _test_initialState_withComponent:c initialState:prop andNodeClass:[CKRenderTreeNode class]];
}

- (void)test_nilInitialState_onCKRenderTreeNode_withCKRenderWithChildrenComponent
{
  // Make sure CKRenderWithChildrenComponent supports nil initial state from prop.
  id prop = nil;
  auto const c = [CKTreeNodeTest_RenderWithChildrenComponent_WithStateFromProps newWithProp:prop];
  [self _test_initialState_withComponent:c initialState:prop andNodeClass:[CKRenderTreeNode class]];

  // Make sure CKRenderWithChildrenComponent supports nil initial.
  auto const c2 = [CKTreeNodeTest_RenderWithChildrenComponent_WithNilState new];
  [self _test_initialState_withComponent:c2 initialState:nil andNodeClass:[CKRenderTreeNode class]];
}

- (void)test_nilInitialState_onCKRenderTreeNode_withCKRenderComponent
{
  // Make sure CKRenderComponent supports nil initial state from prop.
  id prop = nil;
  auto const c = [CKTreeNodeTest_RenderComponent_WithStateFromProps newWithProp:prop];
  [self _test_initialState_withComponent:c initialState:nil andNodeClass:[CKRenderTreeNode class]];

  // Make sure CKRenderWithChildrenComponent supports nil initial.
  auto const c2 = [CKTreeNodeTest_RenderComponent_WithNilState new];
  [self _test_initialState_withComponent:c2 initialState:nil andNodeClass:[CKRenderTreeNode class]];
}

#pragma mark - CKTreeNodeWithChild

- (void)test_childForComponentKey_onCKTreeNodeWithChild_withSameChildOverGenerations
{
  // Simulate first component tree creation
  CKTreeNodeWithChild *root1 = [[CKTreeNodeWithChild alloc] init];
  auto const component1 = [CKComponent newWithView:{} size:{}];
  CKTreeNode *childNode1 = [[CKTreeNode alloc] initWithComponent:component1
                                                          parent:root1
                                                  previousParent:nil
                                                       scopeRoot:nil
                                                    stateUpdates:{}];

  // Simulate a component tree creation due to a state update
  CKTreeNodeWithChild *root2 = [[CKTreeNodeWithChild alloc] init];
  auto const component2 = [CKComponent newWithView:{} size:{}];
  CKTreeNode *childNode2 = [[CKTreeNode alloc] initWithComponent:component2
                                                          parent:root2
                                                  previousParent:root1
                                                       scopeRoot:nil
                                                    stateUpdates:{}];

  XCTAssertTrue(verifyChildToParentConnection(root1, childNode1, component1));
  XCTAssertTrue(verifyChildToParentConnection(root2, childNode2, component2));
  XCTAssertEqual(childNode1.nodeIdentifier, childNode2.nodeIdentifier);
}

- (void)test_childForComponentKey_onCKTreeNodeWithChild_withDifferentChildOverGenerations
{
  // Simulate first component tree creation
  CKTreeNodeWithChild *root1 = [[CKTreeNodeWithChild alloc] init];
  auto const component1 = [CKComponent newWithView:{} size:{}];
  CKTreeNode *childNode1 = [[CKTreeNode alloc] initWithComponent:component1
                                                          parent:root1
                                                  previousParent:nil
                                                       scopeRoot:nil
                                                    stateUpdates:{}];

  // Simulate a component tree creation with a DIFFRENT child
  CKTreeNodeWithChild *root2 = [[CKTreeNodeWithChild alloc] init];
  auto const component2 = [CKRenderComponent newWithView:{} size:{}];
  CKTreeNode *childNode2 = [[CKRenderTreeNode alloc] initWithComponent:component2
                                                                parent:root2
                                                        previousParent:root1
                                                             scopeRoot:nil
                                                          stateUpdates:{}];

  XCTAssertTrue(verifyChildToParentConnection(root1, childNode1, component1));
  XCTAssertTrue(verifyChildToParentConnection(root2, childNode2, component2));
  XCTAssertNotEqual(childNode1.nodeIdentifier, childNode2.nodeIdentifier);
}

- (void)test_treeNodeToScopeHandleConnection
{
  __block CKTreeNodeTest_RenderComponent_WithChild *c;
  __block CKTreeNodeTest_Component_WithScope *child;
  CKComponent *(^block)(void) = ^CKComponent *{
    child = [CKTreeNodeTest_Component_WithScope new];
    c = [CKTreeNodeTest_RenderComponent_WithChild
         newWithComponent:
         [CKCompositeComponent newWithComponent:child]];

    return c;
  };
  auto const results = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, block);
  XCTAssertEqual(c.scopeHandle.treeNode.component, c);
  XCTAssertEqual(child.scopeHandle.treeNode.component, child);
}

#pragma mark - Helpers

- (void)_test_emptyInitialState_withComponent:(CKComponent *)c andNodeClass:(Class<CKTreeNodeProtocol>)nodeClass
{
  CKThreadLocalComponentScope threadScope(nil, {});

  CKRenderTreeNodeWithChildren *root = [[CKRenderTreeNodeWithChildren alloc] init];
  CKTreeNode *node = [[(Class)nodeClass alloc]
                      initWithComponent:c
                      parent:root
                      previousParent:nil
                      scopeRoot:nil
                      stateUpdates:{}];

  XCTAssertNil(node.state);
  XCTAssertNil(node.handle);
}

- (void)_test_nonNil_initialState_withComponent:(CKComponent *)c andNodeClass:(Class<CKTreeNodeProtocol>)nodeClass
{
  CKThreadLocalComponentScope threadScope(nil, {});

  CKRenderTreeNodeWithChildren *root = [[CKRenderTreeNodeWithChildren alloc] init];
  CKTreeNode *node = [[(Class)nodeClass alloc]
                      initWithComponent:c
                      parent:root
                      previousParent:nil
                      scopeRoot:nil
                      stateUpdates:{}];

  XCTAssertEqual([[c class] initialState], node.state);
  XCTAssertNotNil(node.handle);
}

- (void)_test_initialState_withComponent:(CKComponent *)c initialState:(id)initialState andNodeClass:(Class<CKTreeNodeProtocol>)nodeClass
{
  CKThreadLocalComponentScope threadScope(nil, {});

  CKRenderTreeNodeWithChildren *root = [[CKRenderTreeNodeWithChildren alloc] init];
  CKTreeNode *node = [[(Class)nodeClass alloc]
                      initWithComponent:c
                      parent:root
                      previousParent:nil
                      scopeRoot:nil
                      stateUpdates:{}];

  XCTAssertEqual(initialState, node.state);
  XCTAssertNotNil(node.handle);
}

static BOOL verifyChildToParentConnection(id<CKTreeNodeWithChildrenProtocol> parentNode, CKTreeNode *childNode, CKComponent *c) {
  auto const componentKey = [childNode componentKey];
  auto const childComponent = [parentNode childForComponentKey:componentKey].component;
  return [childComponent isEqual:c];
}

static NSMutableArray<CKTreeNode*> *createsNodesForComponentsWithOwner(id<CKTreeNodeWithChildrenProtocol> owner,
                                                                       id<CKTreeNodeWithChildrenProtocol> previousParent,
                                                                       NSArray<CKComponent *> *components) {
  NSMutableArray<CKTreeNode*> *nodes = [NSMutableArray array];
  for (CKComponent *component in components) {
    CKTreeNode *childNode = [[CKTreeNode alloc] initWithComponent:component
                                                           parent:owner
                                                   previousParent:previousParent
                                                        scopeRoot:nil
                                                     stateUpdates:{}];
    [nodes addObject:childNode];
  }
  return nodes;
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

#pragma mark - Helper Classes

@implementation CKTreeNodeTest_Component_WithState
+ (id)initialState
{
  return @1;
}
@end

@implementation CKTreeNodeTest_RenderWithChildrenComponent_WithState
+ (id)initialState
{
  return @1;
}
@end

@implementation CKTreeNodeTest_RenderComponent_WithState
+ (id)initialState
{
  return @1;
}
@end

@implementation CKTreeNodeTest_RenderWithChildrenComponent_WithStateFromProps
{
  id _prop;
}

+ (instancetype)newWithProp:(id)prop
{
  auto const c = [super new];
  if (c) {
    c->_prop = prop;
  }
  return c;
}

+ (id)initialStateWithComponent:(CKTreeNodeTest_RenderWithChildrenComponent_WithStateFromProps *)c
{
  return c->_prop;
}
@end

@implementation CKTreeNodeTest_RenderComponent_WithStateFromProps
{
  id _prop;
}

+ (instancetype)newWithProp:(id)prop
{
  auto const c = [super new];
  if (c) {
    c->_prop = prop;
  }
  return c;
}

+ (id)initialStateWithComponent:(CKTreeNodeTest_RenderComponent_WithStateFromProps *)c
{
  return c->_prop;
}
@end

@implementation CKTreeNodeTest_RenderWithChildrenComponent_WithNilState
+ (id)initialState
{
  return nil;
}
@end

@implementation CKTreeNodeTest_RenderComponent_WithNilState
+ (id)initialState
{
  return nil;
}
@end

@implementation CKTreeNodeTest_Component_WithScope
+ (instancetype)new
{
  CKComponentScope scope(self);
  return [super new];
}
@end

@implementation CKTreeNodeTest_RenderComponent_WithChild
+ (instancetype)newWithComponent:(CKComponent *)component
{
  auto const c = [super new];
  if (c) {
    c->_child = component;
  }
  return c;
}

+ (id)initialState
{
  return nil;
}

- (CKComponent *)render:(id)state
{
  return _child;
}
@end

