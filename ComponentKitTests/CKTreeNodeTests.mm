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

#import <ComponentKit/CKBuildComponent.h>
#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKComponentScopeRootFactory.h>
#import <ComponentKit/CKFlexboxComponent.h>
#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKCompositeComponent.h>
#import <ComponentKit/CKRenderComponent.h>
#import <ComponentKit/CKLayoutComponent.h>
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKButtonComponent.h>
#import <ComponentKit/CKThreadLocalComponentScope.h>
#import <ComponentKit/CKBuildComponent.h>
#import <ComponentKit/CKRenderTreeNode.h>

static BOOL verifyChildToParentConnection(id<CKTreeNodeWithChildrenProtocol> parentNode, CKTreeNode *childNode, id<CKRenderComponentProtocol> c) {
  auto const componentKey = [childNode componentKey];
  auto const childComponent = [parentNode childForComponentKey:componentKey].component;
  return [childComponent isEqual:c];
}

static NSMutableArray<CKTreeNode*> *createsNodesForComponentsWithOwner(id<CKTreeNodeWithChildrenProtocol> owner,
                                                                       id<CKTreeNodeWithChildrenProtocol> previousParent,
                                                                       CKComponentScopeRoot *scopeRoot,
                                                                       NSArray<id<CKRenderComponentProtocol>> *components) {
  NSMutableArray<CKTreeNode*> *nodes = [NSMutableArray array];
  for (id<CKRenderComponentProtocol> component in components) {
    CKTreeNode *childNode = [[CKRenderTreeNode alloc] initWithComponent:component
                                                                 parent:owner
                                                         previousParent:previousParent
                                                              scopeRoot:scopeRoot
                                                           stateUpdates:{}];
    [nodes addObject:childNode];
  }
  return nodes;
}

/** Iterate recursively over the tree and add its node identifiers to the set */
static void treeChildrenIdentifiers(id<CKTreeNodeWithChildrenProtocol> node, NSMutableSet<NSString *> *identifiers, int level) {
  for (auto const childNode : node.children) {
    // We add the child identifier + its level in the tree.
    [identifiers addObject:[NSString stringWithFormat:@"%d-%d",childNode.nodeIdentifier, level]];
    if ([childNode isKindOfClass:[CKRenderTreeNode class]]) {
      treeChildrenIdentifiers((CKRenderTreeNode *)childNode, identifiers, level+1);
    }
  }
}

/** Compare the children of the trees recursively; returns true if the two trees are equal */
static BOOL areTreesEqual(id<CKTreeNodeWithChildrenProtocol> lhs, id<CKTreeNodeWithChildrenProtocol> rhs) {
  NSMutableSet<NSString *> *lhsChildrenIdentifiers = [NSMutableSet set];
  treeChildrenIdentifiers(lhs, lhsChildrenIdentifiers, 0);
  NSMutableSet<NSString *> *rhsChildrenIdentifiers = [NSMutableSet set];
  treeChildrenIdentifiers(rhs, rhsChildrenIdentifiers, 0);
  return [lhsChildrenIdentifiers isEqualToSet:rhsChildrenIdentifiers];
}

static CKComponent* buildComponent(CKComponent*(^block)()) {
  __block CKComponent *c;
  CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, ^CKComponent *{
    c = block();
    return c;
  });
  return c;
}

@interface CKTreeNodeTest_Component_WithScope : CKComponent
@end

@interface CKTreeNodeTest_RenderComponent_WithChild : CKRenderComponent
{
  CKComponent *_childComponent;
}
+ (instancetype)newWithComponent:(CKComponent *)component;
@end

@interface CKTreeNodeTest_RenderComponent_NoInitialState : CKRenderComponent
@end

@interface CKTreeNodeTest_Component_WithState : CKComponent
@end

@interface CKTreeNodeTest_RenderComponent_WithState : CKRenderComponent
@end

@interface CKTreeNodeTest_RenderComponent_WithStateFromProps : CKRenderComponent
+ (instancetype)newWithProp:(id)prop;
@end

@interface CKTreeNodeTest_RenderComponent_WithNilState : CKRenderComponent
@end

@interface CKTreeNodeTest_RenderComponent_WithIdentifier : CKRenderComponent
+ (instancetype)newWithIdentifier:(id<NSObject>)identifier;
@end

@interface CKTreeNodeTests : XCTestCase
@end

