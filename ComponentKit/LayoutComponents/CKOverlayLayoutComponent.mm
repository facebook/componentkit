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

- (instancetype)initWithComponent:(CKComponent *)component overlay:(CKComponent *)overlay
{
  CKComponentPerfScope perfScope(self.class);
  if (self = [super initWithView:{} size:{}]) {
    self->_overlay = overlay;
    self->_component = component;
  }
  return self;
}

#pragma mark - CKMountable

- (unsigned int)numberOfChildren
{
  return RCIterable::numberOfChildren(_component, _overlay);
}

- (id<CKMountable>)childAtIndex:(unsigned int)index
{
  return RCIterable::childAtIndex(self, index, _component, _overlay);
}

/**
 First layout the contents, then fit the overlay on top of it.
 */
- (RCLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
                          restrictedToSize:(const CKComponentSize &)size
                      relativeToParentSize:(CGSize)parentSize
{
  CKAssert(size == CKComponentSize(),
           @"CKOverlayLayoutComponent only passes size {} to the super class initializer, but received size %@ "
           "(component=%@, overlay=%@)", size.description(), _component, _overlay);

  // This variable needs to be mutable so we can move from it.
  /* const */ RCLayout contentsLayout = [_component layoutThatFits:constrainedSize parentSize:parentSize];

  const auto contentsLayoutSize = contentsLayout.size;

  return {
    self,
    contentsLayoutSize,
    _overlay
    ? std::vector<RCLayoutChild> {
      {{0,0}, std::move(contentsLayout)},
      {{0,0}, [_overlay layoutThatFits:{contentsLayoutSize, contentsLayoutSize} parentSize:contentsLayoutSize]},
    }
    : std::vector<RCLayoutChild> {
      {{0,0}, std::move(contentsLayout)},
    }
  };
}

@end
