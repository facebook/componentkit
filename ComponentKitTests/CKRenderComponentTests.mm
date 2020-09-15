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
#import <ComponentKit/CKTreeNodeProtocol.h>
#import <ComponentKit/CKComponentScopeRootFactory.h>
#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKRenderHelpers.h>

#import <ComponentKitTestHelpers/CKRenderComponentTestHelpers.h>

#import "CKComponentTestCase.h"

@interface CKRenderComponentTests : CKComponentTestCase
@end

@interface CKRenderComponentAndScopeTreeTests : CKComponentTestCase
@end

@implementation CKRenderComponentTests
{
  CKTestRenderComponent *_c;
  CKComponentScopeRoot *_scopeRoot;
  @package
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
  auto const scopeRoot = CKComponentScopeRootWithDefaultPredicates(nil, nil);
  auto const buildTrigger = CKBuildComponentTrigger(scopeRoot, {}, NO, NO);
  auto const buildResults = CKBuildComponent(scopeRoot, {}, componentFactory, buildTrigger, CKReflowTriggerNone);

  _c = (CKTestRenderComponent *)buildResults.component;
  _scopeRoot = buildResults.scopeRoot;
  XCTAssertEqual(_c.renderCalledCounter, 1);
}

- (void)setUpForFasterPropsUpdates:(CKComponent *(^)(void))componentFactory
{
  // New Tree Creation.
  auto const scopeRoot = CKComponentScopeRootWithDefaultPredicates(nil, nil);
  auto const buildTrigger = CKBuildComponentTrigger(scopeRoot, {}, NO, NO);
  auto const buildResults = CKBuildComponent(scopeRoot, {}, componentFactory, buildTrigger, CKReflowTriggerNone);
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

  CKRender::ComponentTree::Root::build(c2, {
    .scopeRoot = scopeRoot2,
    .previousScopeRoot = _scopeRoot,
    .stateUpdates = {},
    .treeNodeDirtyIds = {100, 101}, // Use a random id that represents a fake state update on a different branch.
    .buildTrigger = CKBuildTriggerStateUpdate,
  });

  // As the state update doesn't affect the c2, we should reuse c instead.
  [self verifyComponentIsBeingReused:_c c2:c2 scopeRoot:_scopeRoot scopeRoot2:scopeRoot2];
}

- (void)test_fasterStateUpdate_componentIsNotBeingReused_onStateUpdateOnAParent
{
  __block CKCompositeComponentWithScopeAndState *root;
  __block CKTestRenderComponent *c;
  auto const componentFactory = ^{
    c = [CKTestRenderComponent newWithProps:{.identifier = 1}];
    root = [CKCompositeComponentWithScopeAndState newWithComponent:c];
    return root;
  };
  auto const scopeRoot = CKComponentScopeRootWithDefaultPredicates(nil, nil);
  auto const buildTrigger = CKBuildComponentTrigger(scopeRoot, {}, NO, NO);
  auto const buildResults = CKBuildComponent(scopeRoot, {}, componentFactory, buildTrigger, CKReflowTriggerNone);

  // Simulate a state update on a parent component:
  // 1. parentHasStateUpdate = YES
  // 2. treeNodeDirtyIds with a fake parent id.
  CKComponentStateUpdateMap stateUpdates;
  stateUpdates[root.scopeHandle].push_back(^(id){
    return @2;
  });

  __block CKCompositeComponentWithScopeAndState *root2;
  __block CKTestRenderComponent *c2;
  auto const componentFactory2 = ^{
    c2 = [CKTestRenderComponent newWithProps:{.identifier = 2}];
    root2 = [CKCompositeComponentWithScopeAndState newWithComponent:c2];
    return root2;
  };

  auto const buildTrigger2 = CKBuildComponentTrigger(buildResults.scopeRoot, stateUpdates, NO, NO);
  auto const buildResults2 = CKBuildComponent(buildResults.scopeRoot, stateUpdates, componentFactory2, buildTrigger2, CKReflowTriggerNone);

  // c has dirty parent, however, the components are equal, so we reuse the previous component.
  XCTAssertEqual(c.renderCalledCounter, 1);
  XCTAssertEqual(c2.renderCalledCounter, 1);
  XCTAssertFalse(c2.didReuseComponent);
  XCTAssertNotEqual(c.childComponent, c2.childComponent);
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
  CKRender::ComponentTree::Root::build(c2, {
    .scopeRoot = scopeRoot2,
    .previousScopeRoot = _scopeRoot,
    .stateUpdates = stateUpdates,
    .treeNodeDirtyIds = {
      _c.scopeHandle.treeNodeIdentifier
    },
    .buildTrigger = CKBuildTriggerStateUpdate,
  });

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

  CKRender::ComponentTree::Root::build(c2, {
    .scopeRoot = scopeRoot2,
    .previousScopeRoot = _scopeRoot,
    .stateUpdates = stateUpdates,
    .treeNodeDirtyIds = {
      _c.scopeHandle.treeNodeIdentifier
    },
    .buildTrigger = CKBuildTriggerStateUpdate,
  });

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

  CKRender::ComponentTree::Root::build(c2, {
    .scopeRoot = scopeRoot2,
    .previousScopeRoot = _scopeRoot,
    .stateUpdates = {},
    .treeNodeDirtyIds = {},
    .buildTrigger = CKBuildTriggerPropsUpdate,
  });

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

  CKRender::ComponentTree::Root::build(c2, {
    .scopeRoot = scopeRoot2,
    .previousScopeRoot = _scopeRoot,
    .stateUpdates = {},
    .treeNodeDirtyIds = {},
    .buildTrigger = CKBuildTriggerPropsUpdate,
  });

  // The components are equal, we can reuse the previous component.
  [self verifyComponentIsBeingReused:_c c2:c2 scopeRoot:_scopeRoot scopeRoot2:scopeRoot2];
  // Make sure the dirtyParent is pssed correctly to the child component.
  XCTAssertFalse(c2.childComponent.parentHasStateUpdate);
}