@implementation CKTreeNodeTests

#pragma mark - CKTreeNodeWithChildren

- (void)test_childForComponentKey_onCKTreeNodeWithChildren_withChild {
  // Simulate first component tree creation
  auto const scopeRoot = CKComponentScopeRootWithDefaultPredicates(nil, nil);
  auto const root1 = [[CKRenderTreeNode alloc] init];
  auto const component1 = [CKTreeNodeTest_RenderComponent_NoInitialState new];
  CKTreeNode *childNode1 = [[CKRenderTreeNode alloc] initWithComponent:component1
                                                                parent:root1
                                                        previousParent:nil
                                                             scopeRoot:scopeRoot
                                                          stateUpdates:{}];

  // Simulate a component tree creation due to a state update
  auto const root2 = [[CKRenderTreeNode alloc] init];
  auto const component2 = [CKTreeNodeTest_RenderComponent_NoInitialState new];
  CKTreeNode *childNode2 = [[CKRenderTreeNode alloc] initWithComponent:component2
                                                                parent:root2
                                                        previousParent:root1
                                                             scopeRoot:[scopeRoot newRoot]
                                                          stateUpdates:{}];

  XCTAssertTrue(verifyChildToParentConnection(root1, childNode1, component1));
  XCTAssertTrue(verifyChildToParentConnection(root2, childNode2, component2));
}

- (void)test_nodeIdentifier_onCKTreeNodeWithChildren_betweenGenerations_withChild {
  // Simulate first component tree creation
  auto const scopeRoot = CKComponentScopeRootWithDefaultPredicates(nil, nil);
  auto const root1 = [[CKRenderTreeNode alloc] init];
  auto const component1 = [CKTreeNodeTest_RenderComponent_NoInitialState new];
  CKTreeNode *childNode1 = [[CKRenderTreeNode alloc] initWithComponent:component1
                                                                parent:root1
                                                        previousParent:nil
                                                             scopeRoot:scopeRoot
                                                          stateUpdates:{}];

  // Simulate a component tree creation due to a state update
  auto const root2 = [[CKRenderTreeNode alloc] init];
  auto const component2 = [CKTreeNodeTest_RenderComponent_NoInitialState new];
  CKTreeNode *childNode2 = [[CKRenderTreeNode alloc] initWithComponent:component2
                                                                parent:root2
                                                        previousParent:root1
                                                             scopeRoot:[scopeRoot newRoot]
                                                          stateUpdates:{}];

  XCTAssertEqual(childNode1.nodeIdentifier, childNode2.nodeIdentifier);
}


- (void)test_childForComponentKey_onCKTreeNodeWithChildren_withMultipleChildren {
  auto const scopeRoot = CKComponentScopeRootWithDefaultPredicates(nil, nil);
  auto const root = [[CKRenderTreeNode alloc] init];

  // Create 4 children components
  NSArray<id<CKRenderComponentProtocol>> *components = @[[CKTreeNodeTest_RenderComponent_NoInitialState new],
                                                         [CKTreeNodeTest_RenderComponent_NoInitialState new],
                                                         [CKTreeNodeTest_RenderComponent_WithState new],
                                                         [CKTreeNodeTest_RenderComponent_NoInitialState new]];

  // Create a childNode for each.
  NSMutableArray<CKTreeNode*> *nodes = createsNodesForComponentsWithOwner(root, nil, scopeRoot, components);

  // Make sure the connections between the parent to the child nodes are correct
  for (NSUInteger i=0; i<components.count; i++) {
    CKTreeNode *childNode = nodes[i];
    auto const component = components[i];
    XCTAssertTrue(verifyChildToParentConnection(root, childNode, component));
  }

  // Create 4 children components
  auto const root2 = [[CKRenderTreeNode alloc] init];
  NSArray<id<CKRenderComponentProtocol>> *components2 = @[[CKTreeNodeTest_RenderComponent_NoInitialState new],
                                                          [CKTreeNodeTest_RenderComponent_NoInitialState new],
                                                          [CKTreeNodeTest_RenderComponent_WithState new],
                                                          [CKTreeNodeTest_RenderComponent_NoInitialState new]];

  __unused NSMutableArray<CKTreeNode*> *nodes2 = createsNodesForComponentsWithOwner(root2, root, [scopeRoot newRoot], components2);

  // Verify that the two trees are equal.
  XCTAssertTrue(areTreesEqual(root, root2));
}

