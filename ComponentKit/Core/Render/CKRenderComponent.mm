/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKRenderComponent.h"

#import "CKBuildComponent.h"
#import "CKComponentInternal.h"
#import "CKRenderComponentInternal.h"
#import "CKComponentSubclass.h"
#import "CKInternalHelpers.h"
#import "CKRenderHelpers.h"
#import "CKTreeNode.h"
#import "CKGlobalConfig.h"

struct CKRenderLayoutCache {
  CKSizeRange constrainedSize;
  CGSize parentSize;
  CKComponentLayout childLayout;
};

@implementation CKRenderComponent
{
  CKComponent *_childComponent;
  std::shared_ptr<CKRenderLayoutCache> _cachedLayout;
  BOOL _enableLayoutCache;
}

#if DEBUG
+ (void)initialize
{
  if (self != [CKRenderComponent class]) {
    CKAssert(!CKSubclassOverridesInstanceMethod([CKRenderComponent class], self, @selector(computeLayoutThatFits:)),
             @"%@ overrides -computeLayoutThatFits: which is not allowed. "
             "Consider subclassing CKRenderWithChildrenComponent directly if you need to perform custom layout.",
             self);
    CKAssert(!CKSubclassOverridesInstanceMethod([CKRenderComponent class], self, @selector(layoutThatFits:parentSize:)),
             @"%@ overrides -layoutThatFits:parentSize: which is not allowed. "
             "Consider subclassing CKRenderWithChildrenComponent directly if you need to perform custom layout.",
             self);
  }
}
#endif

+ (instancetype)new
{
  return [super newRenderComponentWithView:{} size:{}];
}

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view
                       size:(const CKComponentSize &)size
{
  return [super newRenderComponentWithView:view size:size];
}

- (CKComponent *)render:(id)state
{
  CKFailAssert(@"%@ MUST override the '%@' method.", [self class], NSStringFromSelector(_cmd));
  return nil;
}

- (void)buildComponentTree:(id<CKTreeNodeWithChildrenProtocol>)parent
            previousParent:(id<CKTreeNodeWithChildrenProtocol>)previousParent
                    params:(const CKBuildComponentTreeParams &)params
      parentHasStateUpdate:(BOOL)parentHasStateUpdate
{
  // Layout cache feature.
  _enableLayoutCache = params.enableLayoutCache;
  CKRenderDidReuseComponentBlock didReuseBlock = nil;
  if (_enableLayoutCache) {
    didReuseBlock =^(id<CKRenderComponentProtocol> reusedComponent){
      CKRenderComponent *c = (CKRenderComponent *)reusedComponent;
      self->_cachedLayout = c->_cachedLayout;
    };
  }
  // Build the component tree.
  auto const node = CKRender::buildComponentTreeWithChild(self, &_childComponent, parent, previousParent, params, parentHasStateUpdate, NO, didReuseBlock);
  auto const viewConfiguration = [self viewConfigurationWithState:node.state];
  if (!viewConfiguration.isDefaultConfiguration()) {
    [self setViewConfiguration:viewConfiguration];
  }
}

- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
                          restrictedToSize:(const CKComponentSize &)size
                      relativeToParentSize:(CGSize)parentSize
{
  CKAssert(size == CKComponentSize(),
           @"CKRenderComponent only passes size {} to the super class initializer, but received size %@ "
           "(component=%@)", size.description(), _childComponent);

  if (_childComponent) {
    CKComponentLayout l;
    if (_enableLayoutCache) {
      if (_cachedLayout != nullptr &&
          CGSizeEqualToSize(parentSize, _cachedLayout->parentSize) &&
          constrainedSize == _cachedLayout->constrainedSize) {
        l = _cachedLayout->childLayout;
      } else {
        l = [_childComponent layoutThatFits:constrainedSize parentSize:parentSize];
        _cachedLayout = std::make_shared<CKRenderLayoutCache>(CKRenderLayoutCache{
          .constrainedSize = constrainedSize,
          .parentSize = parentSize,
          .childLayout = l,
        });
      }
    } else {
      l = [_childComponent layoutThatFits:constrainedSize parentSize:parentSize];
    }
    return {self, l.size, {{{0,0}, l}}};
  }
  return [super computeLayoutThatFits:constrainedSize restrictedToSize:size relativeToParentSize:parentSize];
}

- (CKComponent *)childComponent
{
  return _childComponent;
}

#pragma mark - CKRenderComponentProtocol

+ (id)initialStateWithComponent:(id<CKRenderComponentProtocol>)component
{
  return [self initialState];
}

+ (id)initialState
{
  return [CKTreeNodeEmptyState emptyState];
}

- (BOOL)shouldComponentUpdate:(id<CKRenderComponentProtocol>)component
{
  return YES;
}

- (void)didReuseComponent:(id<CKRenderComponentProtocol>)component {}

- (CKComponentViewConfiguration)viewConfigurationWithState:(id)state
{
  return {};
}

- (id)componentIdentifier
{
  return nil;
}

@end
