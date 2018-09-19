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
#import <ComponentKit/CKCompositeComponent.h>
#import <ComponentKit/CKFlexboxComponent.h>
#import <ComponentKit/CKRenderComponent.h>
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKThreadLocalComponentScope.h>
#import <ComponentKit/CKComponentScopeRootFactory.h>

#import "CKTreeNodeWithChild.h"
#import "CKTreeNodeWithChildren.h"

@interface CKTestChildRenderComponent : CKRenderComponent
@property (nonatomic, assign) BOOL hasDirtyParent;
@end

@interface CKTestRenderComponent : CKRenderComponent
@property (nonatomic, assign) NSUInteger renderCalledCounter;
@property (nonatomic, assign) NSUInteger identifier;
@property (nonatomic, strong) CKTestChildRenderComponent *childComponent;
+ (instancetype)newWithIdentifier:(NSUInteger)identifier;
@end

@interface CKCompositeComponentWithScopeAndState : CKCompositeComponent
@end

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
  CKThreadLocalComponentScope threadScope(nil, {});
  auto const c2 = [CKTestRenderComponent new];
  CKComponentScopeRoot *scopeRoot2 = [_scopeRoot newRoot];
  [c2 buildComponentTree:scopeRoot2.rootNode
          previousParent:_scopeRoot.rootNode
                  params:{
                    .scopeRoot = scopeRoot2,
                    .stateUpdates = {},
                    .treeNodeDirtyIds = {},
                    .buildTrigger = BuildTrigger::PropsUpdate,
                  }
                  config:_config
          hasDirtyParent:NO];

  [self verifyComponentIsNotBeingReused:_c c2:c2 scopeRoot:_scopeRoot scopeRoot2:scopeRoot2];
}

- (void)test_fasterStateUpdate_componentIsBeingReused_onStateUpdateOnADifferentComponentBranch
{
  [self setUpForFasterStateUpdates];

  // Simulate a state update on a different component branch:
  // 1. treeNodeDirtyIds with fake components ids.
  // 2. hasDirtyParent = NO
  CKThreadLocalComponentScope threadScope(nil, {});
  auto const c2 = [CKTestRenderComponent new];
  CKComponentScopeRoot *scopeRoot2 = [_scopeRoot newRoot];

  [c2 buildComponentTree:scopeRoot2.rootNode
          previousParent:_scopeRoot.rootNode
                  params:{
                    .scopeRoot = scopeRoot2,
                    .stateUpdates = {},
                    .treeNodeDirtyIds = {100, 101}, // Use a random id that represents a fake state update on a different branch.
                    .buildTrigger = BuildTrigger::StateUpdate,
                  }
                  config:_config
          hasDirtyParent:NO];

  // As the state update doesn't affect the c2, we should reuse c instead.
  [self verifyComponentIsBeingReused:_c c2:c2 scopeRoot:_scopeRoot scopeRoot2:scopeRoot2];
}

- (void)test_fasterStateUpdate_componentIsNotBeingReused_onStateUpdateOnAParent
{
  [self setUpForFasterStateUpdates];

  // Simulate a state update on a parent component:
  // 1. hasDirtyParent = YES
  // 2. treeNodeDirtyIds with a fake parent id.
  CKThreadLocalComponentScope threadScope(nil, {});
  CKComponentScopeRoot *scopeRoot2 = [_scopeRoot newRoot];

  auto const c2 = [CKTestRenderComponent new];
  [c2 buildComponentTree:scopeRoot2.rootNode
          previousParent:_scopeRoot.rootNode
                  params:{
                    .scopeRoot = scopeRoot2,
                    .stateUpdates = {},
                    .treeNodeDirtyIds = {100}, // Use a random id that represents a state update on a fake parent.
                    .buildTrigger = BuildTrigger::StateUpdate,
                  }
                  config:_config
          hasDirtyParent:YES];

  // As the state update affect c2, we should recreate its children.
  [self verifyComponentIsNotBeingReused:_c c2:c2 scopeRoot:_scopeRoot scopeRoot2:scopeRoot2];
  // Make sure the dirtyParent is pssed correctly to the child component.
  XCTAssertTrue(c2.childComponent.hasDirtyParent);
}

