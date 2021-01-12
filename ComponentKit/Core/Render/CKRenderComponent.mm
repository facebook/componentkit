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

#import <ComponentKit/CKInternalHelpers.h>
#import <ComponentKit/CKMutex.h>

#import "CKComponentInternal.h"
#import "CKComponentCreationValidation.h"
#import "CKComponentSubclass.h"
#import "CKThreadLocalComponentScope.h"
#import "CKIterableHelpers.h"
#import "CKRenderHelpers.h"
#import "CKTreeNode.h"

@implementation CKRenderComponent
{
  CKComponent *_child;
}

#if DEBUG
+ (void)initialize
{
  if (self != [CKRenderComponent class]) {
    CKAssert(!CKSubclassOverridesInstanceMethod([CKRenderComponent class], self, @selector(computeLayoutThatFits:)),
             @"%@ overrides -computeLayoutThatFits: which is not allowed. "
             "Consider subclassing CKLayoutComponent directly if you need to perform custom layout.",
             self);
    CKAssert(!CKSubclassOverridesInstanceMethod([CKRenderComponent class], self, @selector(layoutThatFits:parentSize:)),
             @"%@ overrides -layoutThatFits:parentSize: which is not allowed. "
             "Consider subclassing CKLayoutComponent directly if you need to perform custom layout.",
             self);
  }
}
#endif

- (void)didFinishComponentInitialization
{
  // Not calling super intentionally.
  CKValidateRenderComponentCreation();
  CKThreadLocalComponentScope::markCurrentScopeWithRenderComponentInTree();
  CKComponentContextHelper::didCreateRenderComponent(self);
}

- (CKComponent *)render:(id)state
{
  CKFailAssert(@"%@ MUST override the '%@' method.", self.className, NSStringFromSelector(_cmd));
  return nil;
}

- (UIView *)viewForAnimation
{
  // Delegate to the wrapped component's viewForAnimation if we don't have one.
  return [super viewForAnimation] ?: [_child viewForAnimation];
}

- (void)buildComponentTree:(id<CKTreeNodeWithChildrenProtocol>)parent
            previousParent:(id<CKTreeNodeWithChildrenProtocol> _Nullable)previousParent
                    params:(const CKBuildComponentTreeParams &)params
      parentHasStateUpdate:(BOOL)parentHasStateUpdate
{
  // Build the component tree.
  auto const node = CKRender::ComponentTree::Render::build(self, &_child, parent, previousParent, params, parentHasStateUpdate, nil);
  auto const viewConfiguration = [self viewConfigurationWithState:node.state];
  if (!viewConfiguration.isDefaultConfiguration()) {
    [self setViewConfiguration:viewConfiguration];
  }
}

- (RCLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
                          restrictedToSize:(const CKComponentSize &)size
                      relativeToParentSize:(CGSize)parentSize
{
  CKAssert(size == CKComponentSize(),
           @"CKRenderComponent only passes size {} to the super class initializer, but received size %@ "
           "(component=%@)", size.description(), _child);

  if (_child) {
    RCLayout l = [_child layoutThatFits:constrainedSize parentSize:parentSize];
    return {self, l.size, {{{0,0}, l}}};
  }
  return [super computeLayoutThatFits:constrainedSize restrictedToSize:size relativeToParentSize:parentSize];
}

- (CKComponent *)child
{
  return _child;
}

- (unsigned int)numberOfChildren
{
  return RCIterable::numberOfChildren(_child);
}

- (id<CKMountable>)childAtIndex:(unsigned int)index
{
  return RCIterable::childAtIndex(self, index, _child);
}

+ (id)initialState
{
  return CKTreeNodeEmptyState();
}

#pragma mark - CKRenderComponentProtocol

- (id)initialState
{
  return [self.class initialState];
}

- (BOOL)shouldComponentUpdate:(id<CKReusableComponentProtocol>)component
{
  return YES;
}

- (void)didReuseComponent:(id<CKRenderComponentProtocol>)component {}

- (CKComponentViewConfiguration)viewConfigurationWithState:(id)state
{
  return {};
}

- (id _Nullable)componentIdentifier
{
  return nil;
}

- (BOOL)requiresScopeHandle
{
  if ([self.class controllerClass] != nil) {
    return YES;
  }

  const Class componentClass = self.class;

  static CK::StaticMutex mutex = CK_MUTEX_INITIALIZER; // protects cache
  CK::StaticMutexLocker l(mutex);

  static std::unordered_map<Class, BOOL> *cache = new std::unordered_map<Class, BOOL>();
  auto it = cache->find(componentClass);
  if (it == cache->end()) {
    const BOOL requiresScopeHandle =
      CKSubclassOverridesInstanceMethod([CKRenderComponent class], componentClass, @selector(buildController)) ||
      CKSubclassOverridesInstanceMethod([CKRenderComponent class], componentClass, @selector(animationsFromPreviousComponent:)) ||
      CKSubclassOverridesInstanceMethod([CKRenderComponent class], componentClass, @selector(animationsOnInitialMount)) ||
      CKSubclassOverridesInstanceMethod([CKRenderComponent class], componentClass, @selector(animationsOnFinalUnmount));
    it = cache->insert({componentClass, requiresScopeHandle}).first;
  }
  const BOOL requiresScopeHandle = it->second;
  CKAssert(requiresScopeHandle ||
           (!self.hasAnimations && !self.hasInitialMountAnimations && !self.hasFinalUnmountAnimations),
           @"%@ changes the default logic of -has*Animations properties; Make sure to override -requiresScopeHandle "
           "and return YES when animations are present.",
           self);
  return requiresScopeHandle;
}

- (instancetype)clone
{
  // The default implementation returns `nil`, which indicates `clone` is not supported in this component.
  return nil;
}

@end
