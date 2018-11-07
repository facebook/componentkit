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
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKThreadLocalComponentScope.h>
#import <ComponentKit/CKComponentScopeRootFactory.h>

#import <ComponentKitTestHelpers/CKRenderComponentTestHelpers.h>

#import "CKTreeNodeWithChild.h"
#import "CKTreeNodeWithChildren.h"

@interface CKRenderComponentTests : XCTestCase
@end

@implementation CKRenderComponentTests
{
  CKBuildComponentConfig _config;
  CKTestRenderComponent *_c;
  CKComponentScopeRoot *_scopeRoot;

  BOOL _enableFasterStateUpdates;
  BOOL _enableFasterPropsUpdates;
}

- (void)setUpForFasterStateUpdates
{
  _enableFasterStateUpdates = YES;

  _config = {
    .enableFasterStateUpdates = _enableFasterStateUpdates,
    .enableFasterPropsUpdates = _enableFasterPropsUpdates,
  };

  // New Tree Creation.
  _c = [CKTestRenderComponent new];
  _scopeRoot = createNewTreeWithComponentAndReturnScopeRoot(_config, _c);
  XCTAssertEqual(_c.renderCalledCounter, 1);
}

- (void)setUpForFasterPropsUpdates:(CKTestRenderComponent *)component
{
  _enableFasterPropsUpdates = YES;

  _config = {
    .enableFasterStateUpdates = _enableFasterStateUpdates,
    .enableFasterPropsUpdates = _enableFasterPropsUpdates,
  };

  // New Tree Creation.
  _c = component;
  _scopeRoot = createNewTreeWithComponentAndReturnScopeRoot(_config, _c);
  XCTAssertEqual(_c.renderCalledCounter, 1);
}

#pragma mark - State updates

- (void)test_fasterStateUpdate_componentIsNotBeingReused_onPropsUpdate
{
  [self setUpForFasterStateUpdates];

  // Simulate props update.
  CKThreadLocalComponentScope threadScope(_scopeRoot, {});
  auto const c2 = [CKTestRenderComponent new];
  CKComponentScopeRoot *scopeRoot2 = threadScope.newScopeRoot;
  [c2 buildComponentTree:scopeRoot2.rootNode
          previousParent:_scopeRoot.rootNode
                  params:{
                    .scopeRoot = scopeRoot2,
                    .stateUpdates = {},
                    .treeNodeDirtyIds = {},
                    .buildTrigger = BuildTrigger::PropsUpdate,
                  }
    parentHasStateUpdate:NO];

  [self verifyComponentIsNotBeingReused:_c c2:c2 scopeRoot:_scopeRoot scopeRoot2:scopeRoot2];
}

- (void)test_fasterStateUpdate_componentIsBeingReused_onStateUpdateOnADifferentComponentBranch
{
  [self setUpForFasterStateUpdates];

  // Simulate a state update on a different component branch:
  // 1. treeNodeDirtyIds with fake components ids.
  // 2. parentHasStateUpdate = NO
  CKThreadLocalComponentScope threadScope(_scopeRoot, {});
  auto const c2 = [CKTestRenderComponent new];
  CKComponentScopeRoot *scopeRoot2 = threadScope.newScopeRoot;

  [c2 buildComponentTree:scopeRoot2.rootNode
          previousParent:_scopeRoot.rootNode
                  params:{
                    .scopeRoot = scopeRoot2,
                    .previousScopeRoot = _scopeRoot,
                    .stateUpdates = {},
                    .treeNodeDirtyIds = {100, 101}, // Use a random id that represents a fake state update on a different branch.
                    .buildTrigger = BuildTrigger::StateUpdate,
                    .enableFasterStateUpdates = _config.enableFasterStateUpdates,
                    .enableFasterPropsUpdates = _config.enableFasterPropsUpdates,
                  }
    parentHasStateUpdate:NO];

  // As the state update doesn't affect the c2, we should reuse c instead.
  [self verifyComponentIsBeingReused:_c c2:c2 scopeRoot:_scopeRoot scopeRoot2:scopeRoot2];
}

