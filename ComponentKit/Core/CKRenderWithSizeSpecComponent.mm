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
#import "CKOwnerTreeNode.h"
#import "CKComponentInternal.h"

struct CKRenderWithSizeSpecComponentParameters {
  id<CKOwnerTreeNodeProtocol> ownerForChild;
  id<CKOwnerTreeNodeProtocol> previousOwnerForChild;
  const CKComponentStateUpdateMap* stateUpdates;
  CKComponentScopeRoot *scopeRoot;

  CKRenderWithSizeSpecComponentParameters(id<CKOwnerTreeNodeProtocol> o,
                                          id<CKOwnerTreeNodeProtocol> pO,
                                          const CKComponentStateUpdateMap* sU,
                                          CKComponentScopeRoot *sR) : ownerForChild(o), previousOwnerForChild(pO), stateUpdates(sU), scopeRoot(sR) {};
};

@implementation CKRenderWithSizeSpecComponent {
  __weak CKTreeNode *_node;
  std::unique_ptr<CKRenderWithSizeSpecComponentParameters> _parameters;
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
#if CK_ASSERTIONS_ENABLED
  if (c) {
    c->_renderedChildrenSet = [NSMutableSet new];
  }
#endif
  return c;
}

- (CKComponentLayout)measureChild:(CKComponent *)child
                  constrainedSize:(CKSizeRange)constrainedSize
             relativeToParentSize:(CGSize)parentSize {
  CKAssert(_parameters.get() != nullptr, @"measureChild called outside layout calculations");
  [child buildComponentTree:_parameters->ownerForChild
              previousOwner:_parameters->previousOwnerForChild
                  scopeRoot:_parameters->scopeRoot
               stateUpdates:*(_parameters->stateUpdates)];
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
  _parameters = nullptr;

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

- (void)buildComponentTree:(id<CKOwnerTreeNodeProtocol>)owner
             previousOwner:(id<CKOwnerTreeNodeProtocol>)previousOwner
                 scopeRoot:(CKComponentScopeRoot *)scopeRoot
              stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
{
  auto const isOwnerComponent = [[self class] isOwnerComponent];
  const Class nodeClass = isOwnerComponent ? [CKOwnerTreeNode class] : [CKRenderTreeNode class];
  CKTreeNode *const node = [[nodeClass alloc]
                       initWithComponent:self
                       owner:owner
                       previousOwner:previousOwner
                       scopeRoot:scopeRoot
                       stateUpdates:stateUpdates];
  _node = node;

  _parameters = std::make_unique<CKRenderWithSizeSpecComponentParameters>(
                                                                          (isOwnerComponent ? (id<CKOwnerTreeNodeProtocol>)_node : owner),
                                                                          (isOwnerComponent ? (id<CKOwnerTreeNodeProtocol>)[previousOwner childForComponentKey:[_node componentKey]] : previousOwner),
                                                                          &stateUpdates,
                                                                          scopeRoot);
}

#pragma mark - CKRenderComponent

+ (BOOL)isOwnerComponent
{
  return NO;
}

+ (id)initialStateWithComponent:(id<CKRenderComponentProtocol>)component
{
  return [self initialState];
}

+ (id)initialState
{
  return [CKTreeNodeEmptyState emptyState];
}

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

