/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKRenderWithSizeSpecComponent.h"

#import "CKBuildComponent.h"
#import "CKRenderHelpers.h"
#import "CKRenderTreeNodeWithChildren.h"
#import "CKComponentInternal.h"

struct CKRenderWithSizeSpecComponentParameters {
  id<CKTreeNodeWithChildrenProtocol> previousParentForChild;
  const CKBuildComponentTreeParams &params;
  const CKBuildComponentConfig &config;
  const BOOL hasDirtyParent;

  CKRenderWithSizeSpecComponentParameters(id<CKTreeNodeWithChildrenProtocol> pP,
                                          const CKBuildComponentTreeParams &p,
                                          const CKBuildComponentConfig &c,
                                          BOOL hDP) : previousParentForChild(pP), params(p), config(c), hasDirtyParent(hDP) {};
};

@implementation CKRenderWithSizeSpecComponent {
  __weak CKRenderTreeNodeWithChildren *_node;
  std::unique_ptr<CKRenderWithSizeSpecComponentParameters> _parameters;
  NSHashTable<CKComponent *> *_measuredComponents;
#if CK_ASSERTIONS_ENABLED
  NSMutableSet *_renderedChildrenSet;
#endif
}

+ (instancetype)new
{
  return [self newRenderComponentWithView:{} size:{} isLayoutComponent:NO];
}

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view
                       size:(const CKComponentSize &)size
{
  return [self newRenderComponentWithView:view size:size isLayoutComponent:NO];
}

+ (instancetype)newRenderComponentWithView:(const CKComponentViewConfiguration &)view
                                      size:(const CKComponentSize &)size
                         isLayoutComponent:(BOOL)isLayoutComponent
{
  auto const c = [super newRenderComponentWithView:view size:size isLayoutComponent:isLayoutComponent];
  if (c) {
    c->_measuredComponents = [NSHashTable weakObjectsHashTable];
#if CK_ASSERTIONS_ENABLED
    c->_renderedChildrenSet = [NSMutableSet new];
#endif
  }
  return c;
}

- (void)buildComponentTree:(id<CKTreeNodeWithChildrenProtocol>)parent
            previousParent:(id<CKTreeNodeWithChildrenProtocol>)previousParent
                    params:(const CKBuildComponentTreeParams &)params
                    config:(const CKBuildComponentConfig &)config
            hasDirtyParent:(BOOL)hasDirtyParent
{
  if (!_node) {
    auto const node = [[CKRenderTreeNodeWithChildren alloc]
                       initWithComponent:self
                       parent:parent
                       previousParent:previousParent
                       scopeRoot:params.scopeRoot
                       stateUpdates:params.stateUpdates];
    _node = node;

    // Update the `hasDirtyParent` param for Faster state/props updates.
    if (!hasDirtyParent && CKRender::hasDirtyParent(node, previousParent, params, config)) {
      hasDirtyParent = YES;
    }

    auto const previousParentForChild = (id<CKTreeNodeWithChildrenProtocol>)[previousParent childForComponentKey:[node componentKey]];
    _parameters = std::make_unique<CKRenderWithSizeSpecComponentParameters>(previousParentForChild,
                                                                            params,
                                                                            config,
                                                                            hasDirtyParent);
  }
}


- (CKComponentLayout)measureChild:(CKComponent *)child
                  constrainedSize:(CKSizeRange)constrainedSize
             relativeToParentSize:(CGSize)parentSize {
  CKAssert(_parameters.get() != nullptr, @"measureChild called outside layout calculations");
  if (![_measuredComponents containsObject:child]) {
    [child buildComponentTree:_node
               previousParent:_parameters->previousParentForChild
                       params:_parameters->params
                       config:_parameters->config
               hasDirtyParent:_parameters->hasDirtyParent];
    [_measuredComponents addObject:child];
  }

#if CK_ASSERTIONS_ENABLED
  [_renderedChildrenSet addObject:child];
#endif
  return CKComputeComponentLayout(child, constrainedSize, parentSize);
}

#pragma mark - Layout

- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
                          restrictedToSize:(const CKComponentSize &)size
                      relativeToParentSize:(CGSize)parentSize
{
  auto const layout = [self render:_node.state constrainedSize:constrainedSize restrictedToSize:size relativeToParentSize:parentSize];
#if CK_ASSERTIONS_ENABLED
  checkIfAllChildrenComponentHaveBeenAddedToComponentTree(layout,_renderedChildrenSet);
#endif

  return layout;
}

- (CKComponentLayout)render:(id)state
            constrainedSize:(CKSizeRange)constrainedSize
           restrictedToSize:(const CKComponentSize &)size
       relativeToParentSize:(CGSize)parentSize
{
  const CKSizeRange resolvedRange = constrainedSize.intersect([self size].resolve(parentSize));
  return [self render:state constrainedSize:resolvedRange];
}

- (CKComponentLayout)render:(id)state
            constrainedSize:(CKSizeRange)constrainedSize
{
  CKFailAssert( @"When subclassing CKRenderWithSizeSpecComponent, you NEED to ovrride %@", NSStringFromSelector(_cmd));
  return {};
}

- (void)dealloc
{
  _parameters = nullptr;
}

#pragma mark - CKRenderComponent

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

#pragma mark - Render layout checker

#if CK_ASSERTIONS_ENABLED
static void checkIfAllChildrenComponentHaveBeenAddedToComponentTree(const CKComponentLayout &layout, NSSet *renderedChildren) {
  for (const auto ch : *layout.children) {
    const auto child = ch.layout.component;
    if ([child conformsToProtocol:@protocol(CKRenderComponentProtocol)]) {
      CKCAssert([renderedChildren containsObject:child], @"Component %@ is returned in layout but it was not attached to componentTree",child);
    }
  }
}
#endif

@end
