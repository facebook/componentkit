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
#import "CKComponentSubclass.h"

#import <ComponentKit/CKArgumentPrecondition.h>
#import <ComponentKit/CKComponentScopeEnumeratorProvider.h>
#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKBuildComponent.h>
#import <ComponentKit/CKComponentContextHelper.h>
#import <ComponentKit/CKInternalHelpers.h>
#import <ComponentKit/CKMacros.h>
#import <ComponentKit/CKMutex.h>

#import "CKAssert.h"
#import "CKComponent+UIView.h"
#import "CKComponentAccessibility.h"
#import "CKComponentAnimation.h"
#import "CKComponentController.h"
#import "CKComponentDebugController.h"
#import "CKComponentDescriptionHelper.h"
#import "CKComponentLayout.h"
#import "CKComponentScopeHandle.h"
#import "CKComponentViewConfiguration.h"
#import "CKInternalHelpers.h"
#import "CKMountAnimationGuard.h"
#import "CKWeakObjectContainer.h"
#import "ComponentLayoutContext.h"
#import "CKThreadLocalComponentScope.h"
#import "CKComponentScopeRoot.h"
#import "CKRenderHelpers.h"
#import "CKComponentCreationValidation.h"

CGFloat const kCKComponentParentDimensionUndefined = NAN;
CGSize const kCKComponentParentSizeUndefined = {kCKComponentParentDimensionUndefined, kCKComponentParentDimensionUndefined};

struct CKComponentMountInfo {
  CKComponent *supercomponent;
  UIView *view;
  CKComponentViewContext viewContext;
};

@implementation CKComponent
{
  CKComponentScopeHandle<CKComponentController *> *_scopeHandle;
  CKComponentViewConfiguration _viewConfiguration;

  /** Only non-null while mounted. */
  std::unique_ptr<CKComponentMountInfo> _mountInfo;

#if DEBUG
  __weak id<CKTreeNodeProtocol> _treeNode;
#endif

#if CK_ASSERTIONS_ENABLED
  BOOL leafComponentOnARenderTree;
#endif
}

#if DEBUG
+ (void)initialize
{
  if (self != [CKComponent class]) {
    CKAssert(!CKSubclassOverridesInstanceMethod([CKComponent class], self, @selector(layoutThatFits:parentSize:)),
             @"%@ overrides -layoutThatFits:parentSize: which is not allowed. Override -computeLayoutThatFits: "
             "or -computeLayoutThatFits:restrictedToSize:relativeToParentSize: instead.",
             self);
  }
}
#endif

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view size:(const CKComponentSize &)size
{
  return [[self alloc] initWithView:view size:size];
}

+ (instancetype)newRenderComponentWithView:(const CKComponentViewConfiguration &)view
                                      size:(const CKComponentSize &)size
{
  return [[self alloc] initRenderComponentWithView:view size:size];
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
    CKValidateComponentCreation();
    _scopeHandle = [CKComponentScopeHandle handleForComponent:self];
    _viewConfiguration = view;
    _size = size;
  }
  return self;
}