- (void)test_childForComponentKey_onCKTreeNodeWithChildren_withDifferentChildOverGenerations
{
  // Simulate first component tree creation
  auto const scopeRoot = CKComponentScopeRootWithDefaultPredicates(nil, nil);
  auto const root1 = [[CKRenderTreeNode alloc] init];
  auto const component1 = [CKTreeNodeTest_RenderComponent_NoInitialState new];
  CKTreeNode *childNode1 = [[CKRenderTreeNode alloc] initWithComponent:component1
                                                                parent:root1
                                                        previousParent:nil
                                                             scopeRoot:scopeRoot
                                                          stateUpdates:{}];

  // Simulate a component tree creation with a DIFFRENT child
  auto const root2 = [[CKRenderTreeNode alloc] init];
  auto const component2 = [CKRenderComponent newWithView:{} size:{}];
  CKTreeNode *childNode2 = [[CKRenderTreeNode alloc] initWithComponent:component2
                                                                parent:root2
                                                        previousParent:root1
                                                             scopeRoot:[scopeRoot newRoot]
                                                          stateUpdates:{}];

  XCTAssertTrue(verifyChildToParentConnection(root1, childNode1, component1));
  XCTAssertTrue(verifyChildToParentConnection(root2, childNode2, component2));
  XCTAssertNotEqual(childNode1.nodeIdentifier, childNode2.nodeIdentifier);
}

#pragma mark - State

- (void)test_stateUpdate_onCKTreeNode
{
  // The 'resolve' method in CKComponentScopeHandle requires a CKThreadLocalComponentScope.
  // We should get rid of this assert once we move to the render method only.
  CKThreadLocalComponentScope threadScope(CKComponentScopeRootWithDefaultPredicates(nil, nil), {});

  // Simulate first component tree creation
  auto const root1 = [[CKRenderTreeNode alloc] init];
  auto const component1 = [CKTreeNodeTest_RenderComponent_WithState newWithView:{} size:{}];
  CKTreeNode *childNode = [[CKRenderTreeNode alloc] initWithComponent:component1
                                                               parent:root1
                                                       previousParent:nil
                                                            scopeRoot:threadScope.newScopeRoot
                                                         stateUpdates:{}];

  [CKRenderTreeNode didBuildComponentTree:childNode];

  // Verify that the initial state is correct.
  XCTAssertTrue([childNode.state isEqualToNumber:[[component1 class] initialState]]);

  // Simulate a component tree creation due to a state update
  auto const root2 = [[CKRenderTreeNode alloc] init];
  auto const component2 = [CKTreeNodeTest_RenderComponent_WithState newWithView:{} size:{}];

  // Simulate a state update
  auto const newState = @2;
  auto const scopeHandle = childNode.scopeHandle;
  CKComponentStateUpdateMap stateUpdates;
  stateUpdates[scopeHandle].push_back(^(id){
    return newState;
  });
  CKTreeNode *childNode2 = [[CKRenderTreeNode alloc] initWithComponent:component2
                                                                parent:root2
                                                        previousParent:root1
                                                             scopeRoot:[threadScope.newScopeRoot newRoot]
                                                          stateUpdates:stateUpdates];

  [CKRenderTreeNode didBuildComponentTree:childNode2];

  XCTAssertTrue([childNode2.state isEqualToNumber:newState]);
}

- (void)test_nonNil_initialState_onCKTreeNode_withCKComponentSubclass
{
  __block CKComponent *c;
  buildComponent(^CKComponent*{
    c = [CKTreeNodeTest_Component_WithState new];
    // Using flexbox here to add a render component to the hierarchy, which forces buildComponentTree:
    return CK::FlexboxComponentBuilder()
    .child(c)
    .child([CKTreeNodeTest_RenderComponent_WithNilState new])
    .build();
  });
  [self _test_nonNil_initialState_withComponent:c];
}

- (void)test_emptyInitialState_onCKTreeNode_withCKComponentSubclass
{
  auto const c = buildComponent(^{ return [CKComponent new]; });
  [self _test_emptyInitialState_withComponent:c];
}

- (void)test_nonNil_initialState_onCKRenderTreeNode_withCKRenderComponent
{
  auto const c = buildComponent(^{ return [CKTreeNodeTest_RenderComponent_WithState new]; });
  [self _test_nonNil_initialState_withComponent:c];
}

