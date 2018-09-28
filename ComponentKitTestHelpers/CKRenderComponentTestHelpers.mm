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
            hasDirtyParent:(BOOL)hasDirtyParent
{
  [super buildComponentTree:parent previousParent:previousParent params:params hasDirtyParent:hasDirtyParent];
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
