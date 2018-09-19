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

#import "CKBuildComponent.h"
#import "CKComponentInternal.h"
#import "CKRenderComponentInternal.h"
#import "CKComponentSubclass.h"
#import "CKInternalHelpers.h"
#import "CKRenderHelpers.h"
#import "CKTreeNode.h"


@implementation CKRenderComponent
{
  CKComponent *_childComponent;
}

#if DEBUG
+ (void)initialize
{
  if (self != [CKRenderComponent class]) {
    CKAssert(!CKSubclassOverridesSelector([CKRenderComponent class], self, @selector(computeLayoutThatFits:)),
             @"%@ overrides -computeLayoutThatFits: which is not allowed. "
             "Consider subclassing CKRenderWithChildrenComponent directly if you need to perform custom layout.",
             self);
    CKAssert(!CKSubclassOverridesSelector([CKRenderComponent class], self, @selector(layoutThatFits:parentSize:)),
             @"%@ overrides -layoutThatFits:parentSize: which is not allowed. "
             "Consider subclassing CKRenderWithChildrenComponent directly if you need to perform custom layout.",
             self);
  }
}
#endif

+ (instancetype)new
{
  return [super newRenderComponentWithView:{} size:{} isLayoutComponent:NO];
}

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view
                       size:(const CKComponentSize &)size
{
  return [super newRenderComponentWithView:view size:size isLayoutComponent:NO];
}

- (CKComponent *)render:(id)state
{
  return nil;
}

- (void)buildComponentTree:(id<CKTreeNodeWithChildrenProtocol>)parent
            previousParent:(id<CKTreeNodeWithChildrenProtocol>)previousParent
                    params:(const CKBuildComponentTreeParams &)params
                    config:(const CKBuildComponentConfig &)config
            hasDirtyParent:(BOOL)hasDirtyParent
{
  CKRender::buildComponentTreeWithSingleChild(self, &_childComponent, parent, previousParent, params, config, hasDirtyParent);
}

- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
                          restrictedToSize:(const CKComponentSize &)size
                      relativeToParentSize:(CGSize)parentSize
{
  CKAssert(size == CKComponentSize(),
           @"CKRenderComponent only passes size {} to the super class initializer, but received size %@ "
           "(component=%@)", size.description(), _childComponent);

  auto const l = [_childComponent layoutThatFits:constrainedSize parentSize:parentSize];
  return {self, l.size, {{{0,0}, l}}};
}

- (CKComponent *)childComponent
{
  return _childComponent;
}

#pragma mark - CKRenderComponentProtocol

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

@end
