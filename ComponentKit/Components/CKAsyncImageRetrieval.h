/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant 
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

/** Retrieves images for an async image component. */
@protocol CKAsyncImageRetrieval <NSObject>
@required

/**
  @abstract Retrieves an image with the given identifief.
  @param identifier An opaque identifier of the image to be retrieved. Often an URL.
  @param scenePath Opaque context for where this is from.
  @param caller The object that initiated the request.
  @param callbackQueue The queue to call `downloadProgressBlock` and `completion` on. If this value is nil, both blocks will be invoked on the main-queue.
  @param downloadProgressBlock The block to be invoked when the retrieval of `identifier` progresses.
  @param progress The progress of the download, in the range of (0.0, 1.0), inclusive.
  @param completion The block to be invoked when the download has completed, or has failed.
  @param image The image that was downloaded, if the image could be successfully downloaded; nil otherwise.
  @param error An error describing why the retrieval of `identifier` failed, if the download failed; nil otherwise.
  @discussion If `identifier` is nil, `completion` will be invoked immediately with a nil image and an error describing why the retrieval failed.
  @result An opaque identifier to be used in canceling the download, via `cancelImageDownload:`. You must retain the identifier if you wish to use it later.
 */
- (id)downloadImageWithIdentifier:(id)identifier
                        scenePath:(id)scenePath
                           caller:(id)caller
                    callbackQueue:(dispatch_queue_t)callbackQueue
            downloadProgressBlock:(void (^)(CGFloat progress))downloadProgressBlock
                       completion:(void (^)(CGImageRef image, NSError *error))completion;

/**
  @abstract Cancels an image download.
  @param download The opaque download identifier object returned from `downloadImageWithIdentifier:scenePath:caller:callbackQueue:downloadProgressBlock:completion:`.
  @discussion This method has no effect if `download` is nil.
 */
- (void)cancelImageDownload:(id)download;

@end