- (void)test_fasterPropsUpdate_componentIsBeingReused_onStateUpdateWithDirtyParentAndEqualComponents
{
  __block CKCompositeComponentWithScopeAndState *root;
  __block CKTestRenderComponent *c;
  auto const componentIdentifier = 1;
  auto const componentFactory = ^{
    c = [CKTestRenderComponent newWithProps:{.identifier = componentIdentifier}];
    root = [CKCompositeComponentWithScopeAndState newWithComponent:c];
    return root;
  };
  auto const scopeRoot = CKComponentScopeRootWithDefaultPredicates(nil, nil);
  auto const buildTrigger = CKBuildComponentTrigger(scopeRoot, {}, NO, NO);
  auto const buildResults = CKBuildComponent(scopeRoot, {}, componentFactory, buildTrigger, CKReflowTriggerNone);

  // Simulate a state update on a parent component:
  // 1. parentHasStateUpdate = YES
  // 2. treeNodeDirtyIds with a fake parent id.
  CKComponentStateUpdateMap stateUpdates;
  stateUpdates[root.scopeHandle].push_back(^(id){
    return @2;
  });

  __block CKCompositeComponentWithScopeAndState *root2;
  __block CKTestRenderComponent *c2;
  auto const componentFactory2 = ^{
    c2 = [CKTestRenderComponent newWithProps:{.identifier = componentIdentifier}];
    root2 = [CKCompositeComponentWithScopeAndState newWithComponent:c2];
    return root2;
  };

  auto const buildTrigger2 = CKBuildComponentTrigger(buildResults.scopeRoot, stateUpdates, NO, NO);
  auto const buildResults2 = CKBuildComponent(buildResults.scopeRoot, stateUpdates, componentFactory2, buildTrigger2, CKReflowTriggerNone);

  // c has dirty parent, however, the components are equal, so we reuse the previous component.
  XCTAssertEqual(c.renderCalledCounter, 1);
  XCTAssertEqual(c2.renderCalledCounter, 0);
  XCTAssertTrue(c2.didReuseComponent);
  XCTAssertEqual(c.childComponent, c2.childComponent);
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

  CKRender::ComponentTree::Root::build(c2, {
    .scopeRoot = scopeRoot2,
    .previousScopeRoot = _scopeRoot,
    .stateUpdates = {},
    .treeNodeDirtyIds = {},
    .buildTrigger = CKBuildTriggerStateUpdate,
  });

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
  auto const scopeRoot = CK::makeNonNull(_scopeRoot);
  auto const buildTrigger = CKBuildComponentTrigger(scopeRoot, {}, NO, NO);
  auto const buildResults = CKBuildComponent(scopeRoot, {}, componentFactory, buildTrigger, CKReflowTriggerNone);

  // The components are equal, but the node id is dirty - hence, we cannot reuse the previous component.
  [self verifyComponentIsNotBeingReused:_c c2:c2 scopeRoot:_scopeRoot scopeRoot2:buildResults.scopeRoot];

}

#pragma mark - Props and State Update

