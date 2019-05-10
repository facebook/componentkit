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
#import <ComponentKit/CKFlexboxComponent.h>
#import <ComponentKit/CKThreadLocalComponentScope.h>
#import <ComponentKit/CKComponentScopeRootFactory.h>

#import <ComponentKitTestHelpers/CKRenderComponentTestHelpers.h>

#import "CKTreeNodeWithChild.h"
#import "CKTreeNodeWithChildren.h"

@interface CKRenderComponentTests : XCTestCase
@end

@implementation CKRenderComponentTests
{
  CKTestRenderComponent *_c;
  CKComponentScopeRoot *_scopeRoot;
}

- (void)setUpForFasterStateUpdates
{
  [self setUpForFasterStateUpdates:^{
    return [CKTestRenderComponent new];
  }];
}

- (void)setUpForFasterStateUpdates:(CKComponent *(^)(void))componentFactory
{
  // New Tree Creation.
  auto const buildResults = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, componentFactory);

  _c = (CKTestRenderComponent *)buildResults.component;
  _scopeRoot = buildResults.scopeRoot;
  XCTAssertEqual(_c.renderCalledCounter, 1);
}

- (void)setUpForFasterPropsUpdates:(CKComponent *(^)(void))componentFactory
{
  // New Tree Creation.
  auto const buildResults = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, componentFactory);
  _c = (CKTestRenderComponent *)buildResults.component;
  _scopeRoot = buildResults.scopeRoot;
  XCTAssertEqual(_c.renderCalledCounter, 1);
}

#pragma mark - State updates

