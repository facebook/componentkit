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

#import <ComponentKit/CKAnalyticsListener.h>
#import <RenderCore/RCAssert.h>
#import <ComponentKit/RCArgumentPrecondition.h>
#import <ComponentKit/CKBuildComponent.h>
#import <ComponentKit/CKComponentScopeEnumeratorProvider.h>
#import <ComponentKit/CKComponentContextHelper.h>
#import <ComponentKit/CKFatal.h>
#import <ComponentKit/CKInternalHelpers.h>
#import <ComponentKit/CKMacros.h>
#import <ComponentKit/CKTreeNode.h>
#import <ComponentKit/CKInternalHelpers.h>
#import <ComponentKit/CKWeakObjectContainer.h>
#import <ComponentKit/RCComponentDescriptionHelper.h>
#import <ComponentKit/CKMountableHelpers.h>
#import <ComponentKit/RCComponentSize_SwiftBridge+Internal.h>
#import <ComponentKit/CKComponentViewConfiguration_SwiftBridge+Internal.h>

#import "CKComponent+LayoutLifecycle.h"
#import "CKComponent+UIView.h"
#import "CKComponentAccessibility.h"
#import "CKAccessibilityAggregation.h"
#import "CKComponentAnimation.h"
#import "CKComponentController.h"
#import "CKComponentDebugController.h"
#import "CKComponentLayout.h"
#import "CKComponentScopeHandle.h"
#import "CKComponentViewConfiguration.h"
#import "CKMountAnimationGuard.h"
#import "ComponentLayoutContext.h"
#import "CKThreadLocalComponentScope.h"
#import "CKComponentScopeRoot.h"
#import "CKRenderHelpers.h"
#import "CKComponentCreationValidation.h"
#import "CKSizeAssert.h"

CGFloat const kCKComponentParentDimensionUndefined = NAN;
CGSize const kCKComponentParentSizeUndefined = {kCKComponentParentDimensionUndefined, kCKComponentParentDimensionUndefined};

@implementation CKComponent
{
  CKTreeNode *_treeNode;
  CKComponentViewConfiguration _viewConfiguration;

  /** Only non-null while mounted. */
  std::unique_ptr<CKMountInfo> _mountInfo;
}

#if DEBUG
+ (void)initialize
{
  if (self != [CKComponent class]) {
    RCAssert(!CKSubclassOverridesInstanceMethod([CKComponent class], self, @selector(layoutThatFits:parentSize:)),
             @"%@ overrides -layoutThatFits:parentSize: which is not allowed. Override -computeLayoutThatFits: "
             "or -computeLayoutThatFits:restrictedToSize:relativeToParentSize: instead.",
             self);
  }
}
#endif

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view size:(const RCComponentSize &)size
{
  return [[self alloc] initWithView:view size:size];
}

- (instancetype)init
{
  return [self initWithView:{} size:{}];
}

- (instancetype)initWithSwiftView:(CKComponentViewConfiguration_SwiftBridge *)swiftView
                        swiftSize:(RCComponentSize_SwiftBridge *)swiftSize
{
  const auto view = swiftView != nil ? swiftView.viewConfig : CKComponentViewConfiguration{};
  const auto size = swiftSize != nil ? swiftSize.componentSize : RCComponentSize{};
  return [self initWithView:view size:size];
}

- (instancetype)initWithView:(const CKComponentViewConfiguration &)view
                        size:(const RCComponentSize &)size
{
  if (self = [super init]) {
    _viewConfiguration = view;
    _size = size;

    [self didFinishComponentInitialization];
  }
  return self;
}

- (void)dealloc
{
  // Since the component and its view hold strong references to each other, this should never happen!
  RCAssert(_mountInfo == nullptr, @"%@ must be unmounted before dealloc", self.className);
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"<%s: %p>", self.typeName, self];
}

- (void)didFinishComponentInitialization
{
  CKValidateComponentCreation();
  _treeNode = CK::TreeNode::nodeForComponent(self);
}

- (BOOL)hasAnimations
{
  // NOTE: The default implementation is expected to be class-static. Check -[CKRenderComponent requiresScopeHandle] for more context.
  return CKSubclassOverridesInstanceMethod([CKComponent class], [self class], @selector(animationsFromPreviousComponent:));
}

- (BOOL)hasBoundsAnimations
{
  // NOTE: The default implementation is expected to be class-static. Check -[CKRenderComponent requiresScopeHandle] for more context.
  return CKSubclassOverridesInstanceMethod([CKComponent class], [self class], @selector(boundsAnimationFromPreviousComponent:));
}

- (BOOL)hasInitialMountAnimations
{
  // NOTE: The default implementation is expected to be class-static. Check -[CKRenderComponent requiresScopeHandle] for more context.
  return CKSubclassOverridesInstanceMethod([CKComponent class], [self class], @selector(animationsOnInitialMount));
}