- (void)test_fasterStateUpdate_componentIsNotBeingReused_onPropsAndStateUpdate
{
  __block CKCompositeComponentWithScopeAndState *root;
  __block CKTestRenderComponent *c;
  auto const componentIdentifier = 1;
  auto const componentFactory = ^{
    c = [CKTestRenderComponent newWithProps:{.identifier = componentIdentifier}];
    root = [CKCompositeComponentWithScopeAndState newWithComponent:c];
    return root;
  };
  auto const scopeRoot = CKComponentScopeRootWithDefaultPredicates(nil, nil);
  auto const buildTrigger = CKBuildComponentTrigger(scopeRoot, {}, NO, NO);
  auto const buildResults = CKBuildComponent(scopeRoot, {}, componentFactory, buildTrigger, CKReflowTriggerNone);

  // Simulate props and a state update on a component
  // 1. parentHasStateUpdate = YES
  // 2. treeNodeDirtyIds with a fake parent id.
  // 3. forcePropsUpdates = YES
  // 4. Props (componentIdentifier) are equal = reuse
  CKComponentStateUpdateMap stateUpdates;
  stateUpdates[root.scopeHandle].push_back(^(id){
    return @2;
  });

  __block CKCompositeComponentWithScopeAndState *root2;
  __block CKTestRenderComponent *c2;
  auto const componentFactory2 = ^{
    c2 = [CKTestRenderComponent newWithProps:{.identifier = componentIdentifier}];
    root2 = [CKCompositeComponentWithScopeAndState newWithComponent:c2];
    return root2;
  };

  auto const forcePropsUpdates = YES;

  auto const buildTrigger2 = CKBuildComponentTrigger(buildResults.scopeRoot, stateUpdates, NO, forcePropsUpdates);
  auto const buildResults2 = CKBuildComponent(buildResults.scopeRoot, stateUpdates, componentFactory2, buildTrigger2, CKReflowTriggerNone);

  // forcePropsUpdates + state update should end up with PropsAndStateUpdate trigger - which behaves the same as PropsUpdates
  XCTAssertEqual(c.renderCalledCounter, 1);
  XCTAssertEqual(c2.renderCalledCounter, 0);
  XCTAssertFalse(c.didReuseComponent);
  XCTAssertTrue(c2.didReuseComponent);
  XCTAssertEqual(c.childComponent, c2.childComponent);
}

- (void)test_fasterStateUpdate_componentIsBeingReused_onPropsAndStateUpdate
{
  __block CKCompositeComponentWithScopeAndState *root;
  __block CKTestRenderComponent *c;
  auto const componentIdentifier = 1;
  auto const componentFactory = ^{
    c = [CKTestRenderComponent newWithProps:{.identifier = componentIdentifier}];
    root = [CKCompositeComponentWithScopeAndState newWithComponent:c];
    return root;
  };
  auto const scopeRoot = CKComponentScopeRootWithDefaultPredicates(nil, nil);
  auto const buildTrigger = CKBuildComponentTrigger(scopeRoot, {}, NO, NO);
  auto const buildResults = CKBuildComponent(scopeRoot, {}, componentFactory, buildTrigger, CKReflowTriggerNone);

  // Simulate props and a state update on a component
  // 1. parentHasStateUpdate = YES
  // 2. treeNodeDirtyIds with a fake parent id.
  // 3. forcePropsUpdates = YES
  // 4. Props (componentIdentifier) are different = no reuse
  CKComponentStateUpdateMap stateUpdates;
  stateUpdates[root.scopeHandle].push_back(^(id){
    return @2;
  });

  __block CKCompositeComponentWithScopeAndState *root2;
  __block CKTestRenderComponent *c2;
  // Simulate props update
  auto const componentIdentifier2 = 2;
  auto const componentFactory2 = ^{
    c2 = [CKTestRenderComponent newWithProps:{.identifier = componentIdentifier2}];
    root2 = [CKCompositeComponentWithScopeAndState newWithComponent:c2];
    return root2;
  };

  auto const forcePropsUpdates = YES;

  auto const buildTrigger2 = CKBuildComponentTrigger(buildResults.scopeRoot, stateUpdates, NO, forcePropsUpdates);
  auto const buildResults2 = CKBuildComponent(buildResults.scopeRoot, stateUpdates, componentFactory2, buildTrigger2, CKReflowTriggerNone);

  // forcePropsUpdates + state update should end up with PropsAndStateUpdate trigger - which behaves the same as PropsUpdates
  XCTAssertEqual(c.renderCalledCounter, 1);
  XCTAssertEqual(c2.renderCalledCounter, 1);
  XCTAssertFalse(c.didReuseComponent);
  XCTAssertFalse(c2.didReuseComponent);
  XCTAssertNotEqual(c.childComponent, c2.childComponent);
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

  auto const scopeRoot = CKComponentScopeRootWithDefaultPredicates(nil, nil);
  auto const buildTrigger = CKBuildComponentTrigger(scopeRoot, {}, NO, NO);
  auto const buildResults = CKBuildComponent(scopeRoot, {}, componentFactory, buildTrigger, CKReflowTriggerNone);
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

  auto const buildTrigger2 = CKBuildComponentTrigger(buildResults.scopeRoot, stateUpdates, NO, NO);
  CKBuildComponent(buildResults.scopeRoot, stateUpdates, componentFactory2, buildTrigger2, CKReflowTriggerNone);
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
    return [CKTestLayoutComponent newWithChildren:{c1, c2}];
  };

  // Build scope root with predicates.
  auto const scopeRoot = CKComponentScopeRootWithPredicates(nil, nil,
                                                            {&CKComponentRenderTestsPredicate},
                                                            {&CKComponentControllerRenderTestsPredicate});
  auto const buildTrigger = CKBuildComponentTrigger(scopeRoot, {}, NO, NO);
  auto const buildResults = CKBuildComponent(scopeRoot, {}, componentFactory, buildTrigger, CKReflowTriggerNone);
  // Verify components and controllers registration in the scope root.
  [self verifyComponentsAndControllersAreRegisteredInScopeRoot:buildResults.scopeRoot
                                                    components:{c1.childComponent, c2.childComponent}
                                            componentPredicate:&CKComponentRenderTestsPredicate
                                  componentControllerPredicate:&CKComponentControllerRenderTestsPredicate];

  // Simulate a state update on c2.
  CKComponentStateUpdateMap stateUpdates;
  stateUpdates[c2.scopeHandle].push_back(^(id){
    return @2;
  });

  auto const buildTrigger2 = CKBuildComponentTrigger(buildResults.scopeRoot, stateUpdates, NO, NO);
  auto const buildResults2 = CKBuildComponent(buildResults.scopeRoot, stateUpdates, componentFactory, buildTrigger2, CKReflowTriggerNone);
  // Verify c1 has been reused
  XCTAssertTrue(c1.didReuseComponent);
  // Verify components and controllers registration in the scope root.
  [self verifyComponentsAndControllersAreRegisteredInScopeRoot:buildResults2.scopeRoot
                                                    components:{c1.childComponent,c2.childComponent}
                                            componentPredicate:&CKComponentRenderTestsPredicate
                                  componentControllerPredicate:&CKComponentControllerRenderTestsPredicate];
}

