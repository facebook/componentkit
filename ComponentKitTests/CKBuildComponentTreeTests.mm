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

#import <ComponentKit/CKFlexboxComponent.h>

#import <ComponentKitTestHelpers/CKRenderComponentTestHelpers.h>

#import "CKRenderHelpers.h"
#import "CKComponent.h"
#import "CKCompositeComponent.h"
#import "CKRenderComponent.h"
#import "CKRenderLayoutWithChildrenComponent.h"
#import "CKComponentInternal.h"
#import "CKButtonComponent.h"
#import "CKTreeNode.h"
#import "CKTreeNodeWithChild.h"
#import "CKTreeNodeWithChildren.h"
#import "CKComponentScopeRootFactory.h"
#import "CKThreadLocalComponentScope.h"
#import "CKScopeTreeNode.h"

/** An helper class that inherits from 'CKRenderComponent'; render the component from the initializer */
@interface CKComponentTreeTestComponent_Render : CKRenderComponent
+ (instancetype)newWithComponent:(CKComponent *)component;
@end

/** An helper class that inherits from 'CKRenderComponent' and render a random CKComponent */
@interface CKComponentTreeTestComponent_RenderWithChild : CKRenderComponent
@property (nonatomic, strong) CKCompositeComponentWithScopeAndState *childComponent;
@property (nonatomic, assign) BOOL hasReusedComponent;
@end

#pragma mark - Tests

@interface CKBuildComponentTreeTests : XCTestCase
@end

@implementation CKBuildComponentTreeTests

#pragma mark - CKComponent

- (void)test_buildComponentTree_onCKComponent
{
  auto const scopeRoot = CKComponentScopeRootWithDefaultPredicates(nil, nil);
  auto const root = scopeRoot.rootNode.node();
  CKComponent *c = [CKComponent newWithView:{} size:{}];
  [c buildComponentTree:root previousParent:nil params:{
    .scopeRoot = scopeRoot,
    .stateUpdates = {},
    .buildTrigger = BuildTrigger::NewTree,
    .treeNodeDirtyIds = {},
  } parentHasStateUpdate:NO];

  XCTAssertEqual(root.children.size(), 1);
  XCTAssertEqual(root.children[0].component, c);

  // Simulate a second tree creation.
  auto const scopeRoot2 = [scopeRoot newRoot];
  auto const root2 = scopeRoot2.rootNode.node();
  CKComponent *c2 = [CKComponent newWithView:{} size:{}];
  [c2 buildComponentTree:root2 previousParent:root params:{
    .scopeRoot = scopeRoot2,
    .previousScopeRoot = scopeRoot,
    .stateUpdates = {},
    .buildTrigger = BuildTrigger::PropsUpdate,
    .treeNodeDirtyIds = {},
  } parentHasStateUpdate:NO];
  XCTAssertTrue(areTreesEqual(root, root2));
}

#pragma mark - CKRenderComponent

- (void)test_buildComponentTree_onCKRenderComponent
{
  auto const scopeRoot = CKComponentScopeRootWithDefaultPredicates(nil, nil);
  auto const root = scopeRoot.rootNode.node();
  CKComponent *c = [CKComponent newWithView:{} size:{}];
  CKRenderComponent *renderComponent = [CKComponentTreeTestComponent_Render newWithComponent:c];
  [renderComponent buildComponentTree:root previousParent:nil params:{
    .scopeRoot = scopeRoot,
    .stateUpdates = {},
    .buildTrigger = BuildTrigger::NewTree,
    .treeNodeDirtyIds = {},
  } parentHasStateUpdate:NO];

  // Make sure the root has only one child.
  XCTAssertEqual(root.children.size(), 1);
  CKTreeNode *singleChildNode = root.children[0];
  verifyChildToParentConnection(root, singleChildNode, renderComponent);

  // Check the next level of the tree
  if ([singleChildNode conformsToProtocol:@protocol(CKTreeNodeWithChildProtocol)]) {
    id<CKTreeNodeWithChildProtocol> parentNode = (id<CKTreeNodeWithChildProtocol>)singleChildNode;
    XCTAssertEqual(parentNode.children.size(), 1);
    CKTreeNode *componentNode = parentNode.children[0];
    verifyChildToParentConnection(parentNode, componentNode, c);
  } else {
    XCTFail(@"singleChildNode has to conform to CKTreeNodeWithChildProtocol as it has a child.");
  }

  // Simulate a second tree creation.
  auto const scopeRoot2 = [scopeRoot newRoot];
  auto const root2 = scopeRoot2.rootNode.node();
  CKComponent *c2 = [CKComponent newWithView:{} size:{}];
  CKRenderComponent *renderComponent2 = [CKComponentTreeTestComponent_Render newWithComponent:c2];
  [renderComponent2 buildComponentTree:root2 previousParent:root params:{
    .scopeRoot = scopeRoot2,
    .previousScopeRoot = scopeRoot,
    .stateUpdates = {},
    .buildTrigger = BuildTrigger::PropsUpdate,
    .treeNodeDirtyIds = {},
  } parentHasStateUpdate:NO];
  XCTAssertTrue(areTreesEqual(root, root2));
}