- (void)test_fasterStateUpdate_componentIsNotBeingReused_onStateUpdateOnTheComponent
{
  [self setUpForFasterStateUpdates];

  // Simulate a state update on the component itself:
  // 1. treeNodeDirtyIds contains the tree node identifier
  CKThreadLocalComponentScope threadScope(nil, {});
  CKComponentScopeRoot *scopeRoot2 = [_scopeRoot newRoot];

  auto const c2 = [CKTestRenderComponent new];
  [c2 buildComponentTree:scopeRoot2.rootNode
          previousParent:_scopeRoot.rootNode
                  params:{
                    .scopeRoot = scopeRoot2,
                    .stateUpdates = {},
                    .treeNodeDirtyIds = {
                      _c.scopeHandle.treeNode.nodeIdentifier
                    },
                    .buildTrigger = BuildTrigger::StateUpdate,
                  }
                  config:_config
          hasDirtyParent:NO];

  // As the state update affect c2, we should recreate its children.
  [self verifyComponentIsNotBeingReused:_c c2:c2 scopeRoot:_scopeRoot scopeRoot2:scopeRoot2];
  // Make sure the dirtyParent is pssed correctly to the child component.
  XCTAssertTrue(c2.childComponent.hasDirtyParent);
}

- (void)test_fasterStateUpdate_componentIsNotBeingReused_onStateUpdateOnItsChild
{
  [self setUpForFasterStateUpdates];

  // Simulate a state update on the component child:
  // 1. treeNodeDirtyIds, contains the component tree node id.
  // 2. hasDirtyParent = NO
  CKThreadLocalComponentScope threadScope(nil, {});
  CKComponentScopeRoot *scopeRoot2 = [_scopeRoot newRoot];

  auto const c2 = [CKTestRenderComponent new];

  [c2 buildComponentTree:scopeRoot2.rootNode
          previousParent:_scopeRoot.rootNode
                  params:{
                    .scopeRoot = scopeRoot2,
                    .stateUpdates = {},
                    .treeNodeDirtyIds = {
                      _c.scopeHandle.treeNode.nodeIdentifier // Mark the component as dirty
                    },
                    .buildTrigger = BuildTrigger::StateUpdate,
                  }
                  config:_config
          hasDirtyParent:NO];

  // As the state update affect c2, we should recreate its children.
  [self verifyComponentIsNotBeingReused:_c c2:c2 scopeRoot:_scopeRoot scopeRoot2:scopeRoot2];
  // Make sure the dirtyParent is pssed correctly to the child component.
  XCTAssertTrue(c2.childComponent.hasDirtyParent);
}

#pragma mark - Faster Props Update

- (void)test_fasterPropsUpdate_componentIsNotBeingReused_whenPropsAreNotEqual
{
  [self setUpForFasterPropsUpdates:[CKTestRenderComponent newWithIdentifier:1]];

  // Simulate props update.
  CKThreadLocalComponentScope threadScope(nil, {});
  auto const c2 = [CKTestRenderComponent newWithIdentifier:2];
  CKComponentScopeRoot *scopeRoot2 = [_scopeRoot newRoot];

  [c2 buildComponentTree:scopeRoot2.rootNode
          previousParent:_scopeRoot.rootNode
                  params:{
                    .scopeRoot = scopeRoot2,
                    .stateUpdates = {},
                    .treeNodeDirtyIds = {},
                    .buildTrigger = BuildTrigger::PropsUpdate,
                  }
                  config:_config
          hasDirtyParent:NO];

  // Props are not equal, we cannot reuse the component in this case.
  [self verifyComponentIsNotBeingReused:_c c2:c2 scopeRoot:_scopeRoot scopeRoot2:scopeRoot2];
  // Make sure the dirtyParent is pssed correctly to the child component.
  XCTAssertFalse(c2.childComponent.hasDirtyParent);
}