- (void)test_registerComponentsAndControllersInScopeRootAfterReuseWithNonRenderComponents
{
  // Build new tree with siblings `CKTestRenderComponent` components.
  __block CKTestRenderComponent *c1;
  __block CKTestRenderComponent *c2;
  auto const componentFactory = ^{
    c1 = [CKTestRenderComponent newWithProps:{.identifier = 1}];
    c2 = [CKTestRenderComponent newWithProps:{.identifier = 2, .shouldUseNonRenderChild = YES}];
    return [CKTestLayoutComponent newWithChildren:{c1, c2}];
  };

  // Build scope root with predicates.
  auto const scopeRoot = CKComponentScopeRootWithPredicates(nil, nil,
  {&CKAllNonNilComponentsTestsPredicate},
  {&CKAllNonNilComponentsControllersTestsPredicate});

  auto const buildTrigger = CKBuildComponentTrigger(scopeRoot, {}, NO, NO);
  auto const buildResults = CKBuildComponent(scopeRoot, {}, componentFactory, buildTrigger, CKReflowTriggerNone);
  // Verify components and controllers registration in the scope root.
  [self verifyComponentsAndControllersAreRegisteredInScopeRoot:buildResults.scopeRoot
                                                    components:{
    c1, c1.childComponent,
    c2, c2.nonRenderChildComponent, c2.nonRenderChildComponent.childComponent,
  }
                                            componentPredicate:&CKAllNonNilComponentsTestsPredicate
                                  componentControllerPredicate:&CKAllNonNilComponentsControllersTestsPredicate];

  // Simulate a state update on c1.
  CKComponentStateUpdateMap stateUpdates;
  stateUpdates[c1.scopeHandle].push_back(^(id){
    return @2;
  });

  auto const buildTrigger2 = CKBuildComponentTrigger(buildResults.scopeRoot, stateUpdates, NO, NO);
  auto const buildResults2 = CKBuildComponent(buildResults.scopeRoot, stateUpdates, componentFactory, buildTrigger2, CKReflowTriggerNone);
  // Verify c1 has been reused
  XCTAssertTrue(c2.didReuseComponent);

  // Verify components and controllers registration in the scope root.
  [self verifyComponentsAndControllersAreRegisteredInScopeRoot:buildResults2.scopeRoot
                                                    components:{
    c1, c1.childComponent,
    c2, c2.nonRenderChildComponent, c2.nonRenderChildComponent.childComponent,
  }
                                            componentPredicate:&CKAllNonNilComponentsTestsPredicate
                                  componentControllerPredicate:&CKAllNonNilComponentsControllersTestsPredicate];
}

- (void)test_componentIsNotBeingReusedOnAStateUpdate_WhenEnableComponentReuseOptimizationsIsOff
{
  // Build new tree with siblings `CKTestRenderComponent` components.
  __block CKTestRenderComponent *c1;
  __block CKTestRenderComponent *c2;
  auto const componentFactory = ^{
    c1 = [CKTestRenderComponent newWithProps:{.identifier = 1}];
    c2 = [CKTestRenderComponent newWithProps:{.identifier = 2}];
    return [CKTestLayoutComponent newWithChildren:{c1, c2}];
  };

  // Build scope root with predicates.
  auto const scopeRoot = CKComponentScopeRootWithPredicates(nil, nil, {}, {});
  auto const buildTrigger = CKBuildComponentTrigger(scopeRoot, {}, NO, NO);
  auto const buildResults = CKBuildComponent(scopeRoot, {}, componentFactory, buildTrigger, CKReflowTriggerNone);

  // Simulate a state update on c2.
  CKComponentStateUpdateMap stateUpdates;
  stateUpdates[c2.scopeHandle].push_back(^(id){
    return @2;
  });

  auto ignoreComponentReuseOptimizations = YES;
  auto const buildTrigger2 = CKBuildComponentTrigger(buildResults.scopeRoot, stateUpdates, ignoreComponentReuseOptimizations, NO);
  auto const reflowTrigger2 = !ignoreComponentReuseOptimizations ? CKReflowTriggerNone : CKReflowTriggerReload;
  auto const buildResults2 = CKBuildComponent(buildResults.scopeRoot, stateUpdates, componentFactory, buildTrigger2, reflowTrigger2);
  // Verify no component have been reused.
  XCTAssertFalse(c1.didReuseComponent);
  XCTAssertFalse(c2.didReuseComponent);
}

