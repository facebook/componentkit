/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKInsetComponent.h"

#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKMacros.h>
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKComponentPerfScope.h>
#import <ComponentKit/CKInternalHelpers.h>
#import <ComponentKit/CKSizeAssert.h>

#import "CKComponentSubclass.h"
#import "CKDimension_SwiftBridge+Internal.h"
#import "ComponentLayoutContext.h"
#import "CKComponentViewConfiguration_SwiftBridge+Internal.h"

@interface CKInsetComponent ()
{
  CKRelativeDimension _top;
  CKRelativeDimension _left;
  CKRelativeDimension _bottom;
  CKRelativeDimension _right;
  CKComponent *_component;
}
@end

/* Returns f if f is finite, substitute otherwise */
static CGFloat finite(CGFloat f, CGFloat substitute)
{
  return isinf(f) ? substitute : f;
}

/* Returns f if f is finite, 0 otherwise */
static CGFloat finiteOrZero(CGFloat f)
{
  return finite(f, 0);
}

/* Returns the inset required to center 'inner' in 'outer' */
static CGFloat centerInset(CGFloat outer, CGFloat inner)
{
  return CKRoundPixelValue((outer - inner) / 2);
}

@implementation CKInsetComponent

- (instancetype)initWithView:(const CKComponentViewConfiguration &)view
                         top:(CKRelativeDimension)top
                        left:(CKRelativeDimension)left
                      bottom:(CKRelativeDimension)bottom
                       right:(CKRelativeDimension)right
                   component:(CKComponent *)component
{
  if (component == nil) {
    return nil;
  }
  CKComponentPerfScope perfScope(self.class);
  CKInsetComponent *c = [super initWithView:view size:{}];
  if (c) {
    c->_top = top;
    c->_left = left;
    c->_bottom = bottom;
    c->_right = right;
    c->_component = component;
  }
  return c;
}

- (instancetype)initWithTop:(CKRelativeDimension)top
                       left:(CKRelativeDimension)left
                     bottom:(CKRelativeDimension)bottom
                      right:(CKRelativeDimension)right
                     component:(CKComponent *_Nullable)component
{
  return [self initWithView:{} top:top left:left bottom:bottom right:right component:component];
}

- (nullable instancetype)initWithSwiftView:(CKComponentViewConfiguration_SwiftBridge *)swiftView
                                       top:(CKDimension_SwiftBridge *)top
                                      left:(CKDimension_SwiftBridge *)left
                                    bottom:(CKDimension_SwiftBridge *)bottom
                                     right:(CKDimension_SwiftBridge *)right
                                 component:(CKComponent *_Nullable)component
{
  const auto view = swiftView != nil ? swiftView.viewConfig : CKComponentViewConfiguration{};
  return [self initWithView:view top:top.dimension left:left.dimension bottom:bottom.dimension right:right.dimension component:component];
}

/**
 Inset will compute a new constrained size for it's child after applying insets and re-positioning
 the child to respect the inset.
 */
- (RCLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
                          restrictedToSize:(const CKComponentSize &)size
                      relativeToParentSize:(CGSize)parentSize
{
  CKAssert(size == CKComponentSize(),
           @"CKInsetComponent only passes size {} to the super class initializer, but received size %@ "
           "(component=%@)", size.description(), _component);

  const UIEdgeInsets insets = UIEdgeInsetsMake(_top.resolve(0, parentSize.height), _left.resolve(0, parentSize.width), _bottom.resolve(0, parentSize.height), _right.resolve(0, parentSize.width));

  const CGFloat insetsX = (finiteOrZero(insets.left) + finiteOrZero(insets.right));
  const CGFloat insetsY = (finiteOrZero(insets.top) + finiteOrZero(insets.bottom));

  // if either x-axis inset is infinite, let child be intrinsic width
  const CGFloat minWidth = (isinf(insets.left) || isinf(insets.right)) ? 0 : constrainedSize.min.width;
  // if either y-axis inset is infinite, let child be intrinsic height
  const CGFloat minHeight = (isinf(insets.top) || isinf(insets.bottom)) ? 0 : constrainedSize.min.height;

  const CKSizeRange insetConstrainedSize = {
    {
      MAX(0, minWidth - insetsX),
      MAX(0, minHeight - insetsY),
    },
    {
      MAX(0, constrainedSize.max.width - insetsX),
      MAX(0, constrainedSize.max.height - insetsY),
    }
  };
  CKAssertSizeRange(insetConstrainedSize);
  const CGSize insetParentSize = {
    MAX(0, parentSize.width - insetsX),
    MAX(0, parentSize.height - insetsY)
  };
  RCLayout childLayout = [_component layoutThatFits:insetConstrainedSize parentSize:insetParentSize];

  const CGSize computedSize = constrainedSize.clamp({
    finite(childLayout.size.width + insets.left + insets.right, parentSize.width),
    finite(childLayout.size.height + insets.top + insets.bottom, parentSize.height),
  });

  CKAssert(!isnan(computedSize.width) && !isnan(computedSize.height),
           @"Inset component computed size is NaN; you may not specify infinite insets against a NaN parent size\n"
           "parentSize = %@, insets = %@\n%@", NSStringFromCGSize(parentSize), NSStringFromUIEdgeInsets(insets),
           CK::Component::LayoutContext::currentStackDescription());

  const CGFloat x = finite(insets.left, constrainedSize.max.width -
                           (finite(insets.right,
                                   centerInset(constrainedSize.max.width, childLayout.size.width)) + childLayout.size.width));

  const CGFloat y = finite(insets.top,
                           constrainedSize.max.height -
                           (finite(insets.bottom,
                                   centerInset(constrainedSize.max.height, childLayout.size.height)) + childLayout.size.height));
  return {self, computedSize, {{{x,y}, std::move(childLayout)}}};
}

#pragma mark - CKMountable

- (unsigned int)numberOfChildren
{
  return RCIterable::numberOfChildren(_component);
}

- (id<CKMountable>)childAtIndex:(unsigned int)index
{
  return RCIterable::childAtIndex(self, index, _component);
}

@end