- (void)test_fasterPropsUpdate_componentIsBeingReusedWhenPropsAreEqual
{
  // Use the same componentIdentifier for both components.
  // shouldComponentUpdate: will return NO in this case and we can reuse the component.
  NSUInteger componentIdentifier = 1;
  [self setUpForFasterPropsUpdates:[CKTestRenderComponent newWithIdentifier:componentIdentifier]];

  // Simulate props update.
  CKThreadLocalComponentScope threadScope(nil, {});
  auto const c2 = [CKTestRenderComponent newWithIdentifier:componentIdentifier];
  CKComponentScopeRoot *scopeRoot2 = [_scopeRoot newRoot];

  [c2 buildComponentTree:scopeRoot2.rootNode
          previousParent:_scopeRoot.rootNode
                  params:{
                    .scopeRoot = scopeRoot2,
                    .stateUpdates = {},
                    .treeNodeDirtyIds = {},
                    .buildTrigger = BuildTrigger::PropsUpdate,
                  }
                  config:_config
          hasDirtyParent:NO];

  // The components are equal, we can reuse the previous component.
  [self verifyComponentIsBeingReused:_c c2:c2 scopeRoot:_scopeRoot scopeRoot2:scopeRoot2];
  // Make sure the dirtyParent is pssed correctly to the child component.
  XCTAssertFalse(c2.childComponent.hasDirtyParent);
}

- (void)test_fasterPropsUpdate_componentIsBeingReused_onStateUpdateWithDirtyParentAndEqualComponents
{
  auto const componentIdentifier = 1;
  [self setUpForFasterPropsUpdates:[CKTestRenderComponent newWithIdentifier:componentIdentifier]];

  // Simulate a state update on a parent component:
  // 1. hasDirtyParent = YES
  // 2. treeNodeDirtyIds with a fake parent id.
  CKThreadLocalComponentScope threadScope(nil, {});
  auto const c2 = [CKTestRenderComponent newWithIdentifier:componentIdentifier];
  CKComponentScopeRoot *scopeRoot2 = [_scopeRoot newRoot];

  [c2 buildComponentTree:scopeRoot2.rootNode
          previousParent:_scopeRoot.rootNode
                  params:{
                    .scopeRoot = scopeRoot2,
                    .stateUpdates = {},
                    .treeNodeDirtyIds = {100}, // Use a random id that represents a state update on a fake parent.
                    .buildTrigger = BuildTrigger::StateUpdate,
                  }
                  config:_config
          hasDirtyParent:YES];

  // c has dirty parent, however, the components are equal, so we reuse the previous component.
  [self verifyComponentIsBeingReused:_c c2:c2 scopeRoot:_scopeRoot scopeRoot2:scopeRoot2];
}

- (void)test_fasterPropsUpdate_componentIsBeingReused_onStateUpdateWithNonDirtyComponentAndEqualComponents
{
  auto const componentIdentifier = 1;
  [self setUpForFasterPropsUpdates:[CKTestRenderComponent newWithIdentifier:componentIdentifier]];

  // Simulate a state update on a parent component:
  // 1. hasDirtyParent = NO
  // 2. treeNodeDirtyIds is empty.
  CKThreadLocalComponentScope threadScope(nil, {});
  auto const c2 = [CKTestRenderComponent newWithIdentifier:componentIdentifier];
  CKComponentScopeRoot *scopeRoot2 = [_scopeRoot newRoot];

  [c2 buildComponentTree:scopeRoot2.rootNode
          previousParent:_scopeRoot.rootNode
                  params:{
                    .scopeRoot = scopeRoot2,
                    .stateUpdates = {},
                    .treeNodeDirtyIds = {},
                    .buildTrigger = BuildTrigger::StateUpdate,
                  }
                  config:_config
          hasDirtyParent:NO];

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

#pragma mark - hasDirtyParent

- (void)test_hasDirtyParentPropagatedCorrectly
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
  XCTAssertFalse(c.childComponent.hasDirtyParent);

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
  XCTAssertTrue(c2.childComponent.hasDirtyParent);
}

