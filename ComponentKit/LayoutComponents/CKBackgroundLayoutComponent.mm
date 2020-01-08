/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKBackgroundLayoutComponent.h"

#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKMacros.h>
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKComponentPerfScope.h>
#import "CKComponentSubclass.h"

@implementation CKBackgroundLayoutComponent
{
  CKComponent *_component;
  CKComponent *_background;
}

+ (instancetype)newWithComponent:(CKComponent *)component
                      background:(CKComponent *)background
{
  if (component == nil) {
    return nil;
  }
  CKComponentPerfScope perfScope(self);
  CKBackgroundLayoutComponent *c = [super newWithView:{} size:{}];
  if (c) {
    c->_component = component;
    c->_background = background;
  }
  return c;
}

- (unsigned int)numberOfChildren
{
  return CKIterable::numberOfChildren(_component, _background);
}

- (id<CKMountable>)childAtIndex:(unsigned int)index
{
  return CKIterable::childAtIndex(self, index, _component, _background);
}

/**
 First layout the contents, then fit the background image.
 */
- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
                          restrictedToSize:(const CKComponentSize &)size
                      relativeToParentSize:(CGSize)parentSize
{
  CKAssert(size == CKComponentSize(),
           @"CKBackgroundLayoutComponent only passes size {} to the super class initializer, but received size %@ "
           "(component=%@, background=%@)", size.description(), _component, _background);

  const CKComponentLayout contentsLayout = [_component layoutThatFits:constrainedSize parentSize:parentSize];

  return {
    self,
    contentsLayout.size,
    _background
    ? std::vector<CKComponentLayoutChild> {
      {{0,0}, [_background layoutThatFits:{contentsLayout.size, contentsLayout.size} parentSize:contentsLayout.size]},
      {{0,0}, contentsLayout},
    }
    : std::vector<CKComponentLayoutChild> {
      {{0,0}, contentsLayout}
    }
  };
}

@end
