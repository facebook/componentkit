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

#import "CKComponentSubclass.h"
#import "CKInternalHelpers.h"
#import "ComponentLayoutContext.h"

@interface CKInsetComponent ()
{
  UIEdgeInsets _insets;
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

+ (instancetype)newWithInsets:(UIEdgeInsets)insets component:(CKComponent *)component
{
  return [self newWithView:{} insets:insets component:component];
}

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view
                     insets:(UIEdgeInsets)insets
                  component:(CKComponent *)component
{
  if (component == nil) {
    return nil;
  }
  CKInsetComponent *c = [super newWithView:view size:{}];
  if (c) {
    c->_insets = insets;
    c->_component = component;
  }
  return c;
}

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view size:(const CKComponentSize &)size
{
  CK_NOT_DESIGNATED_INITIALIZER();
}

/**
 Inset will compute a new constrained size for it's child after applying insets and re-positioning
 the child to respect the inset.
 */
- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
                          restrictedToSize:(const CKComponentSize &)size
                      relativeToParentSize:(CGSize)parentSize
{
  CKAssert(size == CKComponentSize(),
           @"CKInsetComponent only passes size {} to the super class initializer, but received size %@ "
           "(component=%@)", size.description(), _component);

  const CGFloat insetsX = (finiteOrZero(_insets.left) + finiteOrZero(_insets.right));
  const CGFloat insetsY = (finiteOrZero(_insets.top) + finiteOrZero(_insets.bottom));

  // if either x-axis inset is infinite, let child be intrinsic width
  const CGFloat minWidth = (isinf(_insets.left) || isinf(_insets.right)) ? 0 : constrainedSize.min.width;
  // if either y-axis inset is infinite, let child be intrinsic height
  const CGFloat minHeight = (isinf(_insets.top) || isinf(_insets.bottom)) ? 0 : constrainedSize.min.height;

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
  const CGSize insetParentSize = {
    MAX(0, parentSize.width - insetsX),
    MAX(0, parentSize.height - insetsY)
  };
  CKComponentLayout childLayout = [_component layoutThatFits:insetConstrainedSize parentSize:insetParentSize];

  const CGSize computedSize = constrainedSize.clamp({
    finite(childLayout.size.width + _insets.left + _insets.right, parentSize.width),
    finite(childLayout.size.height + _insets.top + _insets.bottom, parentSize.height),
  });

  CKAssert(!isnan(computedSize.width) && !isnan(computedSize.height),
           @"Inset component computed size is NaN; you may not specify infinite insets against a NaN parent size\n"
           "parentSize = %@, insets = %@\n%@", NSStringFromCGSize(parentSize), NSStringFromUIEdgeInsets(_insets),
           CK::Component::LayoutContext::currentStackDescription());

  const CGFloat x = finite(_insets.left, constrainedSize.max.width -
                           (finite(_insets.right,
                                   centerInset(constrainedSize.max.width, childLayout.size.width)) + childLayout.size.width));

  const CGFloat y = finite(_insets.top,
                           constrainedSize.max.height -
                           (finite(_insets.bottom,
                                   centerInset(constrainedSize.max.height, childLayout.size.height)) + childLayout.size.height));
  return {self, computedSize, {{{x,y}, childLayout}}};
}

@end
