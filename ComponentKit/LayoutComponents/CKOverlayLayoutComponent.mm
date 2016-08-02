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

#import "CKComponentSubclass.h"

@implementation CKOverlayLayoutComponent
{
  CKComponent *_overlay;
  CKComponent *_component;
}

+ (instancetype)newWithComponent:(CKComponent *)component
                         overlay:(CKComponent *)overlay
{
  CKOverlayLayoutComponent *c = [super newWithView:{} size:{}];
  if (c) {
    CKAssertNotNil(component, @"Component that will be overlayed on shouldn't be nil");
    c->_overlay = overlay;
    c->_component = component;
  }
  return c;
}

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view size:(const CKComponentSize &)size
{
  CK_NOT_DESIGNATED_INITIALIZER();
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

  CKComponentLayout contentsLayout = [_component layoutThatFits:constrainedSize parentSize:parentSize];
  
  return {
    self,
    contentsLayout.size,
    _overlay ? std::vector<CKComponentLayoutChild> {
      {{0,0}, contentsLayout},
      {{0,0}, CKComputeComponentLayout(_overlay, {contentsLayout.size, contentsLayout.size}, contentsLayout.size)}
    } : std::vector<CKComponentLayoutChild> {
      {{0,0}, contentsLayout},
    }
  };
}

@end