- (void)test_componentIsNotBeingReusedOnAPropsUpdate_WhenEnableComponentReuseOptimizationsIsOff
{
  // Build new tree with siblings `CKTestRenderComponent` components.
  __block CKTestRenderComponent *c1;
  __block CKTestRenderComponent *c2;
  auto const componentFactory = ^{
    c1 = [CKTestRenderComponent newWithProps:{.identifier = 1}];
    c2 = [CKTestRenderComponent newWithProps:{.identifier = 2}];
    return [CKTestLayoutComponent newWithChildren:{c1, c2}];
  };

  // Build scope root with predicates.
  auto const scopeRoot = CKComponentScopeRootWithPredicates(nil, nil, {}, {});
  auto const buildTrigger = CKBuildComponentTrigger(scopeRoot, {}, NO, NO);
  auto const buildResults = CKBuildComponent(scopeRoot, {}, componentFactory, buildTrigger, CKReflowTriggerNone);

  auto ignoreComponentReuseOptimizations = YES;
  auto const buildTrigger2 = CKBuildComponentTrigger(buildResults.scopeRoot, {}, ignoreComponentReuseOptimizations, NO);
  auto const reflowTrigger2 = !ignoreComponentReuseOptimizations ? CKReflowTriggerNone : CKReflowTriggerReload;
  auto const buildResults2 = CKBuildComponent(buildResults.scopeRoot, {}, componentFactory, buildTrigger2, reflowTrigger2);
  // Verify no component have been reused.
  XCTAssertFalse(c1.didReuseComponent);
  XCTAssertFalse(c2.didReuseComponent);
}

#pragma mark - Helpers

// Filters `CKTestChildRenderComponent` components.
static BOOL CKComponentRenderTestsPredicate(id<CKComponentProtocol> component) {
  return [component class] == [CKTestChildRenderComponent class];
}

// Filters `CKTestChildRenderComponentController` controllers.
static BOOL CKComponentControllerRenderTestsPredicate(id<CKComponentControllerProtocol> controller) {
  return [controller class] == [CKTestChildRenderComponentController class];
}

// Filters all non-nil components.
static BOOL CKAllNonNilComponentsTestsPredicate(id<CKComponentProtocol> component) {
  return component != nil;
}

// Filters all non-nil controllers.
static BOOL CKAllNonNilComponentsControllersTestsPredicate(id<CKComponentControllerProtocol> controller) {
  return controller != nil;
}

- (void)verifyComponentIsNotBeingReused:(CKTestRenderComponent *)c
                                     c2:(CKTestRenderComponent *)c2
                              scopeRoot:(CKComponentScopeRoot *)scopeRoot
                             scopeRoot2:(CKComponentScopeRoot *)scopeRoot2
{
  XCTAssertEqual(c.renderCalledCounter, 1);
  XCTAssertEqual(c2.renderCalledCounter, 1);
  XCTAssertFalse(c2.didReuseComponent);
  XCTAssertNotEqual(c.childComponent, c2.childComponent);
}

- (void)verifyComponentIsBeingReused:(CKTestRenderComponent *)c
                                  c2:(CKTestRenderComponent *)c2
                           scopeRoot:(CKComponentScopeRoot *)scopeRoot
                          scopeRoot2:(CKComponentScopeRoot *)scopeRoot2
{
  XCTAssertEqual(c.renderCalledCounter, 1);
  XCTAssertEqual(c2.renderCalledCounter, 0);
  XCTAssertTrue(c2.didReuseComponent);
  XCTAssertEqual(c.childComponent, c2.childComponent);
}

- (void)verifyComponentsAndControllersAreRegisteredInScopeRoot:(CKComponentScopeRoot *)scopeRoot
                                                    components:(std::vector<CKComponent *>)components
                                            componentPredicate:(CKComponentPredicate)componentPredicate
                                  componentControllerPredicate:(CKComponentControllerPredicate)componentControllerPredicate
{
  auto const registeredComponents = [scopeRoot componentsMatchingPredicate:componentPredicate];
  auto const registeredControllers = [scopeRoot componentControllersMatchingPredicate:componentControllerPredicate];
  for (auto const &c: components) {
    XCTAssertNotNil(c, @"component shoudn't be nil here");
    XCTAssertTrue(CK::Collection::contains(registeredComponents, c));
    if (c.controller) {
      XCTAssertTrue(CK::Collection::contains(registeredControllers, c.controller));
    }
  }
}

