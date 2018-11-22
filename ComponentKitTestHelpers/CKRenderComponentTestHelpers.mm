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
#import <ComponentKit/CKTreeNodeProtocol.h>

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
  _didReuseComponent = YES;
  _childComponent = component->_childComponent;
}

@end

@implementation CKTestChildRenderComponent

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
            previousParent:(id<CKTreeNodeWithChildrenProtocol>)previousParent
                    params:(const CKBuildComponentTreeParams &)params
      parentHasStateUpdate:(BOOL)parentHasStateUpdate
{
  [super buildComponentTree:parent previousParent:previousParent params:params parentHasStateUpdate:parentHasStateUpdate];
  _parentHasStateUpdate = parentHasStateUpdate;
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

@implementation CKTestRenderWithChildrenComponent
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
+ (BOOL)requiresScopeHandle
{
  return YES;
}
- (std::vector<CKComponent *>)renderChildren:(id)state
{
  return _children;
}
@end

@implementation CKTestChildRenderComponentController
@end