- (void)test_fasterStateUpdate_componentIsNotBeingReused_onStateUpdateOnAParent
{
  [self setUpForFasterStateUpdates];

  // Simulate a state update on a parent component:
  // 1. parentHasStateUpdate = YES
  // 2. treeNodeDirtyIds with a fake parent id.
  CKThreadLocalComponentScope threadScope(_scopeRoot, {});
  CKComponentScopeRoot *scopeRoot2 = threadScope.newScopeRoot;

  auto const c2 = [CKTestRenderComponent new];
  [c2 buildComponentTree:scopeRoot2.rootNode
          previousParent:_scopeRoot.rootNode
                  params:{
                    .scopeRoot = scopeRoot2,
                    .stateUpdates = {},
                    .treeNodeDirtyIds = {100}, // Use a random id that represents a state update on a fake parent.
                    .buildTrigger = BuildTrigger::StateUpdate,
                    .enableFasterStateUpdates = _config.enableFasterStateUpdates,
                    .enableFasterPropsUpdates = _config.enableFasterPropsUpdates,
                  }
    parentHasStateUpdate:YES];

  // As the state update affect c2, we should recreate its children.
  [self verifyComponentIsNotBeingReused:_c c2:c2 scopeRoot:_scopeRoot scopeRoot2:scopeRoot2];
  // Make sure the dirtyParent is pssed correctly to the child component.
  XCTAssertTrue(c2.childComponent.parentHasStateUpdate);
}

- (void)test_fasterStateUpdate_componentIsNotBeingReused_onStateUpdateOnTheComponent
{
  [self setUpForFasterStateUpdates];

  // Simulate a state update on the component itself:
  // 1. treeNodeDirtyIds, contains the component tree node id.
  // 2. stateUpdates, contains a state update block for the component.
  CKThreadLocalComponentScope threadScope(_scopeRoot, {});
  CKComponentScopeRoot *scopeRoot2 = threadScope.newScopeRoot;

  CKComponentStateUpdateMap stateUpdates;
  stateUpdates[_c.scopeHandle] = {^id(id s) { return s; }};

  auto const c2 = [CKTestRenderComponent new];
  [c2 buildComponentTree:scopeRoot2.rootNode
          previousParent:_scopeRoot.rootNode
                  params:{
                    .scopeRoot = scopeRoot2,
                    .stateUpdates = stateUpdates,
                    .treeNodeDirtyIds = {
                      _c.scopeHandle.treeNode.nodeIdentifier
                    },
                    .buildTrigger = BuildTrigger::StateUpdate,
                    .enableFasterStateUpdates = _config.enableFasterStateUpdates,
                    .enableFasterPropsUpdates = _config.enableFasterPropsUpdates,
                  }
    parentHasStateUpdate:NO];

  // As the state update affect c2, we should recreate its children.
  [self verifyComponentIsNotBeingReused:_c c2:c2 scopeRoot:_scopeRoot scopeRoot2:scopeRoot2];
  // Make sure the dirtyParent is pssed correctly to the child component.
  XCTAssertTrue(c2.childComponent.parentHasStateUpdate);
}

