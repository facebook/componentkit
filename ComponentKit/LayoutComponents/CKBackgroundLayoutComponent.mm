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

#import "CKComponentSubclass.h"

@interface CKBackgroundLayoutComponent ()
{
  CKComponent *_component;
  CKComponent *_background;
}
@end

@implementation CKBackgroundLayoutComponent

+ (instancetype)newWithComponent:(CKComponent *)component
                      background:(CKComponent *)background
{
  if (component == nil) {
    return nil;
  }
  CKBackgroundLayoutComponent *c = [super newWithView:{} size:{}];
  c->_component = component;
  c->_background = background;
  return c;
}

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view size:(const CKComponentSize &)size
{
  CK_NOT_DESIGNATED_INITIALIZER();
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

  std::vector<CKComponentLayoutChild> children;
  if (_background) {
    // Size background to exactly the same size.
    children.push_back({{0,0}, [_background layoutThatFits:{contentsLayout.size, contentsLayout.size} parentSize:contentsLayout.size]});
  }
  children.push_back({{0,0}, contentsLayout});

  return {self, contentsLayout.size, children};
}

@end
