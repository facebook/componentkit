/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant 
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKAsyncImageRetrieval.h>

struct CKAsyncImageComponentOptions {
  /** Optional imade displayed while the image is being retrieved, or when identifier is nil. */
  UIImage *defaultImage;
  /** Optional rectangle (in the unit coordinate space) that specifies the portion of contents that the receiver should draw. */
  CGRect cropRect;
};

/** Renders an image from an external/async source. */
@interface CKAsyncImageComponent : CKComponent

/**
 @param options See CKAsyncImageComponentOptions
 @param attributes Applied to the underlying UIImageView.
 */
+ (instancetype)newWithIdentifier:(id)identifier
                  imageDownloader:(id<CKAsyncImageRetrieval>)imageDownloader
                        scenePath:(id)scenePath
                             size:(const CKComponentSize &)size
                          options:(const CKAsyncImageComponentOptions &)options
                       attributes:(const CKViewComponentAttributeValueMap &)attributes;

@end