- (void)test_fasterStateUpdate_componentIsNotBeingReused_onStateUpdateOnItsChild
{
  [self setUpForFasterStateUpdates];

  // Simulate a state update on the component child:
  // 1. treeNodeDirtyIds, contains the component tree node id.
  // 2. stateUpdates, contains a state update block for the component.
  // 3. hasDirtyParent = NO
  CKThreadLocalComponentScope threadScope(_scopeRoot, {});
  CKComponentScopeRoot *scopeRoot2 = threadScope.newScopeRoot;

  CKComponentStateUpdateMap stateUpdates;
  stateUpdates[_c.scopeHandle] = {^id(id s) { return s; }};

  auto const c2 = [CKTestRenderComponent new];

  [c2 buildComponentTree:scopeRoot2.rootNode
          previousParent:_scopeRoot.rootNode
                  params:{
                    .scopeRoot = scopeRoot2,
                    .stateUpdates = stateUpdates,
                    .treeNodeDirtyIds = {
                      _c.scopeHandle.treeNode.nodeIdentifier
                    },
                    .buildTrigger = BuildTrigger::StateUpdate,
                    .enableFasterStateUpdates = _config.enableFasterStateUpdates,
                    .enableFasterPropsUpdates = _config.enableFasterPropsUpdates,
                  }
    parentHasStateUpdate:NO];

  // As the state update affect c2, we should recreate its children.
  [self verifyComponentIsNotBeingReused:_c c2:c2 scopeRoot:_scopeRoot scopeRoot2:scopeRoot2];
  // Make sure the dirtyParent is pssed correctly to the child component.
  XCTAssertTrue(c2.childComponent.parentHasStateUpdate);
}

#pragma mark - Faster Props Update

- (void)test_fasterPropsUpdate_componentIsNotBeingReused_whenPropsAreNotEqual
{
  [self setUpForFasterPropsUpdates:[CKTestRenderComponent newWithIdentifier:1]];

  // Simulate props update.
  CKThreadLocalComponentScope threadScope(_scopeRoot, {});
  auto const c2 = [CKTestRenderComponent newWithIdentifier:2];
  CKComponentScopeRoot *scopeRoot2 = threadScope.newScopeRoot;

  [c2 buildComponentTree:scopeRoot2.rootNode
          previousParent:_scopeRoot.rootNode
                  params:{
                    .scopeRoot = scopeRoot2,
                    .stateUpdates = {},
                    .treeNodeDirtyIds = {},
                    .buildTrigger = BuildTrigger::PropsUpdate,
                    .enableFasterStateUpdates = _config.enableFasterStateUpdates,
                    .enableFasterPropsUpdates = _config.enableFasterPropsUpdates,
                  }
    parentHasStateUpdate:NO];

  // Props are not equal, we cannot reuse the component in this case.
  [self verifyComponentIsNotBeingReused:_c c2:c2 scopeRoot:_scopeRoot scopeRoot2:scopeRoot2];
  // Make sure the dirtyParent is pssed correctly to the child component.
  XCTAssertFalse(c2.childComponent.parentHasStateUpdate);
}

- (void)test_fasterPropsUpdate_componentIsBeingReusedWhenPropsAreEqual
{
  // Use the same componentIdentifier for both components.
  // shouldComponentUpdate: will return NO in this case and we can reuse the component.
  NSUInteger componentIdentifier = 1;
  [self setUpForFasterPropsUpdates:[CKTestRenderComponent newWithIdentifier:componentIdentifier]];

  // Simulate props update.
  CKThreadLocalComponentScope threadScope(_scopeRoot, {});
  auto const c2 = [CKTestRenderComponent newWithIdentifier:componentIdentifier];
  CKComponentScopeRoot *scopeRoot2 = threadScope.newScopeRoot;

  [c2 buildComponentTree:scopeRoot2.rootNode
          previousParent:_scopeRoot.rootNode
                  params:{
                    .scopeRoot = scopeRoot2,
                    .previousScopeRoot = _scopeRoot,
                    .stateUpdates = {},
                    .treeNodeDirtyIds = {},
                    .buildTrigger = BuildTrigger::PropsUpdate,
                    .enableFasterStateUpdates = _config.enableFasterStateUpdates,
                    .enableFasterPropsUpdates = _config.enableFasterPropsUpdates,
                  }
    parentHasStateUpdate:NO];

  // The components are equal, we can reuse the previous component.
  [self verifyComponentIsBeingReused:_c c2:c2 scopeRoot:_scopeRoot scopeRoot2:scopeRoot2];
  // Make sure the dirtyParent is pssed correctly to the child component.
  XCTAssertFalse(c2.childComponent.parentHasStateUpdate);
}