- (instancetype)initRenderComponentWithView:(const CKComponentViewConfiguration &)view
                                       size:(const CKComponentSize &)size
{
  if (self = [super init]) {
    CKValidateComponentCreation();
    // Mark render component in the scope root.
    CKThreadLocalComponentScope::markCurrentScopeWithRenderComponentInTree();
    CKComponentContextHelper::didCreateRenderComponent(self);
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

- (void)acquireScopeHandle:(CKComponentScopeHandle *)scopeHandle
{
  CKAssert(_scopeHandle == nil, @"Component(%@) already has '_scopeHandle'.", self);
  [scopeHandle forceAcquireFromComponent:self];
  _scopeHandle = scopeHandle;
}

- (const CKComponentViewConfiguration &)viewConfiguration
{
  return _viewConfiguration;
}

- (void)setViewConfiguration:(const CKComponentViewConfiguration &)viewConfiguration
{
  CKAssert(_viewConfiguration.isDefaultConfiguration(), @"Component(%@) already has '_viewConfiguration'.", self);
  _viewConfiguration = viewConfiguration;
}

- (CKComponentViewContext)viewContext
{
  CKAssertMainThread();
  return _mountInfo ? _mountInfo->viewContext : CKComponentViewContext();
}

#if DEBUG
// These two methods are in DEBUG only in order to save memory.
// Once we build the component tree (by calling `buildComponentTree:`) by default,
// we can swap the the scopeHandle ref with the treeNode one.
- (void)acquireTreeNode:(id<CKTreeNodeProtocol>)treeNode
{
  _treeNode = treeNode;
}

- (id<CKTreeNodeProtocol>)treeNode
{
  return _treeNode;
}
#endif

#pragma mark - ComponentTree

- (void)buildComponentTree:(id<CKTreeNodeWithChildrenProtocol>)parent
            previousParent:(id<CKTreeNodeWithChildrenProtocol>)previousParent
                    params:(const CKBuildComponentTreeParams &)params
      parentHasStateUpdate:(BOOL)parentHasStateUpdate
{
#if CK_ASSERTIONS_ENABLED
  leafComponentOnARenderTree = YES;
#endif
  // In this case this is a leaf component, which means we don't need to continue the recursion as it has no children.
  CKRender::buildComponentTreeForLeafComponent(self, parent, previousParent, params);
}

#pragma mark - Mounting and Unmounting

- (CK::Component::MountResult)mountInContext:(const CK::Component::MountContext &)context
                                        size:(const CGSize)size
                                    children:(std::shared_ptr<const std::vector<CKComponentLayoutChild>>)children
                              supercomponent:(CKComponent *)supercomponent
                            systraceListener:(id<CKSystraceListener>)systraceListener
{
  CKCAssertWithCategory([NSThread isMainThread], [self class], @"This method must be called on the main thread");

  [systraceListener willMountComponent:self];

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
    CKComponent *currentMountedComponent = CKMountedComponentForView(v);
    CKMountAnimationGuard g(currentMountedComponent, self, context, _viewConfiguration);
    if (_mountInfo->view != v) {
      [self _relinquishMountedView];     // First release our old view
      [currentMountedComponent unmount]; // Then unmount old component (if any) from the new view
      CKSetMountedComponentForView(v, self);
      CK::Component::AttributeApplicator::apply(v, viewConfiguration);
      [controller component:self didAcquireView:v];
      _mountInfo->view = v;
    } else {
      CKAssert(currentMountedComponent == self, @"");
    }

    @try {
      const CGPoint anchorPoint = v.layer.anchorPoint;
      [v setCenter:effectiveContext.position + CGPoint({size.width * anchorPoint.x, size.height * anchorPoint.y})];
      [v setBounds:{v.bounds.origin, size}];
    } @catch (NSException *exception) {
      NSString *const componentBacktraceDescription =
        CKComponentBacktraceDescription(generateComponentBacktrace(supercomponent));
      NSString *const componentChildrenDescription = CKComponentChildrenDescription(children);
      [NSException raise:exception.name
                  format:@"%@ raised %@ during mount: %@\n backtrace:%@ children:%@", [self class], exception.name, exception.reason, componentBacktraceDescription, componentChildrenDescription];
    }

    _mountInfo->viewContext = {v, {{0,0}, v.bounds.size}};

    return {.mountChildren = YES, .contextForChildren = effectiveContext.childContextForSubview(v, g.didBlockAnimations)};
  } else {
    CKCAssertWithCategory(_mountInfo->view == nil, [self class],
                          @"%@ should not have a mounted %@ after previously being mounted without a view.\n%@",
                          [self class], [_mountInfo->view class], CKComponentBacktraceDescription(generateComponentBacktrace(self)));
    _mountInfo->viewContext = {effectiveContext.viewManager->view, {effectiveContext.position, size}};

    return {.mountChildren = YES, .contextForChildren = effectiveContext};
  }
}

- (NSString *)backtraceStackDescription
{
  return CKComponentBacktraceStackDescription(generateComponentBacktrace(self));
}

- (void)unmount
{
  CKAssertMainThread();
  if (_mountInfo != nullptr) {
    CKComponentController *const controller = _scopeHandle.controller;
    [controller componentWillUnmount:self];
    [self _relinquishMountedView];
    _mountInfo.reset();
    [controller componentDidUnmount:self];
  }
}

- (void)_relinquishMountedView
{
  CKAssertMainThread();
  CKAssert(_mountInfo != nullptr, @"_mountInfo should not be null");
  if (_mountInfo != nullptr) {
    UIView *view = _mountInfo->view;
    if (view) {
      CKAssert(CKMountedComponentForView(view) == self, @"");
      [_scopeHandle.controller component:self willRelinquishView:view];
      CKSetMountedComponentForView(view, nil);
      _mountInfo->view = nil;
    }
  }
}

- (void)childrenDidMount:(id<CKSystraceListener>)systraceListener
{
  [_scopeHandle.controller componentDidMount:self];
  [systraceListener didMountComponent:self];
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

- (std::vector<CKComponentFinalUnmountAnimation>)animationsOnFinalUnmount
{
  return {};
}

- (UIView *)viewForAnimation
{
  CKAssertMainThread();
  return _mountInfo ? _mountInfo->view : nil;
}

#pragma mark - Layout

- (CKComponentLayout)layoutThatFits:(CKSizeRange)constrainedSize parentSize:(CGSize)parentSize
{
  CK::Component::LayoutContext context(self, constrainedSize);
  auto const systraceListener = context.systraceListener;
  [systraceListener willLayoutComponent:self];

  CKComponentLayout layout = [self computeLayoutThatFits:constrainedSize
                                        restrictedToSize:_size
                                    relativeToParentSize:parentSize];

#if CK_ASSERTIONS_ENABLED
  // If `leafComponentOnARenderTree` is true, the infrastructure treats this component as a leaf component.
  // If this component has children in its layout, this means that it's not a real leaf component.
  // As a result, the infrastructure won't call `buildComponentTree:` on the component's children and can affect the render process.
  if (leafComponentOnARenderTree && layout.children != nullptr) {
    auto const childrenSize = layout.children->size();
    CKAssertWithCategory(childrenSize == 0,
                         NSStringFromClass([self class]),
                         @"%@ is subclassing CKComponent directly, you need to subclass %@ instead. "
                         "Context: we’re phasing out CKComponent subclasses for in favor of CKRenderLayoutComponent/CKRenderLayoutWithChildrenComponent subclasses. "
                         "While this is still kinda OK for leaf components, things start to break when you introduce a CKComponent subclass with children.",
                         [self class],
                         (childrenSize == 1 ? @"CKRenderLayoutComponent" : @"CKRenderLayoutWithChildrenComponent"));
  }
#endif

  CKAssert(layout.component == self, @"Layout computed by %@ should return self as component, but returned %@",
           [self class], [layout.component class]);
  CKSizeRange resolvedRange __attribute__((unused)) = constrainedSize.intersect(_size.resolve(parentSize));
  CKAssertWithCategory(CKIsGreaterThanOrEqualWithTolerance(resolvedRange.max.width, layout.size.width)
                       && CKIsGreaterThanOrEqualWithTolerance(layout.size.width, resolvedRange.min.width)
                       && CKIsGreaterThanOrEqualWithTolerance(resolvedRange.max.height,layout.size.height)
                       && CKIsGreaterThanOrEqualWithTolerance(layout.size.height,resolvedRange.min.height),
                       NSStringFromClass([self class]),
                       @"Computed size %@ for %@ does not fall within constrained size %@\n%@",
                       NSStringFromCGSize(layout.size), [self class], resolvedRange.description(),
                       CK::Component::LayoutContext::currentStackDescription());

  [systraceListener didLayoutComponent:self];

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

#pragma mark - Responder

- (id)nextResponder
{
  return _scopeHandle.controller ?: [self nextResponderAfterController];
}

- (id)nextResponderAfterController
{
  CKAssertMainThread();
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

#pragma mark - CKComponentProtocol

+ (Class<CKComponentControllerProtocol>)controllerClass
{
  const Class componentClass = self;

  if (componentClass == [CKComponent class]) {
    return Nil; // Don't create root CKComponentControllers as it does nothing interesting.
  }

  CKAssertWithCategory(!NSClassFromString([NSStringFromClass(componentClass) stringByAppendingString:@"Controller"]),
                       NSStringFromClass([self class]), @"Should override + (Class<CKComponentControllerProtocol>)controllerClass to return its controllerClass");
  return Nil;
}

+ (id)initialState
{
  return nil;
}

+ (BOOL)requiresScopeHandle
{
  const Class componentClass = self;

  static CK::StaticMutex mutex = CK_MUTEX_INITIALIZER; // protects cache
  CK::StaticMutexLocker l(mutex);

  static std::unordered_map<Class, BOOL> *cache = new std::unordered_map<Class, BOOL>();
  const auto &it = cache->find(componentClass);
  if (it == cache->end()) {
    BOOL hasAnimations = NO;
    if (CKSubclassOverridesInstanceMethod([CKComponent class], componentClass, @selector(animationsFromPreviousComponent:)) ||
        CKSubclassOverridesInstanceMethod([CKComponent class], componentClass, @selector(animationsOnInitialMount)) ||
        CKSubclassOverridesInstanceMethod([CKComponent class], componentClass, @selector(animationsOnFinalUnmount))) {
      hasAnimations = YES;
    }
    cache->insert({componentClass, hasAnimations});
    return hasAnimations;
  }
  return it->second;
}

#pragma mark - State

- (void)updateState:(id (^)(id))updateBlock mode:(CKUpdateMode)mode
{
  CKAssertNotNil(_scopeHandle, @"A component without state cannot update its state.");
  CKAssertNotNil(updateBlock, @"Cannot enqueue component state modification with a nil update block.");
  [_scopeHandle updateState:updateBlock metadata:{} mode:mode];
}

- (CKComponentController *)controller
{
  return _scopeHandle.controller;
}

- (id<NSObject>)scopeFrameToken
{
  return _scopeHandle ? @(_scopeHandle.globalIdentifier) : nil;
}

-(id<CKComponentScopeEnumeratorProvider>)scopeEnumeratorProvider
{
  CKThreadLocalComponentScope *currentScope = CKThreadLocalComponentScope::currentScope();
  if (currentScope == nullptr) {
    return nil;
  }

  return currentScope->newScopeRoot;
}

static NSArray<CKComponent *> *generateComponentBacktrace(CKComponent *component)
{
  NSMutableArray<CKComponent *> *const componentBacktrace = [NSMutableArray arrayWithObject:component];
  while ([componentBacktrace lastObject]
         && [componentBacktrace lastObject]->_mountInfo
         && [componentBacktrace lastObject]->_mountInfo->supercomponent) {
    [componentBacktrace addObject:[componentBacktrace lastObject]->_mountInfo->supercomponent];
  }
  return componentBacktrace;
}

- (UIView *)mountedView
{
  return _mountInfo ? _mountInfo->view : nil;
}

@end