- (BOOL)hasFinalUnmountAnimations
{
  // NOTE: The default implementation is expected to be class-static. Check -[CKRenderComponent requiresScopeHandle] for more context.
  return CKSubclassOverridesInstanceMethod([CKComponent class], [self class], @selector(animationsOnFinalUnmount));
}

- (BOOL)controllerOverridesDidPrepareLayout
{
  const Class<CKComponentControllerProtocol> controllerClass = [[self class] controllerClass];
  return CKSubclassOverridesInstanceMethod([CKComponentController class],
                                  controllerClass,
                                  @selector(didPrepareLayout:forComponent:));
}

- (id<CKComponentControllerProtocol>)buildController
{
  return [[(Class)[self.class controllerClass] alloc] initWithComponent:self];
}

- (const CKComponentViewConfiguration &)viewConfiguration
{
  return _viewConfiguration;
}

- (void)setViewConfiguration:(const CKComponentViewConfiguration &)viewConfiguration
{
  RCAssert(_viewConfiguration.isDefaultConfiguration(), @"Component(%@) already has '_viewConfiguration'.", self);
  _viewConfiguration = viewConfiguration;
}

- (CKComponentViewContext)viewContext
{
  RCAssertMainThread();
  return _mountInfo ? _mountInfo->viewContext : CKComponentViewContext();
}

- (void)acquireTreeNode:(CKTreeNode *)treeNode
{
  _treeNode = treeNode;
}

- (CKTreeNode *)treeNode
{
  return _treeNode;
}

#pragma mark - ComponentTree

- (void)buildComponentTree:(CKTreeNode *)parent
            previousParent:(CKTreeNode *_Nullable)previousParent
                    params:(const CKBuildComponentTreeParams &)params
      parentHasStateUpdate:(BOOL)parentHasStateUpdate
{
  CKRender::ComponentTree::Iterable::build(self, parent, previousParent, params, parentHasStateUpdate);
}

#pragma mark - Mounting and Unmounting

- (CK::Component::MountResult)mountInContext:(const CK::Component::MountContext &)context
                                      layout:(const RCLayout &)layout
                              supercomponent:(CKComponent *)supercomponent
{
  RCCAssertWithCategory([NSThread isMainThread], self.className, @"This method must be called on the main thread");

  // Taking a const ref to a temporary extends the lifetime of the temporary to the lifetime of the const ref
  const CKComponentViewConfiguration &viewConfiguration =
    (CK::Component::Accessibility::IsAccessibilityEnabled() || CKReadGlobalConfig().alwaysMountViewForAccessibityContextComponent)
    ? CK::Component::Accessibility::AccessibleViewConfiguration(_viewConfiguration)
    : _viewConfiguration;

  CKComponentController *controller = _treeNode.scopeHandle.controller;
  [controller componentWillMount:self];

  const CK::Component::MountContext &effectiveContext = [CKComponentDebugController debugMode]
  ? CKDebugMountContext([self class], context, _viewConfiguration, layout.size) : context;

  return CKPerformMount(_mountInfo, layout, viewConfiguration, effectiveContext, supercomponent, &didAcquireView, &willRelinquishView, &blockAnimationIfNeeded, &unblockAnimation);
}

__attribute__((objc_externally_retained)) // parameters are retained by the caller
static void didAcquireView(id<CKMountable> mountable, UIView *view)
{
  CKComponent *component = (CKComponent *)mountable;
  CKComponentController *controller = component.treeNode.scopeHandle.controller;
  [controller component:component didAcquireView:view];
}

__attribute__((objc_externally_retained)) // parameters are retained by the caller
static void willRelinquishView(id<CKMountable> mountable, UIView *view)
{
  CKComponent *component = (CKComponent *)mountable;
  [(CKComponentController *)component.treeNode.scopeHandle.controller component:component willRelinquishView:view];
}

- (NSString *)backtraceStackDescription
{
  return RCComponentBacktraceStackDescription(RCComponentGenerateBacktrace(self));
}

- (void)unmount
{
  RCAssertMainThread();
  if (_mountInfo != nullptr) {
    CKComponentController *const controller = _treeNode.scopeHandle.controller;
    [controller componentWillUnmount:self];
    CKPerformUnmount(_mountInfo, self, &willRelinquishView);
    [controller componentDidUnmount:self];
  }
}

- (void)childrenDidMount
{
  [(CKComponentController *)_treeNode.scopeHandle.controller componentDidMount:self];
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
  RCAssertMainThread();
  return _mountInfo ? _mountInfo->view : nil;
}