#pragma mark - CKRenderLayoutWithChildrenComponent

- (void)test_buildComponentTree_onCKRenderWithChildrenComponent
{
  CKThreadLocalComponentScope threadScope(CKComponentScopeRootWithDefaultPredicates(nil, nil), {});
  auto const scopeRoot = threadScope.newScopeRoot;
  CKTreeNodeWithChildren *root = [[CKTreeNodeWithChildren alloc] init];
  CKComponent *c10 = [CKComponent newWithView:{} size:{}];
  CKComponent *c11 = [CKComponent newWithView:{} size:{}];
  auto renderWithChidlrenComponent = [CKTestRenderWithChildrenComponent newWithChildren:{c10, c11}];
  [renderWithChidlrenComponent buildComponentTree:root previousParent:nil params:{
    .scopeRoot = scopeRoot,
    .previousScopeRoot = nil,
    .stateUpdates = {},
    .buildTrigger = BuildTrigger::NewTree,
    .treeNodeDirtyIds = {},
  } parentHasStateUpdate:NO];

  XCTAssertEqual(root.children.size(), 1);
  XCTAssertTrue(verifyComponentsInNode(root, @[renderWithChidlrenComponent]));

  // Verify that the child component has 2 children nodes.
  CKTreeNode *childNode = root.children[0];
  // Check the next level of the tree
  if ([childNode isKindOfClass:[CKTreeNodeWithChildren class]]) {
    CKTreeNodeWithChildren *parentNode = (CKTreeNodeWithChildren *)childNode;
    XCTAssertEqual(parentNode.children.size(), 2);
    XCTAssertTrue(verifyComponentsInNode(parentNode, @[c10, c11]));
  } else {
    XCTFail(@"childNode has to be CKTreeNodeWithChildren as it has children.");
  }

  // Simulate a second tree creation.
  auto const scopeRoot2 = [scopeRoot newRoot];
  auto const root2 = scopeRoot2.rootNode.node();
  CKComponent *c20 = [CKComponent newWithView:{} size:{}];
  CKComponent *c21 = [CKComponent newWithView:{} size:{}];
  auto renderWithChidlrenComponent2 = [CKTestRenderWithChildrenComponent newWithChildren:{c20, c21}];
  [renderWithChidlrenComponent2 buildComponentTree:root2 previousParent:root params:{
    .scopeRoot = scopeRoot2,
    .previousScopeRoot = scopeRoot,
    .stateUpdates = {},
    .buildTrigger = BuildTrigger::PropsUpdate,
    .treeNodeDirtyIds = {},
  } parentHasStateUpdate:NO];
  XCTAssertTrue(areTreesEqual(root, root2));
}

#pragma mark - Build Component Helpers

- (void)test_renderComponentHelpers_treeNodeDirtyIdsFor_onNewTreeAndPropsUpdate
{
  XCTAssertTrue(CKRender::treeNodeDirtyIdsFor(nil, {}, BuildTrigger::NewTree).empty(), @"It is not expected to have dirty nodes when new tree generation is triggered");
  XCTAssertTrue(CKRender::treeNodeDirtyIdsFor(nil, {}, BuildTrigger::PropsUpdate).empty(), @"It is not expected to have dirty nodes on tree generation triggered by props update");

  XCTAssertTrue(CKRender::treeNodeDirtyIdsFor(nil, {}, BuildTrigger::NewTree).empty(), @"It is not expected to have dirty nodes when new tree generation is triggered");
  XCTAssertTrue(CKRender::treeNodeDirtyIdsFor(nil, {}, BuildTrigger::PropsUpdate).empty(), @"It is not expected to have dirty nodes on tree generation triggered by props update");
}