#pragma mark - Helpers

- (void)verifyComponentIsNotBeingReused:(CKTestRenderComponent *)c
                                     c2:(CKTestRenderComponent *)c2
                              scopeRoot:(CKComponentScopeRoot *)scopeRoot
                             scopeRoot2:(CKComponentScopeRoot *)scopeRoot2
{
  CKTreeNodeWithChild *childNode = (CKTreeNodeWithChild *)scopeRoot.rootNode.children[0];
  CKTreeNodeWithChild *childNode2 = (CKTreeNodeWithChild *)scopeRoot2.rootNode.children[0];
  XCTAssertEqual(c.renderCalledCounter, 1);
  XCTAssertEqual(c2.renderCalledCounter, 1);
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
  XCTAssertEqual(c.childComponent, c2.childComponent);
  XCTAssertEqual(childNode.child, childNode2.child);
}

static const CKBuildComponentTreeParams newTreeParams(CKComponentScopeRoot *scopeRoot) {
  return {
    .scopeRoot = scopeRoot,
    .stateUpdates = {},
    .treeNodeDirtyIds = {},
    .buildTrigger = BuildTrigger::NewTree,
  };
}

static CKComponentScopeRoot *createNewTreeWithComponentAndReturnScopeRoot(const CKBuildComponentConfig &config, CKTestRenderComponent *c) {
  CKThreadLocalComponentScope threadScope(nil, {});
  auto const scopeRoot = CKComponentScopeRootWithDefaultPredicates(nil, nil);
  const CKBuildComponentTreeParams params = newTreeParams(scopeRoot);
  [c buildComponentTree:scopeRoot.rootNode
         previousParent:nil
                 params:params
                 config:config
         hasDirtyParent:NO];
  return scopeRoot;
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

#pragma mark - Helper Classes

@implementation CKTestRenderComponent

+ (instancetype)newWithIdentifier:(NSUInteger)identifier
{
  auto const c = [super new];
  if (c) {
    c->_identifier = identifier;
  }
  return c;
}

- (CKComponent *)render:(id)state
{
  _renderCalledCounter++;
  _childComponent = [CKTestChildRenderComponent new];
  return _childComponent;
}

+ (id)initialState
{
  return nil;
}

- (BOOL)shouldComponentUpdate:(CKTestRenderComponent *)component
{
  return _identifier != component->_identifier;
}

- (void)didReuseComponent:(CKTestRenderComponent *)component
{
  _childComponent = component->_childComponent;
}

@end

@implementation CKTestChildRenderComponent

+ (id)initialState
{
  return nil;
}

- (void)buildComponentTree:(id<CKTreeNodeWithChildrenProtocol>)parent
            previousParent:(id<CKTreeNodeWithChildrenProtocol>)previousParent
                    params:(const CKBuildComponentTreeParams &)params
                    config:(const CKBuildComponentConfig &)config
            hasDirtyParent:(BOOL)hasDirtyParent
{
  [super buildComponentTree:parent previousParent:previousParent params:params config:config hasDirtyParent:hasDirtyParent];
  _hasDirtyParent = hasDirtyParent;
}

@end

@implementation CKCompositeComponentWithScopeAndState
+ (instancetype)newWithComponent:(CKComponent *)component
{
  CKComponentScope scope(self);
  return [super newWithComponent:component];
}

+ (id)initialState
{
  return @1;
}
@end
