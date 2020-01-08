/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKOverlayLayoutComponent.h"

#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKMacros.h>
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKComponentPerfScope.h>

#import "CKComponentSubclass.h"

@implementation CKOverlayLayoutComponent
{
  CKComponent *_overlay;
  CKComponent *_component;
}

+ (instancetype)newWithComponent:(CKComponent *)component
                         overlay:(CKComponent *)overlay
{
  if (component == nil) {
    return nil;
  }
  CKComponentPerfScope perfScope(self);
  CKOverlayLayoutComponent *c = [super newWithView:{} size:{}];
  if (c) {
    c->_overlay = overlay;
    c->_component = component;
  }
  return c;
}

#pragma mark - CKMountable

- (unsigned int)numberOfChildren
{
  return CKIterable::numberOfChildren(_component, _overlay);
}

- (id<CKMountable>)childAtIndex:(unsigned int)index
{
  return CKIterable::childAtIndex(self, index, _component, _overlay);
}

/**
 First layout the contents, then fit the overlay on top of it.
 */
- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
                          restrictedToSize:(const CKComponentSize &)size
                      relativeToParentSize:(CGSize)parentSize
{
  CKAssert(size == CKComponentSize(),
           @"CKOverlayLayoutComponent only passes size {} to the super class initializer, but received size %@ "
           "(component=%@, overlay=%@)", size.description(), _component, _overlay);

  // This variable needs to be mutable so we can move from it.
  /* const */ CKComponentLayout contentsLayout = [_component layoutThatFits:constrainedSize parentSize:parentSize];

  const auto contentsLayoutSize = contentsLayout.size;

  return {
    self,
    contentsLayoutSize,
    _overlay
    ? std::vector<CKComponentLayoutChild> {
      {{0,0}, std::move(contentsLayout)},
      {{0,0}, [_overlay layoutThatFits:{contentsLayoutSize, contentsLayoutSize} parentSize:contentsLayoutSize]},
    }
    : std::vector<CKComponentLayoutChild> {
      {{0,0}, std::move(contentsLayout)},
    }
  };
}

@end