- (void)test_renderComponentHelpers_treeNodeDirtyIdsFor_onStateUpdate
{
  __block CKComponentTreeTestComponent_Render *c;
  __block CKCompositeComponentWithScopeAndState *rootComponent;
  auto const componentFactory = ^{
    c = [CKComponentTreeTestComponent_Render newWithComponent:[CKComponent newWithView:{} size:{}]];
    rootComponent = [CKCompositeComponentWithScopeAndState
                     newWithComponent:c];
    return rootComponent;
  };

  auto const buildResults = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, componentFactory, {});

  // Simulate a state update on the root.
  CKComponentStateUpdateMap stateUpdates;
  stateUpdates[rootComponent.scopeHandle].push_back(^(id){
    return @2;
  });

  CKTreeNodeDirtyIds dirtyNodeIds = CKRender::treeNodeDirtyIdsFor(buildResults.scopeRoot, stateUpdates, BuildTrigger::StateUpdate);
  CKTreeNodeDirtyIds expectedDirtyNodeIds = {rootComponent.scopeHandle.treeNodeIdentifier};
  XCTAssertEqual(dirtyNodeIds, expectedDirtyNodeIds);
}

- (void)test_renderComponentHelpers_treeNodeDirtyIdsFor_updateParentOnStateUpdate
{
  __block CKComponentTreeTestComponent_RenderWithChild *child1;
  __block CKCompositeComponentWithScopeAndState *child2;
  __block CKTestRenderWithChildrenComponent *rootComponent;
  auto const componentFactory = ^{
    child1 = [CKComponentTreeTestComponent_RenderWithChild new];
    child2 =  [CKCompositeComponentWithScopeAndState newWithComponent:[CKComponent new]];
    rootComponent = [CKTestRenderWithChildrenComponent newWithChildren:{child1, child2}];
    return rootComponent;
  };

  auto const buildResults = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, componentFactory, {});
  XCTAssertFalse(child1.hasReusedComponent);

  // Simulate a state update on child2 (child1 should be reused in this case).
  CKComponentStateUpdateMap stateUpdates;
  stateUpdates[child2.scopeHandle].push_back(^(id){
    return @2;
  });

  auto const buildResultsAfterStateUpdate = CKBuildComponent(buildResults.scopeRoot, stateUpdates, componentFactory, {});
  XCTAssertTrue(child1.hasReusedComponent);


  // Simulate a state update on `child1.childComponent` - which should mark the path from `child1.childComponent` to the root as dirty.
  CKComponentStateUpdateMap stateUpdates2;
  stateUpdates2[child1.childComponent.scopeHandle].push_back(^(id){
    return @2;
  });

  auto const dirtyNodeIds = CKRender::treeNodeDirtyIdsFor(buildResultsAfterStateUpdate.scopeRoot, stateUpdates2, BuildTrigger::StateUpdate);
  CKTreeNodeDirtyIds expectedDirtyNodeIds = {
    child1.childComponent.scopeHandle.treeNodeIdentifier,
    child1.scopeHandle.treeNodeIdentifier,
    rootComponent.scopeHandle.treeNodeIdentifier,
  };

  auto const child1ParentNode = buildResultsAfterStateUpdate.scopeRoot.rootNode.parentForNodeIdentifier(child1.scopeHandle.treeNodeIdentifier);
  auto const child1ChildComponentParentNode = buildResultsAfterStateUpdate.scopeRoot.rootNode.parentForNodeIdentifier(child1.childComponent.scopeHandle.treeNodeIdentifier);
  XCTAssertTrue(child1ParentNode.component == rootComponent);
  XCTAssertTrue(child1ChildComponentParentNode.component == child1);
  XCTAssertTrue(dirtyNodeIds == expectedDirtyNodeIds);
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
    if ([childNode isKindOfClass:[CKTreeNodeWithChildren class]]) {
      treeChildrenIdentifiers((CKTreeNodeWithChildren *)childNode, identifiers, level+1);
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

@implementation CKComponentTreeTestComponent_RenderWithChild
+ (BOOL)requiresScopeHandle
{
  return YES;
}
- (CKComponent *)render:(id)state
{
  _childComponent = [CKCompositeComponentWithScopeAndState newWithComponent:[CKComponent new]];
  return _childComponent;
}

- (void)didReuseComponent:(CKComponentTreeTestComponent_RenderWithChild *)component
{
  _childComponent = component->_childComponent;
  _hasReusedComponent = YES;
}
@end