- (void)test_emptyInitialState_onCKRenderTreeNode_withCKRenderComponent
{
  auto const c = buildComponent(^{ return [CKTreeNodeTest_RenderComponent_NoInitialState new]; });
  [self _test_emptyInitialState_withComponent:c];
}

- (void)test_initialStateFromProps_onCKRenderTreeNode_withCKRenderComponent
{
  id prop = @1;
  auto const c = buildComponent(^{ return [CKTreeNodeTest_RenderComponent_WithStateFromProps newWithProp:prop]; });
  [self _test_initialState_withComponent:c initialState:prop];
}

- (void)test_nilInitialState_onCKRenderTreeNode_withCKRenderComponent
{
  // Make sure CKRenderComponent supports nil initial state from prop.
  id prop = nil;
  auto const c = buildComponent(^{ return [CKTreeNodeTest_RenderComponent_WithStateFromProps newWithProp:prop]; });
  [self _test_initialState_withComponent:c initialState:nil];

  // Make sure CKRenderComponent supports nil initial.
  auto const c2 = buildComponent(^{ return [CKTreeNodeTest_RenderComponent_WithNilState new]; });
  [self _test_initialState_withComponent:c2 initialState:nil];
}

- (void)test_componentIdentifierOnCKTreeNodeWithChildren_withReorder {
  // Simulate first component tree creation
  __block CKTreeNodeTest_RenderComponent_WithIdentifier *c1;
  __block CKTreeNodeTest_RenderComponent_WithIdentifier *c2;
  auto const results = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, ^CKComponent *{
    c1 = [CKTreeNodeTest_RenderComponent_WithIdentifier newWithIdentifier:@1];
    c2 = [CKTreeNodeTest_RenderComponent_WithIdentifier newWithIdentifier:@2];
    return CK::FlexboxComponentBuilder()
    .alignItems(CKFlexboxAlignItemsStretch)
    .child(c1)
    .child(c2)
    .build();
  });

  // Simulate a props update which *reorders* the children.
  __block CKTreeNodeTest_RenderComponent_WithIdentifier *c1SecondGen;
  __block CKTreeNodeTest_RenderComponent_WithIdentifier *c2SecondGen;
  auto const results2 = CKBuildComponent(results.scopeRoot, {}, ^CKComponent *{
    c1SecondGen = [CKTreeNodeTest_RenderComponent_WithIdentifier newWithIdentifier:@1];
    c2SecondGen = [CKTreeNodeTest_RenderComponent_WithIdentifier newWithIdentifier:@2];
    return CK::FlexboxComponentBuilder()
    .alignItems(CKFlexboxAlignItemsStretch)
    .child(c2SecondGen)
    .child(c1SecondGen)
    .build();
  });

  // Make sure each component retreive its correct state even after reorder.
  XCTAssertEqual(c1.scopeHandle.state, c1SecondGen.scopeHandle.state);
  XCTAssertEqual(c2.scopeHandle.state, c2SecondGen.scopeHandle.state);
}

- (void)test_componentIdentifierOnCKTreeNodeWithChildren_withRemovingComponents {
  // Simulate first component tree creation
  __block CKTreeNodeTest_RenderComponent_WithIdentifier *c1;
  __block CKTreeNodeTest_RenderComponent_WithIdentifier *c2;
  __block CKTreeNodeTest_RenderComponent_WithIdentifier *c3;
  auto const results = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, ^CKComponent *{
    c1 = [CKTreeNodeTest_RenderComponent_WithIdentifier newWithIdentifier:@1];
    c2 = [CKTreeNodeTest_RenderComponent_WithIdentifier newWithIdentifier:@2];
    c3 = [CKTreeNodeTest_RenderComponent_WithIdentifier newWithIdentifier:@3];
    return CK::FlexboxComponentBuilder()
    .alignItems(CKFlexboxAlignItemsStretch)
    .child(c1)
    .child(c2)
    .child(c3)
    .build();
  });

  // Simulate a props update which *removes* c2 from the hierarchy.
  __block CKTreeNodeTest_RenderComponent_WithIdentifier *c1SecondGen;
  __block CKTreeNodeTest_RenderComponent_WithIdentifier *c3SecondGen;
  auto const results2 = CKBuildComponent(results.scopeRoot, {}, ^CKComponent *{
    c1SecondGen = [CKTreeNodeTest_RenderComponent_WithIdentifier newWithIdentifier:@1];
    c3SecondGen = [CKTreeNodeTest_RenderComponent_WithIdentifier newWithIdentifier:@3];
    return CK::FlexboxComponentBuilder()
    .alignItems(CKFlexboxAlignItemsStretch)
    .child(c1SecondGen)
    .child(c3SecondGen)
    .build();
  });

  // Make sure each component retreive its correct state even after reorder.
  XCTAssertEqual(c1.scopeHandle.state, c1SecondGen.scopeHandle.state);
  XCTAssertEqual(c3.scopeHandle.state, c3SecondGen.scopeHandle.state);
}

