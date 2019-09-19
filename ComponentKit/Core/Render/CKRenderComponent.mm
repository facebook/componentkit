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
  CKRenderLayoutCache _cachedLayout;
  BOOL _enableLayoutCache;
}

#if DEBUG
+ (void)initialize
{
  if (self != [CKRenderComponent class]) {
    CKAssert(!CKSubclassOverridesInstanceMethod([CKRenderComponent class], self, @selector(computeLayoutThatFits:)),
             @"%@ overrides -computeLayoutThatFits: which is not allowed. "
             "Consider subclassing CKRenderLayoutWithChildrenComponent directly if you need to perform custom layout.",
             self);
    CKAssert(!CKSubclassOverridesInstanceMethod([CKRenderComponent class], self, @selector(layoutThatFits:parentSize:)),
             @"%@ overrides -layoutThatFits:parentSize: which is not allowed. "
             "Consider subclassing CKRenderLayoutWithChildrenComponent directly if you need to perform custom layout.",
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
  auto const node = CKRender::ComponentTree::Render::build(self, &_child, parent, previousParent, params, parentHasStateUpdate, didReuseBlock);
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
           "(component=%@)", size.description(), _child);

  if (_child) {
    CKComponentLayout l;
    if (_enableLayoutCache) {
      if (_cachedLayout.childLayout.component != nil &&
          CGSizeEqualToSize(parentSize, _cachedLayout.parentSize) &&
          constrainedSize == _cachedLayout.constrainedSize) {
        l = _cachedLayout.childLayout;
      } else {
        l = [_child layoutThatFits:constrainedSize parentSize:parentSize];
        _cachedLayout = {
          .constrainedSize = constrainedSize,
          .parentSize = parentSize,
          .childLayout = l,
        };
      }
    } else {
      l = [_child layoutThatFits:constrainedSize parentSize:parentSize];
    }
    return {self, l.size, {{{0,0}, l}}};
  }
  return [super computeLayoutThatFits:constrainedSize restrictedToSize:size relativeToParentSize:parentSize];
}

- (CKComponent *)childComponent
{
  return _child;
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

- (void)linkComponent:(id<CKRenderComponentProtocol>)component
             toParent:(id<CKTreeNodeWithChildrenProtocol>)parent
       previousParent:(id<CKTreeNodeWithChildrenProtocol>)previousParent
               params:(const CKBuildComponentTreeParams &)params
{
  Class componentClass = [component class];
  auto const componentKey = [parent createComponentKeyForChildWithClass:componentClass identifier:[component componentIdentifier]];
  auto const previousNode = [previousParent childForComponentKey:componentKey];
  auto const scopeRoot = params.scopeRoot;
  [self setComponentKey:componentKey];

  // For Render Layout components, the component might have a scope handle already.
  CKComponentScopeHandle *scopeHandle = component.scopeHandle;
  if (scopeHandle == nil) {
    // If there is a previous node, we just duplicate the scope handle.
    if (previousNode) {
      scopeHandle = [previousNode.scopeHandle newHandleWithStateUpdates:params.stateUpdates
                                                     componentScopeRoot:scopeRoot];
    } else {
      // The component needs a scope handle in few cases:
      // 1. Has an initial state
      // 2. Has a controller
      // 3. Returns `YES` from `requiresScopeHandle`
      id initialState = [componentClass initialStateWithComponent:component];
      if (initialState != [CKTreeNodeEmptyState emptyState] ||
          [componentClass controllerClass] ||
          [componentClass requiresScopeHandle]) {
        scopeHandle = [[CKComponentScopeHandle alloc] initWithListener:scopeRoot.listener
                                                        rootIdentifier:scopeRoot.globalIdentifier
                                                        componentClass:componentClass
                                                          initialState:initialState];
      }
    }

    // Finalize the node/scope regsitration.
    if (scopeHandle) {
      [component acquireScopeHandle:scopeHandle];
      [scopeRoot registerComponent:component];
      [scopeHandle resolve];
    }
  }

  [super linkComponent:component toParent:parent previousParent:previousParent params:params];
}

@end
