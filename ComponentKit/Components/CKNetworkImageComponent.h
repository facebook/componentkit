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
#import <ComponentKit/CKNetworkImageDownloading.h>

struct CKNetworkImageComponentOptions {
  /** Optional image displayed while the image is loading, or when url is nil. */
  UIImage *defaultImage;
  /** Optional rectangle (in the unit coordinate space) that specifies the portion of contents that the receiver should draw. */
  CGRect cropRect;
};

/** Renders an image from a URL. */
@interface CKNetworkImageComponent : CKComponent

/**
 @param options See CKNetworkImageComponentOptions
 @param attributes Applied to the underlying UIImageView.
 */
+ (instancetype)newWithURL:(NSURL *)url
           imageDownloader:(id<CKNetworkImageDownloading>)imageDownloader
                 scenePath:(id)scenePath
                      size:(const CKComponentSize &)size
                   options:(const CKNetworkImageComponentOptions &)options
                attributes:(const CKViewComponentAttributeValueMap &)attributes;

@end
