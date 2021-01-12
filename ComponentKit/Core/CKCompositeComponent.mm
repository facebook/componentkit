/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKCompositeComponent.h"

#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKMacros.h>
#import <ComponentKit/CKInternalHelpers.h>

#import "CKComponentInternal.h"
#import "CKComponentSubclass.h"
#import "CKIterableHelpers.h"
#import "CKRenderHelpers.h"
#import "CKComponentViewConfiguration_SwiftBridge+Internal.h"

@implementation CKCompositeComponent
{
  id<CKMountable> _child;
}

#if DEBUG
+ (void)initialize
{
  if (self != [CKCompositeComponent class]) {
    CKAssert(!CKSubclassOverridesInstanceMethod([CKCompositeComponent class], self, @selector(computeLayoutThatFits:)),
             @"%@ overrides -computeLayoutThatFits: which is not allowed. "
             "Consider subclassing CKComponent directly if you need to perform custom layout.",
             self);
    CKAssert(!CKSubclassOverridesInstanceMethod([CKCompositeComponent class], self, @selector(layoutThatFits:parentSize:)),
             @"%@ overrides -layoutThatFits:parentSize: which is not allowed. "
             "Consider subclassing CKComponent directly if you need to perform custom layout.",
             self);
  }
}
#endif

- (instancetype _Nullable)initWithView:(const CKComponentViewConfiguration &)view
                             component:(id<CKMountable> _Nullable)component
{
  if (component == nil) {
    return nil;
  }

  if (self = [super initWithView:view size:{}]) {
    _child = component;
  }
  return self;
}

- (instancetype)initWithSwiftView:(CKComponentViewConfiguration_SwiftBridge *_Nullable)swiftView
                        component:(id<CKMountable>)component
{
  const auto view = swiftView != nil ? swiftView.viewConfig : CKComponentViewConfiguration{};
  return [self initWithView:view component:component];
}

+ (instancetype)newWithComponent:(id<CKMountable>)component
{
  return [self newWithView:{} component:component];
}

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view component:(id<CKMountable>)component
{
  if (component == nil) {
    return nil;
  }

  CKCompositeComponent *c = [super newWithView:view size:{}];
  if (c != nil) {
    c->_child = component;
  }

  return c;
}

- (RCLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
                          restrictedToSize:(const CKComponentSize &)size
                      relativeToParentSize:(CGSize)parentSize
{
  CKAssert(size == CKComponentSize(),
           @"CKCompositeComponent only passes size {} to the super class initializer, but received size %@ "
           "(component=%@)", size.description(), _child);

  RCLayout l = [_child layoutThatFits:constrainedSize parentSize:parentSize];
  const auto lSize = l.size;
  return {self, lSize, {{{0,0}, std::move(l)}}};
}

- (id<CKMountable>)child
{
  return _child;
}

- (UIView *)viewForAnimation
{
  // Delegate to the wrapped component's viewForAnimation if we don't have one.
  return [super viewForAnimation] ?: [CKReturnIfResponds(_child, @selector(viewForAnimation)) viewForAnimation];
}

- (unsigned int)numberOfChildren
{
  return RCIterable::numberOfChildren(_child);
}

- (id<CKMountable>)childAtIndex:(unsigned int)index
{
  return RCIterable::childAtIndex(self, index, _child);
}

@end
