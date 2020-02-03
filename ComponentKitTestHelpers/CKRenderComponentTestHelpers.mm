/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKRenderComponentTestHelpers.h"

#import <ComponentKit/CKBuildComponent.h>
#import <ComponentKit/CKComponentController.h>
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKRootTreeNode.h>
#import <ComponentKit/CKTreeNodeProtocol.h>

@implementation CKTestRenderComponent
{
  BOOL _shouldUseComponentContext;
  BOOL _shouldUseNonRenderChild;
}

+ (instancetype)newWithProps:(const CKTestRenderComponentProps &)props
{
  auto const c = [super new];
  if (c) {
    c->_identifier = props.identifier;
    c->_shouldUseComponentContext = props.shouldUseComponentContext;
    c->_shouldUseNonRenderChild = props.shouldUseNonRenderChild;
  }
  return c;
}

- (CKComponent *)render:(id)state
{
  CKComponentMutableContext<NSNumber> context(@1);
  _renderCalledCounter++;
  if (_shouldUseNonRenderChild) {
    _nonRenderChildComponent = [CKCompositeComponentWithScopeAndState
                                newWithComponent:
                                [CKCompositeComponentWithScopeAndState
                                 newWithComponent:
                                [CKCompositeComponentWithScopeAndState
                                 newWithComponent:
                                CK::ComponentBuilder().build()]]];
    return _nonRenderChildComponent;
  }
  _childComponent = [CKTestChildRenderComponent newWithProps:{
    .shouldUseComponentContext = _shouldUseComponentContext,
  }];
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
  _didReuseComponent = YES;
  _childComponent = component->_childComponent;
  _nonRenderChildComponent = component->_nonRenderChildComponent;
  _shouldUseNonRenderChild = component->_shouldUseNonRenderChild;
}

@end

@implementation CKTestChildRenderComponent
{
  NSNumber *_value;
}

+ (instancetype)newWithProps:(const CKTestChildRenderComponentProps &)props
{
  auto const c = [super new];
  if (c) {
    if (props.shouldUseComponentContext) {
      c->_value = CKComponentMutableContext<NSNumber>::get();
    }
  }
  return c;
}

+ (Class<CKComponentControllerProtocol>)controllerClass
{
  return [CKTestChildRenderComponentController class];
}

+ (id)initialState
{
  return nil;
}

- (CKComponent *)render:(id)state
{
  return nil;
}

- (void)buildComponentTree:(id<CKTreeNodeWithChildrenProtocol>)parent
            previousParent:(id<CKTreeNodeWithChildrenProtocol> _Nullable)previousParent
                    params:(const CKBuildComponentTreeParams &)params
      parentHasStateUpdate:(BOOL)parentHasStateUpdate
{
  [super buildComponentTree:parent previousParent:previousParent params:params parentHasStateUpdate:parentHasStateUpdate];
  _parentHasStateUpdate = parentHasStateUpdate;
}

- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
                          restrictedToSize:(const CKComponentSize &)size
                      relativeToParentSize:(CGSize)parentSize
{
  _computeCalledCounter++;
  return [super computeLayoutThatFits:constrainedSize restrictedToSize:size relativeToParentSize:parentSize];
}

@end

@implementation CKCompositeComponentWithScopeAndState
{
  CKComponent *_child;
}
+ (instancetype)newWithComponent:(CKComponent *)component
{
  CKComponentScope scope(self);
  auto const c = [super newWithComponent:component];
  if (c) {
    c->_child = component;
  }
  return c;
}

+ (id)initialState
{
  return @1;
}

- (CKComponent *)child
{
  return _child;
}
@end

@implementation CKTestRenderWithNonRenderWithStateChildComponent
+ (id)initialState
{
  return @1;
}

- (CKComponent *)render:(id)state
{
  _childComponent = [CKCompositeComponentWithScopeAndState
                     newWithComponent:[CKComponent new]];
  return _childComponent;
}

- (void)didReuseComponent:(CKTestRenderWithNonRenderWithStateChildComponent *)component
{
  _didReuseComponent = YES;
  _childComponent = component->_childComponent;
}
@end

@implementation CKTestLayoutComponent
{
  std::vector<CKComponent *> _children;
}
+ (instancetype)newWithChildren:(std::vector<CKComponent *>)children
{
  auto const c = [super newWithView:{} size:{}];
  if (c) {
    c->_children = children;
  }
  return c;
}
- (unsigned int)numberOfChildren
{
  return (unsigned int)_children.size();
}
- (id<CKMountable>)childAtIndex:(unsigned int)index
{
  if (index < _children.size()) {
    return _children[index];
  }
  CKFailAssertWithCategory([self class], @"Index %u is out of bounds %lu", index, _children.size());
  return nil;
}
@end

@implementation CKTestChildRenderComponentController
@end

@implementation CKCompositeComponentWithScope

+ (instancetype)newWithComponentProvider:(CKComponent *(^)())componentProvider
{
  CKComponentScope scope(self);
  return [super newWithComponent:componentProvider()];
}
@end