- (void)test_fasterPropsUpdate_componentIsBeingReused_onStateUpdateWithDirtyParentAndEqualComponents
{
  auto const componentIdentifier = 1;
  [self setUpForFasterPropsUpdates:[CKTestRenderComponent newWithIdentifier:componentIdentifier]];

  // Simulate a state update on a parent component:
  // 1. parentHasStateUpdate = YES
  // 2. treeNodeDirtyIds with a fake parent id.
  CKThreadLocalComponentScope threadScope(_scopeRoot, {});
  auto const c2 = [CKTestRenderComponent newWithIdentifier:componentIdentifier];
  CKComponentScopeRoot *scopeRoot2 = threadScope.newScopeRoot;

  [c2 buildComponentTree:scopeRoot2.rootNode
          previousParent:_scopeRoot.rootNode
                  params:{
                    .scopeRoot = scopeRoot2,
                    .previousScopeRoot = _scopeRoot,
                    .stateUpdates = {},
                    .treeNodeDirtyIds = {100}, // Use a random id that represents a state update on a fake parent.
                    .buildTrigger = BuildTrigger::StateUpdate,
                    .enableFasterStateUpdates = _config.enableFasterStateUpdates,
                    .enableFasterPropsUpdates = _config.enableFasterPropsUpdates,
                  }
    parentHasStateUpdate:YES];

  // c has dirty parent, however, the components are equal, so we reuse the previous component.
  [self verifyComponentIsBeingReused:_c c2:c2 scopeRoot:_scopeRoot scopeRoot2:scopeRoot2];
}

- (void)test_fasterPropsUpdate_componentIsBeingReused_onStateUpdateWithNonDirtyComponentAndEqualComponents
{
  auto const componentIdentifier = 1;
  [self setUpForFasterPropsUpdates:[CKTestRenderComponent newWithIdentifier:componentIdentifier]];

  // Simulate a state update on a parent component:
  // 1. parentHasStateUpdate = NO
  // 2. treeNodeDirtyIds is empty.
  CKThreadLocalComponentScope threadScope(_scopeRoot, {});
  auto const c2 = [CKTestRenderComponent newWithIdentifier:componentIdentifier];
  CKComponentScopeRoot *scopeRoot2 = threadScope.newScopeRoot;

  [c2 buildComponentTree:scopeRoot2.rootNode
          previousParent:_scopeRoot.rootNode
                  params:{
                    .scopeRoot = scopeRoot2,
                    .previousScopeRoot = _scopeRoot,
                    .stateUpdates = {},
                    .treeNodeDirtyIds = {},
                    .buildTrigger = BuildTrigger::StateUpdate,
                    .enableFasterStateUpdates = _config.enableFasterStateUpdates,
                    .enableFasterPropsUpdates = _config.enableFasterPropsUpdates,
                  }
    parentHasStateUpdate:NO];

  // c is not dirty, the components are equal, so we reuse the previous component.
  [self verifyComponentIsBeingReused:_c c2:c2 scopeRoot:_scopeRoot scopeRoot2:scopeRoot2];
}

- (void)test_fasterPropsUpdate_whenBothOptimizationsAreOn
{
  _enableFasterStateUpdates = YES;
  _enableFasterPropsUpdates = YES;

  // Props Updates
  [self test_fasterPropsUpdate_componentIsNotBeingReused_whenPropsAreNotEqual];
  [self test_fasterPropsUpdate_componentIsBeingReusedWhenPropsAreEqual];
  [self test_fasterPropsUpdate_componentIsBeingReused_onStateUpdateWithDirtyParentAndEqualComponents];
  [self test_fasterPropsUpdate_componentIsBeingReused_onStateUpdateWithNonDirtyComponentAndEqualComponents];
}