__attribute__((objc_externally_retained)) // parameters are retained by the caller
static BOOL blockAnimationIfNeeded(id<CKMountable> oldComponent, id<CKMountable> newComponent, const CK::Component::MountContext &ctx, const CKViewConfiguration &viewConfig)
{
  return CKMountAnimationGuard::blockAnimationsIfNeeded(oldComponent, newComponent, ctx, viewConfig);
}

__attribute__((objc_externally_retained)) // parameters are retained by the caller
static void unblockAnimation()
{
  CKMountAnimationGuard::unblockAnimation();
}

#pragma mark - Layout

#if CK_ASSERTIONS_ENABLED

- (void)_validate_layoutThatFits:(const CKSizeRange &)constrainedSize layout:(const RCLayout &)layout parentSize:(const CGSize &)parentSize
{
  // If this component has children in its layout, this means that it's not a real leaf component.
  // As a result, the infrastructure won't call `buildComponentTree:` on the component's children and can affect the render process.
  if (self.superclass == [CKComponent class] && layout.children != nullptr && layout.children->size() > 0) {
    const auto overridesIterableMethods =
    CKSubclassOverridesInstanceMethod([CKComponent class], self.class, @selector(childAtIndex:)) &&
    CKSubclassOverridesInstanceMethod([CKComponent class], self.class, @selector(numberOfChildren));
    RCAssertWithCategory(overridesIterableMethods,
                         self.className,
                         @"%@ is subclassing CKComponent directly, you need to subclass CKLayoutComponent instead. "
                         "Context: we’re phasing out CKComponent subclasses for in favor of CKLayoutComponent subclasses. "
                         "While this is still kinda OK for leaf components, things start to break when you introduce a CKComponent subclass with children.",
                         self.className);
  }

  RCAssert(layout.component == self, @"Layout computed by %@ should return self as component, but returned %@",
           self.className, layout.component.className);

  CKAssertResolvedSize(_size, parentSize);
  CKSizeRange resolvedRange __attribute__((unused)) = constrainedSize.intersect(_size.resolve(parentSize));
  CKAssertSizeRange(resolvedRange);
  RCAssertWithCategory(CKIsGreaterThanOrEqualWithTolerance(resolvedRange.max.width, layout.size.width)
                       && CKIsGreaterThanOrEqualWithTolerance(layout.size.width, resolvedRange.min.width)
                       && CKIsGreaterThanOrEqualWithTolerance(resolvedRange.max.height,layout.size.height)
                       && CKIsGreaterThanOrEqualWithTolerance(layout.size.height,resolvedRange.min.height),
                       self.className,
                       @"Computed size %@ for %@ does not fall within constrained size %@\n%@",
                       NSStringFromCGSize(layout.size), self.className, resolvedRange.description(),
                       CK::Component::LayoutContext::currentStackDescription());
}

#endif

__attribute__((objc_externally_retained)) // parameters are retained by the caller
void CKComponentWillLayout(CKComponent *component, CKSizeRange constrainedSize, CGSize parentSize, id<CKSystraceListener> systraceListener)
{
  CKAssertSizeRange(constrainedSize);
  [systraceListener willLayoutComponent:component];
}

- (RCLayout)layoutThatFits:(CKSizeRange)constrainedSize parentSize:(CGSize)parentSize
{
#if CK_ASSERTIONS_ENABLED
  const CKComponentContext<CKComponentCreationValidationContext> validationContext([[CKComponentCreationValidationContext alloc] initWithSource:CKComponentCreationValidationSourceLayout]);
#endif
  
  CK::Component::LayoutContext context(self, constrainedSize);
  auto const systraceListener = context.systraceListener;
  CKComponentWillLayout(self, constrainedSize, parentSize, systraceListener);
  
  RCLayout layout = [self computeLayoutThatFits:constrainedSize
                               restrictedToSize:_size
                           relativeToParentSize:parentSize];
  
  CKComponentDidLayout(self, layout, constrainedSize, parentSize, systraceListener);
  
  return layout;
}

__attribute__((objc_externally_retained)) // parameters are retained by the caller
void CKComponentDidLayout(CKComponent *component, const RCLayout &layout, CKSizeRange constrainedSize, CGSize parentSize, id<CKSystraceListener> systraceListener)
{
#if CK_ASSERTIONS_ENABLED
  [component _validate_layoutThatFits:constrainedSize layout:layout parentSize:parentSize];
#endif
  [systraceListener didLayoutComponent:component];
}