#pragma mark - Helpers

- (void)_test_emptyInitialState_withComponent:(CKComponent *)c
{
  XCTAssertNil(c.scopeHandle.state);
}

- (void)_test_nonNil_initialState_withComponent:(CKComponent *)c
{
  XCTAssertEqual([[c class] initialState], c.scopeHandle.state);
  XCTAssertNotNil(c.scopeHandle);
}

- (void)_test_initialState_withComponent:(CKComponent *)c initialState:(id)initialState
{
  XCTAssertEqual(initialState, c.scopeHandle.state);
  XCTAssertNotNil(c.scopeHandle);
}

@end

@interface CKRenderTreeNodeTests : XCTestCase
@end

@implementation CKRenderTreeNodeTests

- (id<CKTreeNodeWithChildrenProtocol>)newTreeNodeWithChild
{
  return [CKRenderTreeNode new];
}

#pragma mark - CKTreeNodeWithChild

- (void)test_childForComponentKey_onCKTreeNodeWithChild {
  // Simulate first component tree creation
  auto const scopeRoot = CKComponentScopeRootWithDefaultPredicates(nil, nil);
  id<CKTreeNodeWithChildrenProtocol> root1 = [self newTreeNodeWithChild];
  auto const component1 = [CKTreeNodeTest_RenderComponent_NoInitialState new];
  CKTreeNode *childNode1 = [[CKRenderTreeNode alloc] initWithComponent:component1
                                                                parent:root1
                                                        previousParent:nil
                                                             scopeRoot:scopeRoot
                                                          stateUpdates:{}];

  // Simulate a component tree creation due to a state update
  id<CKTreeNodeWithChildrenProtocol> root2 = [self newTreeNodeWithChild];
  auto const component2 = [CKTreeNodeTest_RenderComponent_NoInitialState new];
  CKTreeNode *childNode2 = [[CKRenderTreeNode alloc] initWithComponent:component2
                                                                parent:root2
                                                        previousParent:root1
                                                             scopeRoot:[scopeRoot newRoot]
                                                          stateUpdates:{}];

  XCTAssertTrue(verifyChildToParentConnection(root1, childNode1, component1));
  XCTAssertTrue(verifyChildToParentConnection(root2, childNode2, component2));
}

- (void)test_nodeIdentifier_onCKTreeNodeWithChild_betweenGenerations {
  // Simulate first component tree creation
  auto const scopeRoot = CKComponentScopeRootWithDefaultPredicates(nil, nil);
  id<CKTreeNodeWithChildrenProtocol> root1 = [self newTreeNodeWithChild];
  auto const component1 = [CKTreeNodeTest_RenderComponent_NoInitialState new];
  CKTreeNode *childNode1 = [[CKRenderTreeNode alloc] initWithComponent:component1
                                                                parent:root1
                                                        previousParent:nil
                                                             scopeRoot:scopeRoot
                                                          stateUpdates:{}];

  // Simulate a component tree creation due to a state update
  id<CKTreeNodeWithChildrenProtocol> root2 = [self newTreeNodeWithChild];
  auto const component2 = [CKTreeNodeTest_RenderComponent_NoInitialState new];
  CKTreeNode *childNode2 = [[CKRenderTreeNode alloc] initWithComponent:component2
                                                                parent:root2
                                                        previousParent:root1
                                                             scopeRoot:[scopeRoot newRoot]
                                                          stateUpdates:{}];

  XCTAssertEqual(childNode1.nodeIdentifier, childNode2.nodeIdentifier);
}

