/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKImageComponent.h"

@interface CKImageView : UIImageView
@end

@implementation CKImageComponent

+ (instancetype)newWithImage:(UIImage *)image
                  attributes:(const CKViewComponentAttributeValueMap &)attributes
                        size:(const CKComponentSize &)size
{
  CKViewComponentAttributeValueMap updatedAttributes(attributes);
  updatedAttributes.insert({
    {@selector(setImage:), image},
  });

  return [self
          newWithView:{
            [CKImageView class],
            std::move(updatedAttributes)
          } size:size];
}

@end

@implementation CKImageView

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
  [super traitCollectionDidChange:previousTraitCollection];
  if (@available(iOS 13.0, tvOS 13.0, *)) {
    // In the case where image appearance is decided by color apperance from trait collection,
    // we need to reset image manually in image view to get the correct color appearance.
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
      const auto image = self.image;
      self.image = nil;
      self.image = image;
    }
  }
}

@end
