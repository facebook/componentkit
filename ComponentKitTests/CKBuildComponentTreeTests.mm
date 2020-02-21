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
#import <ComponentKit/CKMountable.h>
#import <ComponentKit/CKRenderHelpers.h>
#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKCompositeComponent.h>
#import <ComponentKit/CKRenderComponent.h>
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKButtonComponent.h>
#import <ComponentKit/CKComponentScopeRootFactory.h>
#import <ComponentKit/CKThreadLocalComponentScope.h>
#import <ComponentKit/CKRenderTreeNode.h>
#import <ComponentKit/CKScopeTreeNode.h>

/** A helper class that inherits from 'CKRenderComponent'; render the component from the initializer */
@interface CKComponentTreeTestComponent_Render : CKRenderComponent
+ (instancetype)newWithComponent:(CKComponent *)component;
@end

/** A helper class that inherits from 'CKRenderComponent' and render a random CKComponent */
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
  CKComponent *c = [CKComponentTreeTestComponent_Render new];

  [c buildComponentTree:root previousParent:nil params:{
    .scopeRoot = scopeRoot,
    .stateUpdates = {},
    .buildTrigger = CKBuildTrigger::NewTree,
    .treeNodeDirtyIds = {},
  } parentHasStateUpdate:NO];

  XCTAssertEqual(root.children.size(), 1);
  XCTAssertEqual(root.children[0].component, c);

  // Simulate a second tree creation.
  auto const scopeRoot2 = [scopeRoot newRoot];
  auto const root2 = scopeRoot2.rootNode.node();
  CKComponent *c2 = [CKComponentTreeTestComponent_Render new];

  [c2 buildComponentTree:root2 previousParent:root params:{
    .scopeRoot = scopeRoot2,
    .previousScopeRoot = scopeRoot,
    .stateUpdates = {},
    .buildTrigger = CKBuildTrigger::PropsUpdate,
    .treeNodeDirtyIds = {},
  } parentHasStateUpdate:NO];
  XCTAssertTrue(areTreesEqual(root, root2));
}

#pragma mark - CKRenderComponent

- (void)test_buildComponentTree_onCKRenderComponent
{
  auto const scopeRoot = CKComponentScopeRootWithDefaultPredicates(nil, nil);
  auto const root = scopeRoot.rootNode.node();
  CKComponent *c = [CKComponentTreeTestComponent_Render new];

  CKRenderComponent *renderComponent = [CKComponentTreeTestComponent_Render newWithComponent:c];
  [renderComponent buildComponentTree:root previousParent:nil params:{
    .scopeRoot = scopeRoot,
    .stateUpdates = {},
    .buildTrigger = CKBuildTrigger::NewTree,
    .treeNodeDirtyIds = {},
  } parentHasStateUpdate:NO];

  // Make sure the root has only one child.
  XCTAssertEqual(root.children.size(), 1);
  CKTreeNode *singleChildNode = root.children[0];
  verifyChildToParentConnection(root, singleChildNode, renderComponent);

  // Check the next level of the tree
  if ([singleChildNode conformsToProtocol:@protocol(CKTreeNodeWithChildrenProtocol)]) {
    auto const parentNode = (id<CKTreeNodeWithChildrenProtocol>)singleChildNode;
    XCTAssertEqual(parentNode.children.size(), 1);
    CKTreeNode *componentNode = parentNode.children[0];
    verifyChildToParentConnection(parentNode, componentNode, c);
  } else {
    XCTFail(@"singleChildNode has to conform to CKTreeNodeWithChildrenProtocol as it has a child.");
  }

  // Simulate a second tree creation.
  auto const scopeRoot2 = [scopeRoot newRoot];
  auto const root2 = scopeRoot2.rootNode.node();
  CKComponent *c2 = [CKComponentTreeTestComponent_Render new];

  CKRenderComponent *renderComponent2 = [CKComponentTreeTestComponent_Render newWithComponent:c2];
  [renderComponent2 buildComponentTree:root2 previousParent:root params:{
    .scopeRoot = scopeRoot2,
    .previousScopeRoot = scopeRoot,
    .stateUpdates = {},
    .buildTrigger = CKBuildTrigger::PropsUpdate,
    .treeNodeDirtyIds = {},
  } parentHasStateUpdate:NO];
  XCTAssertTrue(areTreesEqual(root, root2));
}

#pragma mark - CKLayoutComponent

