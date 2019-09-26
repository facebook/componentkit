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

#import <ComponentKit/CKComponentDescriptionHelper.h>

#import "CKInternalHelpers.h"
#import "CKComponentInternal.h"
#import "CKComponentSubclass.h"
#import "CKRenderHelpers.h"

@implementation CKCompositeComponent

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

+ (instancetype)newWithComponent:(CKComponent *)component
{
  return [self newWithView:{} component:component];
}

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view component:(CKComponent *)component
{
  if (!component) {
    return nil;
  }

  CKCompositeComponent *c = [super newWithView:view size:{}];
  if (c) {
    c->_child = component;
  }
  return c;
}

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view size:(const CKComponentSize &)size
{
  CK_NOT_DESIGNATED_INITIALIZER();
}

- (NSString *)description
{
  return CKComponentDescriptionWithChildren([super description], [NSArray arrayWithObjects:_child, nil]);
}

- (void)buildComponentTree:(id<CKTreeNodeWithChildrenProtocol>)parent
            previousParent:(id<CKTreeNodeWithChildrenProtocol>)previousParent
                    params:(const CKBuildComponentTreeParams &)params
      parentHasStateUpdate:(BOOL)parentHasStateUpdate
{
  CKRender::ComponentTree::NonRender::build(self, _child, parent, previousParent, params, parentHasStateUpdate);
}

- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
                          restrictedToSize:(const CKComponentSize &)size
                      relativeToParentSize:(CGSize)parentSize
{
  CKAssert(size == CKComponentSize(),
           @"CKCompositeComponent only passes size {} to the super class initializer, but received size %@ "
           "(component=%@)", size.description(), _child);

  CKComponentLayout l = [_child layoutThatFits:constrainedSize parentSize:parentSize];
  return {self, l.size, {{{0,0}, l}}};
}

- (UIView *)viewForAnimation
{
  // Delegate to the wrapped component's viewForAnimation if we don't have one.
  return [super viewForAnimation] ?: [_child viewForAnimation];
}

@end