- (void)test_childForComponentKey_onCKTreeNodeWithChild_withSameChildOverGenerations
{
  // Simulate first component tree creation
  auto const scopeRoot = CKComponentScopeRootWithDefaultPredicates(nil, nil);
  id<CKTreeNodeWithChildrenProtocol> root1 = [self newTreeNodeWithChild];
  auto const component1 = [CKTreeNodeTest_RenderComponent_NoInitialState new];
  CKTreeNode *childNode1 = [[CKRenderTreeNode alloc] initWithComponent:component1
                                                                parent:root1
                                                        previousParent:nil
                                                             scopeRoot:scopeRoot
                                                          stateUpdates:{}];

  // Simulate a component tree creation due to a state update
  id<CKTreeNodeWithChildrenProtocol> root2 = [self newTreeNodeWithChild];
  auto const component2 = [CKTreeNodeTest_RenderComponent_NoInitialState new];
  CKTreeNode *childNode2 = [[CKRenderTreeNode alloc] initWithComponent:component2
                                                                parent:root2
                                                        previousParent:root1
                                                             scopeRoot:[scopeRoot newRoot]
                                                          stateUpdates:{}];

  XCTAssertTrue(verifyChildToParentConnection(root1, childNode1, component1));
  XCTAssertTrue(verifyChildToParentConnection(root2, childNode2, component2));
  XCTAssertEqual(childNode1.nodeIdentifier, childNode2.nodeIdentifier);
}

- (void)test_childForComponentKey_onCKTreeNodeWithChild_withDifferentChildOverGenerations
{
  // Simulate first component tree creation
  auto const scopeRoot = CKComponentScopeRootWithDefaultPredicates(nil, nil);
  id<CKTreeNodeWithChildrenProtocol> root1 = [self newTreeNodeWithChild];
  auto const component1 = [CKTreeNodeTest_RenderComponent_NoInitialState new];
  CKTreeNode *childNode1 = [[CKRenderTreeNode alloc] initWithComponent:component1
                                                                parent:root1
                                                        previousParent:nil
                                                             scopeRoot:scopeRoot
                                                          stateUpdates:{}];

  // Simulate a component tree creation with a DIFFRENT child
  id<CKTreeNodeWithChildrenProtocol> root2 = [self newTreeNodeWithChild];
  auto const component2 = [CKRenderComponent newWithView:{} size:{}];
  CKTreeNode *childNode2 = [[CKRenderTreeNode alloc] initWithComponent:component2
                                                                parent:root2
                                                        previousParent:root1
                                                             scopeRoot:[scopeRoot newRoot]
                                                          stateUpdates:{}];

  XCTAssertTrue(verifyChildToParentConnection(root1, childNode1, component1));
  XCTAssertTrue(verifyChildToParentConnection(root2, childNode2, component2));
  XCTAssertNotEqual(childNode1.nodeIdentifier, childNode2.nodeIdentifier);
}

@end

#pragma mark - Helper Classes

@implementation CKTreeNodeTest_Component_WithState
+ (id)initialState
{
  return @1;
}
+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view
                       size:(const CKComponentSize &)size
{
  CKComponentScope scope(self);
  return [super newWithView:view size:size];
}
@end

@implementation CKTreeNodeTest_RenderComponent_WithState
+ (id)initialState
{
  return @1;
}
- (CKComponent *)render:(id)state
{
  return [CKComponent new];
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

- (id)initialState
{
  return _prop;
}

- (CKComponent *)render:(id)state
{
  return [CKComponent new];
}
@end

@implementation CKTreeNodeTest_RenderComponent_WithNilState
+ (id)initialState
{
  return nil;
}

- (CKComponent *)render:(id)state
{
  return [CKComponent new];
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
    c->_childComponent = component;
  }
  return c;
}

+ (id)initialState
{
  return nil;
}

- (CKComponent *)render:(id)state
{
  return _childComponent;
}
@end

@implementation CKTreeNodeTest_RenderComponent_WithIdentifier
{
  id<NSObject> _identifier;
}

+ (instancetype)newWithIdentifier:(id<NSObject>)identifier
{
  auto const c = [super new];
  if (c) {
    c->_identifier = identifier;
  }
  return c;
}

- (id<NSObject>)componentIdentifier
{
  return _identifier;
}

- (CKComponent *)render:(id)state
{
  return [CKComponent new];
}

- (id)initialState
{
  return _identifier;
}

@end

@implementation CKTreeNodeTest_RenderComponent_NoInitialState
- (CKComponent *)render:(id)state
{
  return [CKComponent new];
}
@end