- (void)test_buildComponentTree_onCKLayoutComponent
{
  CKThreadLocalComponentScope threadScope(CKComponentScopeRootWithDefaultPredicates(nil, nil), {});
  auto const scopeRoot = threadScope.newScopeRoot;
  auto const root = [CKScopeTreeNode new];
  CKComponent *c10 = [CKComponentTreeTestComponent_Render new];
  CKComponent *c11 = [CKComponentTreeTestComponent_Render new];
  auto renderWithChidlrenComponent = [CKTestLayoutComponent newWithChildren:{c10, c11}];
  [renderWithChidlrenComponent buildComponentTree:root previousParent:nil params:{
    .scopeRoot = scopeRoot,
    .previousScopeRoot = nil,
    .stateUpdates = {},
    .buildTrigger = CKBuildTrigger::NewTree,
    .treeNodeDirtyIds = {},
  } parentHasStateUpdate:NO];

  XCTAssertEqual(root.children.size(), 2);
  XCTAssertTrue(verifyComponentsInNode(root, @[c10, c11]));

  // Simulate a second tree creation.
  auto const scopeRoot2 = [scopeRoot newRoot];
  auto const root2 = scopeRoot2.rootNode.node();
  CKComponent *c20 = [CKComponentTreeTestComponent_Render new];
  CKComponent *c21 = [CKComponentTreeTestComponent_Render new];
  auto renderWithChidlrenComponent2 = [CKTestLayoutComponent newWithChildren:{c20, c21}];
  [renderWithChidlrenComponent2 buildComponentTree:root2 previousParent:root params:{
    .scopeRoot = scopeRoot2,
    .previousScopeRoot = scopeRoot,
    .stateUpdates = {},
    .buildTrigger = CKBuildTrigger::PropsUpdate,
    .treeNodeDirtyIds = {},
  } parentHasStateUpdate:NO];
  XCTAssertTrue(areTreesEqual(root, root2));
}

#pragma mark - Build Component Helpers

- (void)test_renderComponentHelpers_treeNodeDirtyIdsFor_onNewTreeAndPropsUpdate
{
  XCTAssertTrue(CKRender::treeNodeDirtyIdsFor(nil, {}, CKBuildTrigger::NewTree).empty(), @"It is not expected to have dirty nodes when new tree generation is triggered");
  XCTAssertTrue(CKRender::treeNodeDirtyIdsFor(nil, {}, CKBuildTrigger::PropsUpdate).empty(), @"It is not expected to have dirty nodes on tree generation triggered by props update");

  XCTAssertTrue(CKRender::treeNodeDirtyIdsFor(nil, {}, CKBuildTrigger::NewTree).empty(), @"It is not expected to have dirty nodes when new tree generation is triggered");
  XCTAssertTrue(CKRender::treeNodeDirtyIdsFor(nil, {}, CKBuildTrigger::PropsUpdate).empty(), @"It is not expected to have dirty nodes on tree generation triggered by props update");
}

- (void)test_renderComponentHelpers_treeNodeDirtyIdsFor_onStateUpdate
{
  __block CKComponentTreeTestComponent_Render *c;
  __block CKCompositeComponentWithScopeAndState *rootComponent;
  auto const componentFactory = ^{
    c = [CKComponentTreeTestComponent_Render newWithComponent:CK::ComponentBuilder().build()];
    rootComponent = [CKCompositeComponentWithScopeAndState newWithComponent:c];
    return rootComponent;
  };

  auto const buildResults = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, componentFactory);

  // Simulate a state update on the root.
  CKComponentStateUpdateMap stateUpdates;
  stateUpdates[rootComponent.scopeHandle].push_back(^(id){
    return @2;
  });

  CKTreeNodeDirtyIds dirtyNodeIds = CKRender::treeNodeDirtyIdsFor(buildResults.scopeRoot, stateUpdates, CKBuildTrigger::StateUpdate);
  CKTreeNodeDirtyIds expectedDirtyNodeIds = {rootComponent.scopeHandle.treeNodeIdentifier};
  XCTAssertEqual(dirtyNodeIds, expectedDirtyNodeIds);
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
    [componentsFromTheTree addObject:(CKComponent *)node.component];
  }
  NSSet<id<CKMountable>> *componentsSet = [NSSet setWithArray:components];
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
    if ([childNode isKindOfClass:[CKRenderTreeNode class]]) {
      treeChildrenIdentifiers((CKRenderTreeNode *)childNode, identifiers, level+1);
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
- (BOOL)requiresScopeHandle
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