#pragma mark - parentHasStateUpdate

- (void)test_parentHasStateUpdatePropagatedCorrectly
{
  CKBuildComponentConfig config = {
    .enableFasterStateUpdates = YES,
    .enableFasterPropsUpdates = YES,
  };

  // Build new tree
  __block CKTestRenderComponent *c;
  __block CKCompositeComponentWithScopeAndState *rootComponent;

  auto const componentFactory = ^{
    c = [CKTestRenderComponent newWithIdentifier:1];
    rootComponent = generateComponentHierarchyWithComponent(c);
    return rootComponent;
  };

  auto const buildResults = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, componentFactory, config);
  XCTAssertFalse(c.childComponent.parentHasStateUpdate);

  // Simulate a state update on the root.
  CKComponentStateUpdateMap stateUpdates;
  stateUpdates[rootComponent.scopeHandle].push_back(^(id){
    return @2;
  });

  __block CKTestRenderComponent *c2;
  __block CKCompositeComponentWithScopeAndState *rootComponent2;

  auto const componentFactory2 = ^{
    // Use different identifier for c2 to make sure we don't reuse it (otherwise the buildComponentTree won't be called on the child component).
    c2 = [CKTestRenderComponent newWithIdentifier:2];
    rootComponent2 = generateComponentHierarchyWithComponent(c2);
    return rootComponent2;
  };

  CKBuildComponent(buildResults.scopeRoot, stateUpdates, componentFactory2, config);
  XCTAssertTrue(c2.childComponent.parentHasStateUpdate);
}

- (void)test_registerComponentsAndControllersInScopeRootAfterReuse
{
  CKBuildComponentConfig config = {
    .enableFasterStateUpdates = YES,
    .enableFasterPropsUpdates = YES,
  };

  // Build new tree with siblings `CKTestRenderComponent` components.
  __block CKTestRenderComponent *c1;
  __block CKTestRenderComponent *c2;
  auto const componentFactory = ^{
    c1 = [CKTestRenderComponent newWithIdentifier:1];
    c2 = [CKTestRenderComponent newWithIdentifier:2];
    return [CKTestRenderWithChildrenComponent newWithChildren:{c1, c2}];
  };

  // Build scope root with predicates.
  auto const scopeRoot = CKComponentScopeRootWithPredicates(nil, nil, {&CKComponentRenderTestsPredicate}, {&CKComponentControllerRenderTestsPredicate});
  auto const buildResults = CKBuildComponent(scopeRoot, {}, componentFactory, config);
  // Verify components and controllers registration in the scope root.
  [self verifyComponentsAndControllersAreRegisteredInScopeRoot:buildResults.scopeRoot components:{c1.childComponent, c2.childComponent}];

  // Simulate a state update on c2.
  CKComponentStateUpdateMap stateUpdates;
  stateUpdates[c2.scopeHandle].push_back(^(id){
    return @2;
  });

  auto const buildResults2 = CKBuildComponent(buildResults.scopeRoot, stateUpdates, componentFactory, config);
  // Verify c1 has been reused
  XCTAssertTrue(c1.didReuseComponent);
  // Verify components and controllers registration in the scope root.
  [self verifyComponentsAndControllersAreRegisteredInScopeRoot:buildResults2.scopeRoot components:{c1.childComponent, c2.childComponent}];
}

#pragma mark - Helpers

// Filters `CKTestChildRenderComponent` components.
static BOOL CKComponentRenderTestsPredicate(id<CKComponentProtocol> controller) {
  return [controller class] == [CKTestChildRenderComponent class];
}

// Filters `CKTestChildRenderComponentController` controllers.
static BOOL CKComponentControllerRenderTestsPredicate(id<CKComponentControllerProtocol> controller) {
  return [controller class] == [CKTestChildRenderComponentController class];
}

