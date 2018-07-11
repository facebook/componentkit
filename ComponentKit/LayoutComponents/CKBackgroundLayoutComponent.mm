/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKBackgroundLayoutComponent.h"

#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKMacros.h>
#import <ComponentKit/CKComponentInternal.h>

#import "CKComponentSubclass.h"
#import "CKRenderTreeNodeWithChildren.h"

@implementation CKBackgroundLayoutComponent
{
  CKComponent *_component;
  CKComponent *_background;
}

+ (instancetype)newWithComponent:(CKComponent *)component
                      background:(CKComponent *)background
{
  if (component == nil) {
    return nil;
  }
  CKBackgroundLayoutComponent *c = [super newWithView:{} size:{}];
  if (c) {
    c->_component = component;
    c->_background = background;
  }
  return c;
}

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view size:(const CKComponentSize &)size
{
  CK_NOT_DESIGNATED_INITIALIZER();
}

- (void)buildComponentTree:(id<CKTreeNodeWithChildrenProtocol>)owner
             previousOwner:(id<CKTreeNodeWithChildrenProtocol>)previousOwner
                 scopeRoot:(CKComponentScopeRoot *)scopeRoot
              stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
                    config:(const CKBuildComponentConfig &)config
{
  if (config.forceParent) {
    auto const node = [[CKTreeNodeWithChildren alloc]
                       initWithComponent:self
                       owner:owner
                       previousOwner:previousOwner
                       scopeRoot:scopeRoot
                       stateUpdates:stateUpdates];

    auto const previousOwnerForChild = (id<CKTreeNodeWithChildrenProtocol>)[previousOwner childForComponentKey:[node componentKey]];
    [_component buildComponentTree:node previousOwner:previousOwnerForChild scopeRoot:scopeRoot stateUpdates:stateUpdates config:config];
    [_background buildComponentTree:node previousOwner:previousOwnerForChild scopeRoot:scopeRoot stateUpdates:stateUpdates config:config];
  } else {
    [super buildComponentTree:owner previousOwner:previousOwner scopeRoot:scopeRoot stateUpdates:stateUpdates config:config];
    [_component buildComponentTree:owner previousOwner:previousOwner scopeRoot:scopeRoot stateUpdates:stateUpdates config:config];
    [_background buildComponentTree:owner previousOwner:previousOwner scopeRoot:scopeRoot stateUpdates:stateUpdates config:config];
  }
}

/**
 First layout the contents, then fit the background image.
 */
- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
                          restrictedToSize:(const CKComponentSize &)size
                      relativeToParentSize:(CGSize)parentSize
{
  CKAssert(size == CKComponentSize(),
           @"CKBackgroundLayoutComponent only passes size {} to the super class initializer, but received size %@ "
           "(component=%@, background=%@)", size.description(), _component, _background);

  const CKComponentLayout contentsLayout = [_component layoutThatFits:constrainedSize parentSize:parentSize];

  return {
    self,
    contentsLayout.size,
    _background
    ? std::vector<CKComponentLayoutChild> {
      {{0,0}, [_background layoutThatFits:{contentsLayout.size, contentsLayout.size} parentSize:contentsLayout.size]},
      {{0,0}, contentsLayout},
    }
    : std::vector<CKComponentLayoutChild> {
      {{0,0}, contentsLayout}
    }
  };
}

@end