static CKCompositeComponentWithScopeAndState* generateComponentHierarchyWithComponent(CKComponent *c) {
  return
  [CKCompositeComponentWithScopeAndState
   newWithComponent:
   CK::FlexboxComponentBuilder()
       .child(c)
       .build()];
}

@end

@implementation CKRenderComponentAndScopeTreeTests

- (void)test_scopeFramePreserveStateDuringComponentReuse
{
  // Build new tree with siblings `CKTestRenderWithNonRenderWithStateChildComponent` components.
  // Each `CKTestRenderWithNonRenderWithStateChildComponent` has non-render component with state.
  __block CKTestRenderWithNonRenderWithStateChildComponent *c1;
  __block CKTestRenderWithNonRenderWithStateChildComponent *c2;
  auto const componentFactory = ^{
    c1 = [CKTestRenderWithNonRenderWithStateChildComponent new];
    c2 = [CKTestRenderWithNonRenderWithStateChildComponent new];
    return [CKTestLayoutComponent newWithChildren:{c1, c2}];
  };

  // Build first component generation:
  auto const scopeRoot = CKComponentScopeRootWithPredicates(nil, nil, {}, {});
  auto const buildTrigger = CKBuildComponentTrigger(scopeRoot, {}, NO, NO);
  auto const buildResults = CKBuildComponent(scopeRoot, {}, componentFactory, buildTrigger, CKReflowTriggerNone);

  // Simulate state update on c1.childComponent
  NSNumber *newState1 = @10;
  CKComponentStateUpdateMap stateUpdates;
  stateUpdates[c1.childComponent.scopeHandle].push_back(^(id){ return newState1; });
  auto const buildTrigger2 = CKBuildComponentTrigger(buildResults.scopeRoot, stateUpdates, NO, NO);
  auto const buildResults2 = CKBuildComponent(buildResults.scopeRoot, stateUpdates, componentFactory, buildTrigger2, CKReflowTriggerNone);
  // Verify `c2.childComponent` gets the correct new state
  XCTAssertEqual(newState1, c1.childComponent.scopeHandle.state);
  // Verify c2 was reused
  XCTAssertTrue(c2.didReuseComponent);
  // Verify c1 wasn't reused
  XCTAssertFalse(c1.didReuseComponent);

  // Simulate state update on c2.childComponent
  NSNumber *newState2 = @20;
  CKComponentStateUpdateMap stateUpdates2;
  stateUpdates2[c2.childComponent.scopeHandle].push_back(^(id){ return newState2;});

  auto const buildTrigger3 = CKBuildComponentTrigger(buildResults2.scopeRoot, stateUpdates2, NO, NO);
  auto const buildResults3 = CKBuildComponent(buildResults2.scopeRoot, stateUpdates2, componentFactory, buildTrigger3, CKReflowTriggerNone);
  // Verify `c2.childComponent` gets the correct new state
  XCTAssertEqual(newState2, c2.childComponent.scopeHandle.state);
  // Verify c1 was reused
  XCTAssertTrue(c1.didReuseComponent);
  // Verify c2 wasn't reused
  XCTAssertFalse(c2.didReuseComponent);
  // Verify `c1.childComponent` preserves its state during component reuse
  XCTAssertEqual(newState1, c1.childComponent.scopeHandle.state);

  // Simulate state update on c1.childComponent
  NSNumber *newState3 = @30;
  CKComponentStateUpdateMap stateUpdates3;
  stateUpdates3[c1.childComponent.scopeHandle].push_back(^(id){ return newState3;});

  auto const buildTrigger4 = CKBuildComponentTrigger(buildResults3.scopeRoot, stateUpdates3, NO, NO);
  auto const buildResults4 = CKBuildComponent(buildResults3.scopeRoot, stateUpdates3, componentFactory, buildTrigger4, CKReflowTriggerNone);
  // Verify `c1.childComponent` gets the correct new state
  XCTAssertEqual(newState3, c1.childComponent.scopeHandle.state);
  // Verify c2 was reused
  XCTAssertTrue(c2.didReuseComponent);
  // Verify c1 wasn't reused
  XCTAssertFalse(c1.didReuseComponent);
  // Verify `c2.childComponent` preserves its state during component reuse
  XCTAssertEqual(newState2, c2.childComponent.scopeHandle.state);
}

