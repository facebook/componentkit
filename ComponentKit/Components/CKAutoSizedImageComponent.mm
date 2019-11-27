/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKAutoSizedImageComponent.h"

#import <ComponentKit/CKComponentSize.h>

#import "CKImageComponent.h"

@implementation CKAutoSizedImageComponent

+ (instancetype)newWithImage:(UIImage *)image
                  attributes:(const CKViewComponentAttributeValueMap &)attributes
{
  return [super newWithComponent:
          [CKImageComponent
           newWithImage:image
           attributes:attributes
           size:CKComponentSize::fromCGSize(image.size)]];
}

@end
