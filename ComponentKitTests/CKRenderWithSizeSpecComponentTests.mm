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

#import "CKRenderWithSizeSpecComponent.h"
#import "CKRenderComponent.h"
#import "CKBuildComponent.h"
#import "CKComponentInternal.h"
#import "CKComponentSubclass.h"
#import "CKRenderTreeNodeWithChildren.h"
#import "CKComponentScopeHandle.h"
#import "CKThreadLocalComponentScope.h"

#import <ComponentKit/CKComponentScopeRootFactory.h>

// RenderWithSizeSpecComponent that gets a child from the constructor, and is an ownerComponent
@interface TestOwnerRenderWithSizeSpecComponent_ChildFromOutside : CKRenderWithSizeSpecComponent
+ (TestOwnerRenderWithSizeSpecComponent_ChildFromOutside *)newWithChild:(CKComponent *)child;
@end

@interface TestRenderChildComponentRetainingParameters : CKRenderComponent
@property (weak) id<CKTreeNodeWithChildrenProtocol> parent;
@property (weak) id<CKTreeNodeWithChildrenProtocol> previousParent;
@property const CKBuildComponentTreeParams *params;
@property const CKBuildComponentConfig *config;
@end

@interface CKRenderWithSizeSpecComponentTests : XCTestCase

@end

@implementation CKRenderWithSizeSpecComponentTests

- (void)test_ChildNode_IsAttached_To_OwnerRenderNode {
  // The 'resolve' method in CKComponentScopeHandle requires a CKThreadLocalComponentScope.
  // We should get rid of this assert once we move to the render method only.
  CKThreadLocalComponentScope threadScope(nil, {});
  CKRenderTreeNodeWithChildren *root = [[CKRenderTreeNodeWithChildren alloc] init];
  TestRenderChildComponentRetainingParameters *child = [TestRenderChildComponentRetainingParameters new];
  CKRenderTreeNodeWithChildren *previousRoot = [[CKRenderTreeNodeWithChildren alloc] init];
  CKComponentScopeRoot *scopeRoot = [CKComponentScopeRoot new];
  id (^stateUpdateBlock)(id) = ^(id){
    return (id)@"Test";
  };
  CKComponentScopeHandle *testScopeHandle = root.handle;
  std::unordered_map<CKComponentScopeHandle *, std::vector<id (^)(id)>> testUpdateMap({
    { testScopeHandle, {stateUpdateBlock} }
  });

  TestOwnerRenderWithSizeSpecComponent_ChildFromOutside *c = [TestOwnerRenderWithSizeSpecComponent_ChildFromOutside newWithChild:child];

  CKTreeNodeComponentKey previuosOwnerKey = [previousRoot createComponentKeyForChildWithClass:[c class]];
  CKRenderTreeNodeWithChildren *previousParent = [CKRenderTreeNodeWithChildren new];
  [previousRoot setChild:previousParent forComponentKey:previuosOwnerKey];

  const CKBuildComponentTreeParams params = {
    .scopeRoot = scopeRoot,
    .stateUpdates = testUpdateMap,
    .buildTrigger = BuildTrigger::NewTree,
    .treeNodeDirtyIds = {},
  };
  [c buildComponentTree:root previousParent:previousRoot params:params config:{} hasDirtyParent:NO];

  // Make sure the root has only one child.
  const auto singleChildNode = root.children[0];
  XCTAssertEqual(singleChildNode.component, c);
  XCTAssertEqual(root.children.size(), 1);

  // Check the next level of the tree
  XCTAssertTrue([singleChildNode isKindOfClass:[CKRenderTreeNodeWithChildren class]]);
  CKRenderTreeNodeWithChildren *parentNode = (CKRenderTreeNodeWithChildren *)singleChildNode;

  //Check that there are no children attached before we call -measureChild
  XCTAssertEqual(parentNode.children.size(), 0);

  CKComponentLayout componentLayout = [c render:nil
                                constrainedSize:CKSizeRange(CGSizeMake(200, 200), CGSizeMake(200, 200))
                               restrictedToSize:CKComponentSize::fromCGSize(CGSizeMake(200, 200))
                           relativeToParentSize:CGSizeMake(200, 200)];

  //It should only contain one child layout
  XCTAssertEqual(componentLayout.children->size(), 1);
  CKComponentLayout firstLayout = componentLayout.children->at(0).layout;
  XCTAssertEqual(child, firstLayout.component);

  //Now the tree node has a child
  XCTAssertEqual(parentNode.children.size(), 1);
  //and it's the first component
  XCTAssertEqual(child, parentNode.children[0].component);

  //Make sure that the parameters that we pass to the child component from measureChild: are correct
  XCTAssertEqual(child.parent, singleChildNode);
  XCTAssertEqual(child.previousParent, previousParent);
  XCTAssertEqual(child.params->stateUpdates, testUpdateMap);
  XCTAssertEqual(child.params->scopeRoot, scopeRoot);

}

@end

@implementation TestRenderChildComponentRetainingParameters

+ (instancetype)new {
  TestRenderChildComponentRetainingParameters *const c = [super new];
  if (c) {
    c->_parent = nil;
    c->_previousParent = nil;
    c->_params = nullptr;
    c->_config = nullptr;
  }
  return c;
}

- (CKComponent *)render:(id)state {
  return [CKComponent newWithView:{} size:{
    .width = 100,
    .height = 100,
  }];
}

- (void)buildComponentTree:(id<CKTreeNodeWithChildrenProtocol>)parent
            previousParent:(id<CKTreeNodeWithChildrenProtocol>)previousParent
                    params:(const CKBuildComponentTreeParams &)params
                    config:(const CKBuildComponentConfig &)config
            hasDirtyParent:(BOOL)hasDirtyParent
{
  _parent = parent;
  _previousParent = previousParent;
  _params = &params;
  _config = &config;
  [super buildComponentTree:parent previousParent:previousParent params:params config:config  hasDirtyParent:hasDirtyParent];
}

@end


@implementation TestOwnerRenderWithSizeSpecComponent_ChildFromOutside {
  CKComponent * _child;
}

+ (TestOwnerRenderWithSizeSpecComponent_ChildFromOutside *)newWithChild:(CKComponent *)child {
  const auto c = [super new];
  if (c) {
    c->_child =child;
  }
  return c;
}

- (CKComponentLayout)render:(id)state constrainedSize:(CKSizeRange)constrainedSize restrictedToSize:(const CKComponentSize &)size relativeToParentSize:(CGSize)parentSize {
  CKComponentLayout cLayout = [self measureChild:_child constrainedSize:constrainedSize relativeToParentSize:parentSize];
  return {
    self,
    cLayout.size,
    {
      {{0,0}, cLayout}
    }
  };
}

@end