- (void)test_renderComponentPreserveStateDuringComponentReuse
{
  // Build new tree with siblings `CKTestRenderWithNonRenderWithStateChildComponent` components.
  // Each `CKTestRenderWithNonRenderWithStateChildComponent` has non-render component with state.
  __block CKTestRenderWithNonRenderWithStateChildComponent *c1;
  __block CKTestRenderWithNonRenderWithStateChildComponent *c2;
  auto const componentFactory = ^{
    c1 = [CKTestRenderWithNonRenderWithStateChildComponent new];
    c2 = [CKTestRenderWithNonRenderWithStateChildComponent new];
    return [CKTestLayoutComponent newWithChildren:{c1, c2}];
  };

  // Build first component generation:
  auto const scopeRoot = CKComponentScopeRootWithPredicates(nil, nil, {}, {});
  auto const buildTrigger = CKBuildComponentTrigger(scopeRoot, {}, NO, NO);
  auto const buildResults = CKBuildComponent(scopeRoot, {}, componentFactory, buildTrigger, CKReflowTriggerNone);

  // Simulate state update on c1
  NSNumber *newState1 = @10;
  CKComponentStateUpdateMap stateUpdates;
  stateUpdates[c1.scopeHandle].push_back(^(id){ return newState1; });

  auto const buildTrigger2 = CKBuildComponentTrigger(buildResults.scopeRoot, stateUpdates, NO, NO);
  auto const buildResults2 = CKBuildComponent(buildResults.scopeRoot, stateUpdates, componentFactory, buildTrigger2, CKReflowTriggerNone);
  // Verify `c2.childComponent` gets the correct new state
  XCTAssertEqual(newState1, c1.scopeHandle.state);
  // Verify c2 was reused
  XCTAssertTrue(c2.didReuseComponent);
  // Verify c1 wasn't reused
  XCTAssertFalse(c1.didReuseComponent);

  // Simulate state update on c2
  NSNumber *newState2 = @20;
  CKComponentStateUpdateMap stateUpdates2;
  stateUpdates2[c2.scopeHandle].push_back(^(id){ return newState2;});

  auto const buildTrigger3 = CKBuildComponentTrigger(buildResults2.scopeRoot, stateUpdates2, NO, NO);
  auto const buildResults3 = CKBuildComponent(buildResults2.scopeRoot, stateUpdates2, componentFactory, buildTrigger3, CKReflowTriggerNone);
  // Verify `c2.childComponent` gets the correct new state
  XCTAssertEqual(newState2, c2.scopeHandle.state);
  // Verify c1 was reused
  XCTAssertTrue(c1.didReuseComponent);
  // Verify c2 wasn't reused
  XCTAssertFalse(c2.didReuseComponent);
  // Verify `c1.childComponent` preserves its state during component reuse
  XCTAssertEqual(newState1, c1.scopeHandle.state);

  // Simulate state update on c1
  NSNumber *newState3 = @30;
  CKComponentStateUpdateMap stateUpdates3;
  stateUpdates3[c1.scopeHandle].push_back(^(id){ return newState3;});

  auto const buildTrigger4 = CKBuildComponentTrigger(buildResults3.scopeRoot, stateUpdates3, NO, NO);
  auto const buildResults4 = CKBuildComponent(buildResults3.scopeRoot, stateUpdates3, componentFactory, buildTrigger4, CKReflowTriggerNone);
  // Verify `c1.childComponent` gets the correct new state
  XCTAssertEqual(newState3, c1.scopeHandle.state);
  // Verify c2 was reused
  XCTAssertTrue(c2.didReuseComponent);
  // Verify c1 wasn't reused
  XCTAssertFalse(c1.didReuseComponent);
  // Verify `c2.childComponent` preserves its state during component reuse
  XCTAssertEqual(newState2, c2.scopeHandle.state);
}