- (void)verifyComponentIsNotBeingReused:(CKTestRenderComponent *)c
                                     c2:(CKTestRenderComponent *)c2
                              scopeRoot:(CKComponentScopeRoot *)scopeRoot
                             scopeRoot2:(CKComponentScopeRoot *)scopeRoot2
{
  CKTreeNodeWithChild *childNode = (CKTreeNodeWithChild *)scopeRoot.rootNode.children[0];
  CKTreeNodeWithChild *childNode2 = (CKTreeNodeWithChild *)scopeRoot2.rootNode.children[0];
  XCTAssertEqual(c.renderCalledCounter, 1);
  XCTAssertEqual(c2.renderCalledCounter, 1);
  XCTAssertFalse(c2.didReuseComponent);
  XCTAssertNotEqual(c.childComponent, c2.childComponent);
  XCTAssertNotEqual(childNode.child, childNode2.child);
}

- (void)verifyComponentIsBeingReused:(CKTestRenderComponent *)c
                                  c2:(CKTestRenderComponent *)c2
                           scopeRoot:(CKComponentScopeRoot *)scopeRoot
                          scopeRoot2:(CKComponentScopeRoot *)scopeRoot2
{
  CKTreeNodeWithChild *childNode = (CKTreeNodeWithChild *)scopeRoot.rootNode.children[0];
  CKTreeNodeWithChild *childNode2 = (CKTreeNodeWithChild *)scopeRoot2.rootNode.children[0];
  XCTAssertEqual(c.renderCalledCounter, 1);
  XCTAssertEqual(c2.renderCalledCounter, 0);
  XCTAssertTrue(c2.didReuseComponent);
  XCTAssertEqual(c.childComponent, c2.childComponent);
  XCTAssertEqual(childNode.child, childNode2.child);
}

- (void)verifyComponentsAndControllersAreRegisteredInScopeRoot:(CKComponentScopeRoot *)scopeRoot
                                                    components:(std::vector<CKComponent *>)components
{
  auto const registeredComponents = [scopeRoot componentsMatchingPredicate:&CKComponentRenderTestsPredicate];
  auto const registeredControllers = [scopeRoot componentControllersMatchingPredicate:&CKComponentControllerRenderTestsPredicate];
  for (auto const &c: components) {
    XCTAssertTrue(CK::Collection::contains(registeredComponents, c));
    XCTAssertTrue(CK::Collection::contains(registeredControllers, c.scopeHandle.controller));
  }
}

static const CKBuildComponentTreeParams newTreeParams(CKComponentScopeRoot *scopeRoot, const CKBuildComponentConfig &config) {
  return {
    .scopeRoot = scopeRoot,
    .stateUpdates = {},
    .treeNodeDirtyIds = {},
    .buildTrigger = BuildTrigger::NewTree,
    .enableFasterStateUpdates = config.enableFasterStateUpdates,
    .enableFasterPropsUpdates = config.enableFasterPropsUpdates,
  };
}

static CKComponentScopeRoot *createNewTreeWithComponentAndReturnScopeRoot(const CKBuildComponentConfig &config, CKTestRenderComponent *c) {
  CKThreadLocalComponentScope threadScope(CKComponentScopeRootWithDefaultPredicates(nil, nil), {});
  const CKBuildComponentTreeParams params = newTreeParams(threadScope.newScopeRoot, config);
  [c buildComponentTree:threadScope.newScopeRoot.rootNode
         previousParent:nil
                 params:params
   parentHasStateUpdate:NO];
  return threadScope.newScopeRoot;
}

static CKCompositeComponentWithScopeAndState* generateComponentHierarchyWithComponent(CKComponent *c) {
  return
  [CKCompositeComponentWithScopeAndState
   newWithComponent:
   [CKFlexboxComponent
    newWithView:{}
    size:{}
    style:{}
    children:{
      { c }
    }]];
}

@end