- (void)test_fasterStateUpdate_componentIsBeingReused_onStateUpdateOnADifferentComponentBranch
{
  [self setUpForFasterStateUpdates];

  // Simulate a state update on a different component branch:
  // 1. treeNodeDirtyIds with fake components ids.
  // 2. parentHasStateUpdate = NO
  CKThreadLocalComponentScope threadScope(_scopeRoot, {});
  auto const c2 = [CKTestRenderComponent new];
  CKComponentScopeRoot *scopeRoot2 = threadScope.newScopeRoot;

  [c2 buildComponentTree:scopeRoot2.rootNode.node()
          previousParent:_scopeRoot.rootNode.node()
                  params:{
                    .scopeRoot = scopeRoot2,
                    .previousScopeRoot = _scopeRoot,
                    .stateUpdates = {},
                    .treeNodeDirtyIds = {100, 101}, // Use a random id that represents a fake state update on a different branch.
                    .buildTrigger = BuildTrigger::StateUpdate,
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

  auto const c2 = [CKTestRenderComponent newWithProps:{.identifier = 1}];
  [c2 buildComponentTree:scopeRoot2.rootNode.node()
          previousParent:_scopeRoot.rootNode.node()
                  params:{
                    .scopeRoot = scopeRoot2,
                    .previousScopeRoot = _scopeRoot,
                    .stateUpdates = {},
                    .treeNodeDirtyIds = {100}, // Use a random id that represents a state update on a fake parent.
                    .buildTrigger = BuildTrigger::StateUpdate,
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
  [c2 buildComponentTree:scopeRoot2.rootNode.node()
          previousParent:_scopeRoot.rootNode.node()
                  params:{
                    .scopeRoot = scopeRoot2,
                    .previousScopeRoot = _scopeRoot,
                    .stateUpdates = stateUpdates,
                    .treeNodeDirtyIds = {
                      _c.scopeHandle.treeNodeIdentifier
                    },
                    .buildTrigger = BuildTrigger::StateUpdate,
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

  [c2 buildComponentTree:scopeRoot2.rootNode.node()
          previousParent:_scopeRoot.rootNode.node()
                  params:{
                    .scopeRoot = scopeRoot2,
                    .previousScopeRoot = _scopeRoot,
                    .stateUpdates = stateUpdates,
                    .treeNodeDirtyIds = {
                      _c.scopeHandle.treeNodeIdentifier
                    },
                    .buildTrigger = BuildTrigger::StateUpdate,
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
  [self setUpForFasterPropsUpdates:^(){
    return [CKTestRenderComponent newWithProps:{.identifier = 1}];
  }];

  // Simulate props update.
  CKThreadLocalComponentScope threadScope(_scopeRoot, {});
  auto const c2 = [CKTestRenderComponent newWithProps:{.identifier = 2}];
  CKComponentScopeRoot *scopeRoot2 = threadScope.newScopeRoot;

  [c2 buildComponentTree:scopeRoot2.rootNode.node()
          previousParent:_scopeRoot.rootNode.node()
                  params:{
                    .scopeRoot = scopeRoot2,
                    .previousScopeRoot = _scopeRoot,
                    .stateUpdates = {},
                    .treeNodeDirtyIds = {},
                    .buildTrigger = BuildTrigger::PropsUpdate,
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
  [self setUpForFasterPropsUpdates:^{
    return [CKTestRenderComponent newWithProps:{.identifier = componentIdentifier}];
  }];

  // Simulate props update.
  CKThreadLocalComponentScope threadScope(_scopeRoot, {});
  auto const c2 = [CKTestRenderComponent newWithProps:{.identifier = componentIdentifier}];
  CKComponentScopeRoot *scopeRoot2 = threadScope.newScopeRoot;

  [c2 buildComponentTree:scopeRoot2.rootNode.node()
          previousParent:_scopeRoot.rootNode.node()
                  params:{
                    .scopeRoot = scopeRoot2,
                    .previousScopeRoot = _scopeRoot,
                    .stateUpdates = {},
                    .treeNodeDirtyIds = {},
                    .buildTrigger = BuildTrigger::PropsUpdate,
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
  [self setUpForFasterPropsUpdates:^{
    return [CKTestRenderComponent newWithProps:{.identifier = componentIdentifier}];
  }];

  // Simulate a state update on a parent component:
  // 1. parentHasStateUpdate = YES
  // 2. treeNodeDirtyIds with a fake parent id.
  CKThreadLocalComponentScope threadScope(_scopeRoot, {});
  auto const c2 = [CKTestRenderComponent newWithProps:{.identifier = componentIdentifier}];
  CKComponentScopeRoot *scopeRoot2 = threadScope.newScopeRoot;

  [c2 buildComponentTree:scopeRoot2.rootNode.node()
          previousParent:_scopeRoot.rootNode.node()
                  params:{
                    .scopeRoot = scopeRoot2,
                    .previousScopeRoot = _scopeRoot,
                    .stateUpdates = {},
                    .treeNodeDirtyIds = {100}, // Use a random id that represents a state update on a fake parent.
                    .buildTrigger = BuildTrigger::StateUpdate,
                  }
    parentHasStateUpdate:YES];

  // c has dirty parent, however, the components are equal, so we reuse the previous component.
  [self verifyComponentIsBeingReused:_c c2:c2 scopeRoot:_scopeRoot scopeRoot2:scopeRoot2];
}

- (void)test_fasterPropsUpdate_componentIsBeingReused_onStateUpdateWithNonDirtyComponentAndEqualComponents
{
  auto const componentIdentifier = 1;
  [self setUpForFasterPropsUpdates:^{
    return [CKTestRenderComponent newWithProps:{.identifier = componentIdentifier}];
  }];

  // Simulate a state update on a parent component:
  // 1. parentHasStateUpdate = NO
  // 2. treeNodeDirtyIds is empty.
  CKThreadLocalComponentScope threadScope(_scopeRoot, {});
  auto const c2 = [CKTestRenderComponent newWithProps:{.identifier = componentIdentifier}];
  CKComponentScopeRoot *scopeRoot2 = threadScope.newScopeRoot;

  [c2 buildComponentTree:scopeRoot2.rootNode.node()
          previousParent:_scopeRoot.rootNode.node()
                  params:{
                    .scopeRoot = scopeRoot2,
                    .previousScopeRoot = _scopeRoot,
                    .stateUpdates = {},
                    .treeNodeDirtyIds = {},
                    .buildTrigger = BuildTrigger::StateUpdate,
                  }
    parentHasStateUpdate:NO];

  // c is not dirty, the components are equal, so we reuse the previous component.
  [self verifyComponentIsBeingReused:_c c2:c2 scopeRoot:_scopeRoot scopeRoot2:scopeRoot2];
}

- (void)test_fasterPropsUpdate_componentIsNotBeingReusedWhenPropsAreEqualButNodeIdIsDirty
{
  // Use the same componentIdentifier for both components.
  // shouldComponentUpdate: will return NO in this case.
  // However, we simulate a case when the node id is dirty, hence cannot be reused.
  NSUInteger componentIdentifier = 1;
  [self setUpForFasterPropsUpdates:^{
    return [CKTestRenderComponent newWithProps:{
      .identifier = componentIdentifier,
      .shouldUseComponentContext = YES,
    }];
  }];

  // Simulate props update.
  __block CKTestRenderComponent *c2;
  auto const componentFactory = ^{
    c2 = [CKTestRenderComponent newWithProps:{
      .identifier = componentIdentifier,
      .shouldUseComponentContext = YES,
    }];
    return c2;
  };

  auto const buildResults = CKBuildComponent(_scopeRoot, {}, componentFactory);

  // The components are equal, but the node id is dirty - hence, we cannot reuse the previous component.
  [self verifyComponentIsNotBeingReused:_c c2:c2 scopeRoot:_scopeRoot scopeRoot2:buildResults.scopeRoot];

}

#pragma mark - parentHasStateUpdate

- (void)test_parentHasStateUpdatePropagatedCorrectly
{
  // Build new tree
  __block CKTestRenderComponent *c;
  __block CKCompositeComponentWithScopeAndState *rootComponent;

  auto const componentFactory = ^{
    c = [CKTestRenderComponent newWithProps:{.identifier = 1}];
    rootComponent = generateComponentHierarchyWithComponent(c);
    return rootComponent;
  };

  auto const buildResults = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, componentFactory);
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
    c2 = [CKTestRenderComponent newWithProps:{.identifier = 2}];
    rootComponent2 = generateComponentHierarchyWithComponent(c2);
    return rootComponent2;
  };

  CKBuildComponent(buildResults.scopeRoot, stateUpdates, componentFactory2);
  XCTAssertTrue(c2.childComponent.parentHasStateUpdate);
}

- (void)test_registerComponentsAndControllersInScopeRootAfterReuse
{
  // Build new tree with siblings `CKTestRenderComponent` components.
  __block CKTestRenderComponent *c1;
  __block CKTestRenderComponent *c2;
  auto const componentFactory = ^{
    c1 = [CKTestRenderComponent newWithProps:{.identifier = 1}];
    c2 = [CKTestRenderComponent newWithProps:{.identifier = 2}];
    return [CKTestRenderWithChildrenComponent newWithChildren:{c1, c2}];
  };

  // Build scope root with predicates.
  auto const scopeRoot = CKComponentScopeRootWithPredicates(nil, nil, {&CKComponentRenderTestsPredicate}, {&CKComponentControllerRenderTestsPredicate});
  auto const buildResults = CKBuildComponent(scopeRoot, {}, componentFactory);
  // Verify components and controllers registration in the scope root.
  [self verifyComponentsAndControllersAreRegisteredInScopeRoot:buildResults.scopeRoot components:{c1.childComponent, c2.childComponent}];

  // Simulate a state update on c2.
  CKComponentStateUpdateMap stateUpdates;
  stateUpdates[c2.scopeHandle].push_back(^(id){
    return @2;
  });

  auto const buildResults2 = CKBuildComponent(buildResults.scopeRoot, stateUpdates, componentFactory);
  // Verify c1 has been reused
  XCTAssertTrue(c1.didReuseComponent);
  // Verify components and controllers registration in the scope root.
  [self verifyComponentsAndControllersAreRegisteredInScopeRoot:buildResults2.scopeRoot components:{c1.childComponent, c2.childComponent}];
}

- (void)test_componentIsNotBeingReusedOnAStateUpdate_WhenIgnoreComponentReuseOptimizationsIsOn
{
  // Build new tree with siblings `CKTestRenderComponent` components.
  __block CKTestRenderComponent *c1;
  __block CKTestRenderComponent *c2;
  auto const componentFactory = ^{
    c1 = [CKTestRenderComponent newWithProps:{.identifier = 1}];
    c2 = [CKTestRenderComponent newWithProps:{.identifier = 2}];
    return [CKTestRenderWithChildrenComponent newWithChildren:{c1, c2}];
  };

  // Build scope root with predicates.
  auto const scopeRoot = CKComponentScopeRootWithPredicates(nil, nil, {}, {});
  auto const buildResults = CKBuildComponent(scopeRoot, {}, componentFactory);

  // Simulate a state update on c2.
  CKComponentStateUpdateMap stateUpdates;
  stateUpdates[c2.scopeHandle].push_back(^(id){
    return @2;
  });

  auto ignoreComponentReuseOptimizationsIsOn = YES;
  auto const buildResults2 = CKBuildComponent(buildResults.scopeRoot, stateUpdates, componentFactory, ignoreComponentReuseOptimizationsIsOn);
  // Verify no component have been reused.
  XCTAssertFalse(c1.didReuseComponent);
  XCTAssertFalse(c2.didReuseComponent);
}

- (void)test_componentIsNotBeingReusedOnAPropsUpdate_WhenIgnoreComponentReuseOptimizationsIsOn
{
  // Build new tree with siblings `CKTestRenderComponent` components.
  __block CKTestRenderComponent *c1;
  __block CKTestRenderComponent *c2;
  auto const componentFactory = ^{
    c1 = [CKTestRenderComponent newWithProps:{.identifier = 1}];
    c2 = [CKTestRenderComponent newWithProps:{.identifier = 2}];
    return [CKTestRenderWithChildrenComponent newWithChildren:{c1, c2}];
  };

  // Build scope root with predicates.
  auto const scopeRoot = CKComponentScopeRootWithPredicates(nil, nil, {}, {});
  auto const buildResults = CKBuildComponent(scopeRoot, {}, componentFactory);

  auto ignoreComponentReuseOptimizationsIsOn = YES;
  auto const buildResults2 = CKBuildComponent(buildResults.scopeRoot, {}, componentFactory, ignoreComponentReuseOptimizationsIsOn);
  // Verify no component have been reused.
  XCTAssertFalse(c1.didReuseComponent);
  XCTAssertFalse(c2.didReuseComponent);
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
  CKTreeNodeWithChild *childNode = (CKTreeNodeWithChild *)scopeRoot.rootNode.node().children[0];
  CKTreeNodeWithChild *childNode2 = (CKTreeNodeWithChild *)scopeRoot2.rootNode.node().children[0];
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
  CKTreeNodeWithChild *childNode = (CKTreeNodeWithChild *)scopeRoot.rootNode.node().children[0];
  CKTreeNodeWithChild *childNode2 = (CKTreeNodeWithChild *)scopeRoot2.rootNode.node().children[0];
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
