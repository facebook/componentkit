/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponent.h"
#import "CKComponentControllerInternal.h"
#import "CKComponentInternal.h"
#import "CKComponentMemoizer.h"
#import "CKComponentSubclass.h"

#import <ComponentKit/CKArgumentPrecondition.h>
#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKMacros.h>

#import "CKAssert.h"
#import "CKComponentAccessibility.h"
#import "CKComponentAnimation.h"
#import "CKComponentController.h"
#import "CKComponentDebugController.h"
#import "CKComponentLayout.h"
#import "CKComponentScopeHandle.h"
#import "CKComponentViewConfiguration.h"
#import "CKComponentViewInterface.h"
#import "CKInternalHelpers.h"
#import "CKMountAnimationGuard.h"
#import "CKWeakObjectContainer.h"
#import "ComponentLayoutContext.h"

CGFloat const kCKComponentParentDimensionUndefined = NAN;
CGSize const kCKComponentParentSizeUndefined = {kCKComponentParentDimensionUndefined, kCKComponentParentDimensionUndefined};

struct CKComponentMountInfo {
  CKComponent *supercomponent;
  UIView *view;
  CKComponentViewContext viewContext;
};

@implementation CKComponent
{
  CKComponentScopeHandle *_scopeHandle;
  CKComponentViewConfiguration _viewConfiguration;
  CKComponentSize _size;

  /** Only non-null while mounted. */
  std::unique_ptr<CKComponentMountInfo> _mountInfo;
}

#if DEBUG
+ (void)initialize
{
  CKConditionalAssert(self != [CKComponent class],
                      !CKSubclassOverridesSelector([CKComponent class], self, @selector(layoutThatFits:parentSize:)),
                      @"%@ overrides -layoutThatFits:parentSize: which is not allowed. Override -computeLayoutThatFits: "
                      "or -computeLayoutThatFits:restrictedToSize:relativeToParentSize: instead.",
                      self);
}
#endif

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view size:(const CKComponentSize &)size
{
  return [[self alloc] initWithView:view size:size];
}

+ (instancetype)new
{
  return [self newWithView:{} size:{}];
}

- (instancetype)init
{
  CK_NOT_DESIGNATED_INITIALIZER();
}

- (instancetype)initWithView:(const CKComponentViewConfiguration &)view
                        size:(const CKComponentSize &)size
{
  if (self = [super init]) {
    _scopeHandle = [CKComponentScopeHandle handleForComponent:self];
    _viewConfiguration = view;
    _size = size;
  }
  return self;
}

- (void)dealloc
{
  // Since the component and its view hold strong references to each other, this should never happen!
  CKAssert(_mountInfo == nullptr, @"%@ must be unmounted before dealloc", [self class]);
}

- (const CKComponentViewConfiguration &)viewConfiguration
{
  return _viewConfiguration;
}

- (CKComponentViewContext)viewContext
{
  return _mountInfo ? _mountInfo->viewContext : CKComponentViewContext();
}

#pragma mark - Mounting and Unmounting

- (CK::Component::MountResult)mountInContext:(const CK::Component::MountContext &)context
                                        size:(const CGSize)size
                                    children:(std::shared_ptr<const std::vector<CKComponentLayoutChild>>)children
                              supercomponent:(CKComponent *)supercomponent
{
  // Taking a const ref to a temporary extends the lifetime of the temporary to the lifetime of the const ref
  const CKComponentViewConfiguration &viewConfiguration = CK::Component::Accessibility::IsAccessibilityEnabled() ? CK::Component::Accessibility::AccessibleViewConfiguration(_viewConfiguration) : _viewConfiguration;

  if (_mountInfo == nullptr) {
    _mountInfo.reset(new CKComponentMountInfo());
  }
  _mountInfo->supercomponent = supercomponent;

  CKComponentController *controller = _scopeHandle.controller;
  [controller componentWillMount:self];

  const CK::Component::MountContext &effectiveContext = [CKComponentDebugController debugMode]
  ? CKDebugMountContext([self class], context, _viewConfiguration, size) : context;

  UIView *v = effectiveContext.viewManager->viewForConfiguration([self class], viewConfiguration);
  if (v) {
    CKMountAnimationGuard g(v.ck_component, self, context);
    if (_mountInfo->view != v) {
      [self _relinquishMountedView]; // First release our old view
      [v.ck_component unmount];      // Then unmount old component (if any) from the new view
      v.ck_component = self;
      CK::Component::AttributeApplicator::apply(v, viewConfiguration);
      [controller component:self didAcquireView:v];
      _mountInfo->view = v;
    } else {
      CKAssert(v.ck_component == self, @"");
    }

    const CGPoint anchorPoint = v.layer.anchorPoint;
    [v setCenter:effectiveContext.position + CGPoint({size.width * anchorPoint.x, size.height * anchorPoint.y})];
    [v setBounds:{v.bounds.origin, size}];

    _mountInfo->viewContext = {v, {{0,0}, v.bounds.size}};
    return {.mountChildren = YES, .contextForChildren = effectiveContext.childContextForSubview(v, g.didBlockAnimations)};
  } else {
    CKAssertNil(_mountInfo->view, @"Didn't expect to sometimes have a view and sometimes not have a view");
    _mountInfo->viewContext = {effectiveContext.viewManager->view, {effectiveContext.position, size}};
    return {.mountChildren = YES, .contextForChildren = effectiveContext};
  }
}

