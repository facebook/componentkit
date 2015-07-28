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

#import "CKComponentSize.h"
#import "CKComponentSubclass.h"

@implementation CKImageComponent

+ (instancetype)newWithImage:(NSImage *)image
{
  return [self
          newWithImage:image
          size:CKComponentSize::fromCGSize(image.size)];
}

+ (instancetype)newWithImage:(NSImage *)image
                        size:(const CKComponentSize &)size
{
  return [self
          newWithView:{[NSImageView class], {{@selector(setImage:), image}}}
          size:size];
}

+ (instancetype)newWithImage:(NSImage *)image
                        view:(CKComponentViewConfiguration)view
                        size:(const CKComponentSize &)size
{
  return [self
          newWithView:view
          size:size];
}


@end