- (RCLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
                          restrictedToSize:(const RCComponentSize &)size
                      relativeToParentSize:(CGSize)parentSize
{
  CKAssertResolvedSize(_size, parentSize);
  CKSizeRange resolvedRange = constrainedSize.intersect(_size.resolve(parentSize));
  return [self computeLayoutThatFits:resolvedRange];
}

- (RCLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
{
  return {self, constrainedSize.min};
}

#pragma mark - Responder

- (id)nextResponder
{
  return _treeNode.scopeHandle.controller ?: [self nextResponderAfterController];
}

- (id)nextResponderAfterController
{
  RCAssertMainThread();
  if (_mountInfo && _mountInfo->supercomponent) {
    return _mountInfo->supercomponent;
  }
  return [self rootComponentMountedView];
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

#pragma mark - CKMountable

- (unsigned int)numberOfChildren
{
  return 0;
}

- (id<CKMountable>)childAtIndex:(unsigned int)index
{
  return nil;
}

#pragma mark - CKComponentProtocol

+ (RCComponentCoalescingMode)coalescingMode {
  return RCComponentCoalescingModeNone;
}

+ (Class<CKComponentControllerProtocol>)controllerClass
{
  const Class componentClass = self;

  if (componentClass == [CKComponent class]) {
    return Nil; // Don't create root CKComponentControllers as it does nothing interesting.
  }

  RCAssertWithCategory(!NSClassFromString([NSStringFromClass(componentClass) stringByAppendingString:@"Controller"]),
                       [self class], @"Should override + (Class<CKComponentControllerProtocol>)controllerClass to return its controllerClass");
  return Nil;
}

+ (id)initialState
{
  return nil;
}

#pragma mark - State

- (void)updateState:(id (^)(id))updateBlock mode:(CKUpdateMode)mode
{
  RCAssertWithCategory(_treeNode.scopeHandle != nil, self.className, @"A component without state cannot update its state.");
  RCAssertWithCategory(updateBlock != nil, self.className, @"Cannot enqueue component state modification with a nil update block.");
  [_treeNode.scopeHandle updateState:updateBlock metadata:{} mode:mode];
}

- (CKComponentController *)controller
{
  return _treeNode.scopeHandle.controller;
}

- (id<NSObject>)uniqueIdentifier
{
  return _treeNode ? @(_treeNode.scopeHandle.globalIdentifier) : nil;
}

-(id<CKComponentScopeEnumeratorProvider>)scopeEnumeratorProvider
{
  CKThreadLocalComponentScope *currentScope = CKThreadLocalComponentScope::currentScope();
  if (currentScope == nullptr) {
    return nil;
  }

  return currentScope->newScopeRoot;
}

- (UIView *)mountedView
{
  return _mountInfo ? _mountInfo->view : nil;
}

- (CKMountInfo)mountInfo
{
  if (_mountInfo) {
    return *_mountInfo.get();
  }
  return {};
}

- (id)state
{
  return _treeNode.scopeHandle.state;
}

- (NSString *)className
{
  return [NSString stringWithUTF8String:self.typeName];
}

- (const char *)typeName
{
  // Coalesced component require their type names to differ from their class names.
  // https://fburl.com/codesearch/tjepeywh
  return class_getName(self.class);
}

- (NSDictionary<NSString *, id> *)metadata
{
  return nil;
}

// This method can be used to override what accessible elements are
// provided by the component. Very similar to UIKit accessibilityElements.
#pragma mark - Accessibility

- (NSArray<NSObject *> *)accessibilityChildren
{
  const auto numChildren = [self numberOfChildren];
  if (numChildren == 0) {
    return nil;
  }
  NSMutableArray *const contents = [NSMutableArray arrayWithCapacity:numChildren];
  for(unsigned int i = 0; i < numChildren; i++) {
    const auto child = [self childAtIndex:i];
    if (child != nil) {
      [contents addObject:child];
    }
  }

  return contents;
}

- (CGRect)accessibilityFrame {
  if (_mountInfo == nullptr) {
    return CGRectNull;
  }
  return UIAccessibilityConvertFrameToScreenCoordinates(_mountInfo->viewContext.frame, _mountInfo->viewContext.view);
}

- (void)setAccessibilityElements:(NSArray *)accessibilityElements {
  RCFailAssert(@"Attempt to setAccessibilityElements in %@", NSStringFromClass([self class]));
}

// In base Component we rely on the view to provide the accessible elements:
// If the component itself has isAccessibilityElement == NO and
// 1) It has a mounted view that has accessibilityElements
// 2) It has a mounted view that is an accessibile element
- (NSArray<NSObject *> *)accessibilityElements
{
  const auto mountedView = self.mountedView;
  if ([[mountedView accessibilityElements] count] > 0
      || [mountedView accessibilityElementCount] > 0
      || [mountedView isAccessibilityElement]) {
    if ([mountedView isAccessibilityElement]) {
      return @[self.mountedView];
    } else if (![mountedView isAccessibilityElement] && CKAccessibilityAggregationIsActive()) {
      return [self accessibilityChildren];
    } else {
      return @[self.mountedView];
    }
  }
  return [self accessibilityChildren];
}

@end