- (void)unmount
{
  if (_mountInfo != nullptr) {
    [_scopeHandle.controller componentWillUnmount:self];
    [self _relinquishMountedView];
    _mountInfo.reset();
    [_scopeHandle.controller componentDidUnmount:self];
  }
}

- (void)_relinquishMountedView
{
  UIView *view = _mountInfo->view;
  if (view) {
    CKAssert(view.ck_component == self, @"");
    [_scopeHandle.controller component:self willRelinquishView:view];
    view.ck_component = nil;
    _mountInfo->view = nil;
  }
}

- (void)childrenDidMount
{
  [_scopeHandle.controller componentDidMount:self];
}

#pragma mark - Animation

- (std::vector<CKComponentAnimation>)animationsOnInitialMount
{
  return {};
}

- (std::vector<CKComponentAnimation>)animationsFromPreviousComponent:(CKComponent *)previousComponent
{
  return {};
}

- (CKComponentBoundsAnimation)boundsAnimationFromPreviousComponent:(CKComponent *)previousComponent
{
  return {};
}

- (UIView *)viewForAnimation
{
  return _mountInfo ? _mountInfo->view : nil;
}

#pragma mark - Layout

- (CKComponentLayout)layoutThatFits:(CKSizeRange)constrainedSize parentSize:(CGSize)parentSize
{
  CK::Component::LayoutContext context(self, constrainedSize);

  CKComponentLayout layout = CKMemoizeOrComputeLayout(self, constrainedSize, _size, parentSize);

  CKAssert(layout.component == self, @"Layout computed by %@ should return self as component, but returned %@",
           [self class], [layout.component class]);
  CKSizeRange resolvedRange = constrainedSize.intersect(_size.resolve(parentSize));
  CKAssert(layout.size.width <= resolvedRange.max.width
           && layout.size.width >= resolvedRange.min.width
           && layout.size.height <= resolvedRange.max.height
           && layout.size.height >= resolvedRange.min.height,
           @"Computed size %@ for %@ does not fall within constrained size %@\n%@",
           NSStringFromCGSize(layout.size), [self class], resolvedRange.description(),
           CK::Component::LayoutContext::currentStackDescription());
  return layout;
}

- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
                          restrictedToSize:(const CKComponentSize &)size
                      relativeToParentSize:(CGSize)parentSize
{
  CKSizeRange resolvedRange = constrainedSize.intersect(_size.resolve(parentSize));
  return [self computeLayoutThatFits:resolvedRange];
}

- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
{
  return {self, constrainedSize.min};
}

- (BOOL)shouldMemoizeLayout
{
  return NO;
}

#pragma mark - Responder

- (id)nextResponder
{
  return _scopeHandle.controller ?: [self nextResponderAfterController];
}

- (id)nextResponderAfterController
{
  return (_mountInfo ? _mountInfo->supercomponent : nil) ?: [self rootComponentMountedView];
}

- (id)targetForAction:(SEL)action withSender:(id)sender
{
  return [self canPerformAction:action withSender:sender] ? self : [[self nextResponder] targetForAction:action withSender:sender];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
  return [self respondsToSelector:action];
}

// Because only the root component in each mounted tree will have a non-nil rootComponentMountedView, we use Obj-C
// associated objects to save the memory overhead of storing such a pointer on every single CKComponent instance in
// the app. With tens of thousands of component instances, this adds up to several KB.
static void *kRootComponentMountedViewKey = &kRootComponentMountedViewKey;

- (void)setRootComponentMountedView:(UIView *)rootComponentMountedView
{
  ck_objc_setNonatomicAssociatedWeakObject(self, kRootComponentMountedViewKey, rootComponentMountedView);
}

- (UIView *)rootComponentMountedView
{
  return ck_objc_getAssociatedWeakObject(self, kRootComponentMountedViewKey);
}

#pragma mark - State

+ (id)initialState
{
  return nil;
}

- (void)updateState:(id (^)(id))updateBlock mode:(CKUpdateMode)mode
{
  CKAssertNotNil(_scopeHandle, @"A component without state cannot update its state.");
  CKAssertNotNil(updateBlock, @"Cannot enqueue component state modification with a nil block.");
  [_scopeHandle updateState:updateBlock mode:mode];
}

- (CKComponentController *)controller
{
  return _scopeHandle.controller;
}

- (id)scopeFrameToken
{
  return _scopeHandle ? @(_scopeHandle.globalIdentifier) : nil;
}

@end