- (void)test_nodeToParentLinksAfterReuse
{
  // Build new tree with siblings `CKTestRenderWithNonRenderWithStateChildComponent` components.
  // Each `CKTestRenderWithNonRenderWithStateChildComponent` has non-render component with state.
  __block CKTestRenderWithNonRenderWithStateChildComponent *c1;
  __block CKTestRenderWithNonRenderWithStateChildComponent *c2;
  __block CKTestLayoutComponent *root;
  auto const componentFactory = ^{
    c1 = [CKTestRenderWithNonRenderWithStateChildComponent new];
    c2 = [CKTestRenderWithNonRenderWithStateChildComponent new];
    root = [CKTestLayoutComponent newWithChildren:{c1, c2}];
    return root;
  };

  // Build first component generation:
  auto const scopeRoot = CKComponentScopeRootWithPredicates(nil, nil, {}, {});
  auto const buildTrigger = CKBuildComponentTrigger(scopeRoot, {}, NO, NO);
  auto const buildResults = CKBuildComponent(scopeRoot, {}, componentFactory, buildTrigger, CKReflowTriggerNone);

  // Simulate state update on c1
  NSNumber *newState1 = @10;
  CKComponentStateUpdateMap stateUpdates;
  stateUpdates[c1.scopeHandle].push_back(^(id){ return newState1; });

  auto const buildTrigger2 = CKBuildComponentTrigger(buildResults.scopeRoot, stateUpdates, NO, NO);
  auto const buildResults2 = CKBuildComponent(buildResults.scopeRoot, stateUpdates, componentFactory, buildTrigger2, CKReflowTriggerNone);
  // Verify `c2.childComponent` gets the correct new state
  XCTAssertEqual(newState1, c1.scopeHandle.state);
  // Verify c2 was reused
  XCTAssertTrue(c2.didReuseComponent);
  // Verify c1 wasn't reused
  XCTAssertFalse(c1.didReuseComponent);

  NSMutableSet *components = [NSMutableSet setWithArray:@[c1, c2, c1.childComponent, c2.childComponent]];
  NSMutableSet *componentsFromParentNodeMap = [NSMutableSet set];

  // Add all the components from c1.childComponent to the root
  id<CKTreeNodeComponentProtocol> component = c1.childComponent;
  while (component) {
    [componentsFromParentNodeMap addObject:component];
    auto const parent = [buildResults2.scopeRoot rootNode].parentForNodeIdentifier(component.scopeHandle.treeNode.nodeIdentifier);
    component = parent.component;
  }

  // Add all the components from c2.childComponent to the root
  id<CKTreeNodeComponentProtocol> component2 = c2.childComponent;
  while (component2) {
    [componentsFromParentNodeMap addObject:component2];
    auto const parent = [buildResults2.scopeRoot rootNode].parentForNodeIdentifier(component2.scopeHandle.treeNode.nodeIdentifier);
    component2 = parent.component;
  }

  // Verify we got the same components from the node -> parent map as expected.
  XCTAssertTrue([components isEqualToSet:componentsFromParentNodeMap]);
}

- (void)test_componentReuseWhenReorderScopedComponents
{
  // Build new tree with siblings `CKCompositeComponentWithScope components
  // tha thas `CKTestRenderWithNonRenderWithStateChildComponent` children.
  // Each `CKTestRenderWithNonRenderWithStateChildComponent` has non-render component with state.
  __block CKCompositeComponentWithScope *c1;
  __block CKCompositeComponentWithScope *c2;
  __block CKCompositeComponentWithScope *c3;
  auto const componentFactory = ^{
    c1 = [CKCompositeComponentWithScope newWithComponentProvider:^CKComponent *{
      return [CKTestRenderWithNonRenderWithStateChildComponent new];
    } scopeIdentifier:@1];
    c2 = [CKCompositeComponentWithScope newWithComponentProvider:^CKComponent *{
      return [CKTestRenderWithNonRenderWithStateChildComponent new];
    } scopeIdentifier:@2];
    return [CKTestLayoutComponent newWithChildren:{c1, c2}];
  };

  // Build first component generation:
  auto const scopeRoot = CKComponentScopeRootWithPredicates(nil, nil, {}, {});
  auto const buildTrigger = CKBuildComponentTrigger(scopeRoot, {}, NO, NO);
  auto const buildResults = CKBuildComponent(scopeRoot, {}, componentFactory, buildTrigger, CKReflowTriggerNone);

  // Insert new child c3 before c1
  auto const componentFactory2 = ^{
    c3 = [CKCompositeComponentWithScope newWithComponentProvider:^CKComponent *{
      return [CKTestRenderWithNonRenderWithStateChildComponent new];
    } scopeIdentifier:@3];
    c1 = [CKCompositeComponentWithScope newWithComponentProvider:^CKComponent *{
      return [CKTestRenderWithNonRenderWithStateChildComponent new];
    } scopeIdentifier:@1];
    c2 = [CKCompositeComponentWithScope newWithComponentProvider:^CKComponent *{
      return [CKTestRenderWithNonRenderWithStateChildComponent new];
    } scopeIdentifier:@2];
    return [CKTestLayoutComponent newWithChildren:{c3, c1, c2}];
  };

  // Simulate state update on c1.child.childComponent
  NSNumber *newState1 = @10;
  CKComponentStateUpdateMap stateUpdates;
  auto c1Child = (CKTestRenderWithNonRenderWithStateChildComponent *)c1.childComponent;
  stateUpdates[c1Child.childComponent.scopeHandle].push_back(^(id){ return newState1; });

  auto const buildTrigger2 = CKBuildComponentTrigger(buildResults.scopeRoot, stateUpdates, NO, NO);
  auto const buildResults2 = CKBuildComponent(buildResults.scopeRoot, stateUpdates, componentFactory2, buildTrigger2, CKReflowTriggerNone);

  // Accessing the updated children
  c1Child = (CKTestRenderWithNonRenderWithStateChildComponent *)c1.childComponent;
  auto c2Child = (CKTestRenderWithNonRenderWithStateChildComponent *)c2.childComponent;

  // Verify `c2.child.childComponent` gets the correct new state
  XCTAssertEqual(newState1, c1Child.childComponent.scopeHandle.state);
  // Verify c2.child was reused
  XCTAssertTrue(c2Child.didReuseComponent);
  // Verify c1.child wasn't reused
  XCTAssertFalse(c1Child.didReuseComponent);
}

@end
