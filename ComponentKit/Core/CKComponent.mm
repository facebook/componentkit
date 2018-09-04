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
#import "CKTreeNode.h"

CGFloat const kCKComponentParentDimensionUndefined = NAN;
CGSize const kCKComponentParentSizeUndefined = {kCKComponentParentDimensionUndefined, kCKComponentParentDimensionUndefined};

struct CKComponentMountInfo {
  CKComponent *supercomponent;
  UIView *view;
  CKComponentViewContext viewContext;
  BOOL componentOrAncestorHasScopeConflict;
};

@implementation CKComponent
{
  CKComponentScopeHandle<CKComponentController *> *_scopeHandle;
  CKComponentViewConfiguration _viewConfiguration;

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

+ (instancetype)newRenderComponentWithView:(const CKComponentViewConfiguration &)view
                                      size:(const CKComponentSize &)size
                         isLayoutComponent:(BOOL)isLayoutComponent
{
  return [[self alloc] initRenderComponentWithView:view size:size isLayoutComponent:isLayoutComponent];
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

- (instancetype)initRenderComponentWithView:(const CKComponentViewConfiguration &)view
                                       size:(const CKComponentSize &)size
                          isLayoutComponent:(BOOL)isLayoutComponent
{
  if (self = [super init]) {
    _viewConfiguration = view;
    _size = size;

    // Mark render component in the scope root, but only in case that it's not a layout component.
    // We converted layout components (such as CKFlexboxComponent, CKInsetComponent etc.) to be a CKRenderComponentProtocol
    // in order to support mix and match of CKCompositeComponents/CKComponent and CKRenderComponentProtocol components.
    // We will build a component tree (CKTreeNode) only in case that we have a render component in the tree.
    if (!isLayoutComponent) {
      CKThreadLocalComponentScope *currentScope = CKThreadLocalComponentScope::currentScope();
      if (currentScope != nullptr) {
        currentScope->newScopeRoot.hasRenderComponentInTree = YES;
      }
    }
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

- (CKComponentViewContext)viewContext
{
  CKAssertMainThread();
  return _mountInfo ? _mountInfo->viewContext : CKComponentViewContext();
}

#pragma mark - ComponentTree

- (void)buildComponentTree:(id<CKTreeNodeWithChildrenProtocol>)parent
            previousParent:(id<CKTreeNodeWithChildrenProtocol>)previousParent
                    params:(const CKBuildComponentTreeParams &)params
                    config:(const CKBuildComponentConfig &)config
            hasDirtyParent:(BOOL)hasDirtyParent
{
  // In this case this is a leaf component, which means we don't need to continue the recursion as it has no children.
  __unused auto const node = [[CKTreeNode alloc]
                              initWithComponent:self
                              parent:parent
                              previousParent:previousParent
                              scopeRoot:params.scopeRoot
                              stateUpdates:params.stateUpdates];
}

#pragma mark - Mounting and Unmounting

- (CK::Component::MountResult)mountInContext:(const CK::Component::MountContext &)context
                                        size:(const CGSize)size
                                    children:(std::shared_ptr<const std::vector<CKComponentLayoutChild>>)children
                              supercomponent:(CKComponent *)supercomponent
{
  CKCAssertWithCategory([NSThread isMainThread], [self class], @"This method must be called on the main thread");
  // Taking a const ref to a temporary extends the lifetime of the temporary to the lifetime of the const ref
  const CKComponentViewConfiguration &viewConfiguration = CK::Component::Accessibility::IsAccessibilityEnabled() ? CK::Component::Accessibility::AccessibleViewConfiguration(_viewConfiguration) : _viewConfiguration;

  if (_mountInfo == nullptr) {
    _mountInfo.reset(new CKComponentMountInfo());
  }
  _mountInfo->supercomponent = supercomponent;
  _mountInfo->componentOrAncestorHasScopeConflict = context.componentOrAncestorHasScopeConflict;

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
      CKAssert(view.ck_component == self, @"");
      [_scopeHandle.controller component:self willRelinquishView:view];
      view.ck_component = nil;
      _mountInfo->view = nil;
    }
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

  CKComponentLayout layout = [self computeLayoutThatFits:constrainedSize
                                        restrictedToSize:_size
                                    relativeToParentSize:parentSize];

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

  static CK::StaticMutex mutex = CK_MUTEX_INITIALIZER; // protects cache
  CK::StaticMutexLocker l(mutex);

  static std::unordered_map<Class, Class> *cache = new std::unordered_map<Class, Class>();
  const auto &it = cache->find(componentClass);
  if (it == cache->end()) {
    Class c = nil;
    // If you override animationsFromPreviousComponent: or animationsOnInitialMount and if context permits
    // then we need a controller
    const auto ctx = CKComponentContext<CKComponentControllerContext>::get();
    const auto handleAnimationsInController = (ctx == nil) ? YES : ctx.handleAnimationsInController;
    if (handleAnimationsInController &&
        (CKSubclassOverridesSelector([CKComponent class], componentClass, @selector(animationsFromPreviousComponent:)) ||
         CKSubclassOverridesSelector([CKComponent class], componentClass, @selector(animationsOnInitialMount)))) {
          c = [CKComponentController class];
        }
    cache->insert({componentClass, c});

    CKAssertWithCategory(!(c == nil && NSClassFromString([NSStringFromClass(componentClass) stringByAppendingString:@"Controller"])),
                         NSStringFromClass([self class]), @"Should override + (Class<CKComponentControllerProtocol>)controllerClass to return its controllerClass");

    return c;
  }
  return it->second;
}

+ (id)initialState
{
  return nil;
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

- (BOOL)componentOrAncestorHasScopeConflict
{
  return _mountInfo ? _mountInfo->componentOrAncestorHasScopeConflict : NO;
}

- (UIView *)mountedView
{
  return _mountInfo ? _mountInfo->view : nil;
}

@end
