/*
*  Copyright (c) 2014-present, Facebook, Inc.
*  All rights reserved.
*
*  This source code is licensed under the BSD-style license found in the
*  LICENSE file in the root directory of this source tree. An additional grant
*  of patent rights can be found in the PATENTS file in the same directory.
*
*/

#import "CKMountableComponent.h"

#import <ComponentKit/CKMountedObjectForView.h>
#import <ComponentKit/CKWeakObjectContainer.h>

#import "CKComponentDescriptionHelper.h"
#import "CKLayout.h"
#import "CKMountableHelpers.h"

@implementation CKMountableComponent
{
  CKMountableViewConfiguration _viewConfiguration;
  CK::Optional<CKComponentSize> _size;
  /** Only non-null while mounted. */
  std::unique_ptr<CKMountInfo> _mountInfo;
}

+ (instancetype)new
{
  return [self newWithView:{} size:{}];
}

+ (instancetype)newWithView:(const CKMountableViewConfiguration &)view size:(const CKComponentSize &)size
{
  auto const c = [super new];
  if (c) {
    c->_viewConfiguration = view;
    c->_size = size;
  }
  return c;
}

- (CKComponentLayout)layoutThatFits:(CKSizeRange)constrainedSize
                         parentSize:(CGSize)parentSize
{
  CKSizeRange resolvedRange = constrainedSize.intersect(_size.valueOr({}).resolve(parentSize));
  return {self, resolvedRange.min};
}

- (CKComponentViewContext)viewContext
{
  CKAssertMainThread();
  return _mountInfo ? _mountInfo->viewContext : CKComponentViewContext();
}

- (void)setViewConfiguration:(const CKMountableViewConfiguration &)viewConfiguration
{
  CKAssert(_viewConfiguration.isDefaultConfiguration(), @"Component(%@) already has '_viewConfiguration'.", self);
  _viewConfiguration = viewConfiguration;
}

- (CKComponentSize)size
{
  return _size.valueOr({});
}

- (void)setSize:(const CKComponentSize &)size
{
  CKAssert(!_size.hasValue(), @"Component(%@) already has '_size'.", self);
  _size = size;
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

- (UIView *)mountedView
{
  return _mountInfo ? _mountInfo->view : nil;
}

#pragma mark - Mount

- (CK::Component::MountResult)mountInContext:(const CK::Component::MountContext &)context
                                        size:(const CGSize)size
                                    children:(std::shared_ptr<const std::vector<CKComponentLayoutChild> >)children
                              supercomponent:(id<CKMountable>)supercomponent
{
  CKCAssertWithCategory([NSThread isMainThread], [self class], @"This method must be called on the main thread");

  if (_mountInfo == nullptr) {
    _mountInfo.reset(new CKMountInfo());
  }
  _mountInfo->supercomponent = supercomponent;

  UIView *v = context.viewManager->viewForConfiguration([self class], _viewConfiguration);
  if (v) {
    auto const currentMountedComponent = (CKMountableComponent *)CKMountedObjectForView(v);
    if (_mountInfo->view != v) {
      [self _relinquishMountedView];     // First release our old view
      [currentMountedComponent unmount]; // Then unmount old component (if any) from the new view
      CKSetMountedObjectForView(v, self);
      CK::Component::AttributeApplicator::apply(v, _viewConfiguration);
      _mountInfo->view = v;
    } else {
      CKAssert(currentMountedComponent == self, @"");
    }

    CKSetViewPositionAndBounds(v, context, size, children, supercomponent, [self class]);
    _mountInfo->viewContext = {v, {{0,0}, v.bounds.size}};
    return {.mountChildren = YES, .contextForChildren = context.childContextForSubview(v, NO)};
  } else {
    CKCAssertWithCategory(_mountInfo->view == nil, [self class],
                          @"%@ should not have a mounted %@ after previously being mounted without a view.\n%@",
                          [self class], [_mountInfo->view class], CKComponentBacktraceDescription(CKComponentGenerateBacktrace(self)));
    _mountInfo->viewContext = {context.viewManager->view, {context.position, size}};
    return {.mountChildren = YES, .contextForChildren = context};
  }
}

- (void)unmount
{
  CKAssertMainThread();
  if (_mountInfo != nullptr) {
    [self _relinquishMountedView];
    _mountInfo.reset();
  }
}

- (void)_relinquishMountedView
{
  CKAssertMainThread();
  CKAssert(_mountInfo != nullptr, @"_mountInfo should not be null");
  if (_mountInfo != nullptr) {
    UIView *view = _mountInfo->view;
    if (view) {
      CKAssert(CKMountedObjectForView(view) == self, @"");
      CKSetMountedObjectForView(view, nil);
      _mountInfo->view = nil;
    }
  }
}

- (void)childrenDidMount
{

}

- (CKMountInfo)mountInfo
{
  if (_mountInfo) {
    return *_mountInfo.get();
  }
  return {};
}

- (id)controller
{
  return nil;
}

- (id<NSObject>)uniqueIdentifier
{
  return nil;
}

- (NSString *)debugName
{
  return NSStringFromClass(self.class);
}

- (BOOL)shouldCacheLayout
{
  return NO;
}

@end
