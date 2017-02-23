/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentSnapshotTestCase/CKComponentSnapshotTestCase.h>

#import <ComponentKit/CKNetworkImageComponent.h>

#pragma mark - Helpers

static UIImage *ck_fakeImage(UIColor *imageBackgroundColor, CGSize size)
{
  size_t bytesPerRow = ((((size_t)size.width * 4)+31)&~0x1f);

  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef context = CGBitmapContextCreate(NULL,
                                               size.width,
                                               size.height,
                                               8,
                                               bytesPerRow,
                                               colorSpace,
                                               kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
  CGColorSpaceRelease(colorSpace);

  CGContextSetAllowsAntialiasing(context, YES);
  CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
  CGContextSetFillColorWithColor(context, [imageBackgroundColor CGColor]);
  CGContextFillRect(context, {{0,0}, size});
  CGImageRef imageRef = CGBitmapContextCreateImage(context);
  CGContextRelease(context);
  UIImage *image = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:UIImageOrientationUp];
  CGImageRelease(imageRef);

  return image;
}

typedef id (^CKTestImageDownloaderDownloadImageBlock)(NSURL *url,
                                                      id caller,
                                                      dispatch_queue_t callbackQueue,
                                                      void (^downloadProgressBlock)(CGFloat),
                                                      void (^completion)(CGImageRef, NSError *));

@interface CKTestImageDownloader : NSObject <CKNetworkImageDownloading>
@end

@implementation CKTestImageDownloader
{
  CKTestImageDownloaderDownloadImageBlock _downloadImageBlock;
}

- (instancetype)initWithDownloadImageBlock:(CKTestImageDownloaderDownloadImageBlock)downloadImageBlock
{
  self = [super init];
  if (self) {
    _downloadImageBlock = [downloadImageBlock copy];
  }
  return self;
}

- (id)downloadImageWithURL:(NSURL *)URL
                    caller:(id)caller
             callbackQueue:(dispatch_queue_t)callbackQueue
     downloadProgressBlock:(void (^)(CGFloat))downloadProgressBlock
                completion:(void (^)(CGImageRef, NSError *))completion
{
  return _downloadImageBlock(URL, caller, callbackQueue, downloadProgressBlock, completion);
}

- (void)cancelImageDownload:(id)download { /* no-op */ }

@end

#pragma mark - Tests

@interface CKNetworkImageComponentTests : CKComponentSnapshotTestCase
@end

@implementation CKNetworkImageComponentTests

- (void)setUp
{
  [super setUp];
  self.recordMode = NO;
}

- (void)testWhenNoDefaultImageIsGivenImageViewImageIsNotSetToDefaultImage
{
  CKNetworkImageComponent *c =
  [CKNetworkImageComponent
   newWithURL:nil
   imageDownloader:nil
   size:{}
   options:{}
   attributes:{
     {{@selector(setBackgroundColor:), [UIColor redColor]}},
   }];

  static CKSizeRange kSize = {{50, 50}, {50, 50}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testWhenDefaultImageIsGivenImageViewImageIsSetToDefaultImage
{
  CKNetworkImageComponent *c =
  [CKNetworkImageComponent
   newWithURL:nil
   imageDownloader:nil
   size:{}
   options:{
     .defaultImage = ck_fakeImage([UIColor greenColor], CGSizeMake(50, 50)),
   }
   attributes:{
     {{@selector(setBackgroundColor:), [UIColor redColor]}},
   }];

  static CKSizeRange kSize = {{50, 50}, {50, 50}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testWhenURLIsNilImageDownloaderIsNotCalled
{
  CKTestImageDownloader *imageDownloader =
    [[CKTestImageDownloader alloc] initWithDownloadImageBlock:^id(NSURL *url,
                                                                  id caller,
                                                                  dispatch_queue_t callbackQueue,
                                                                  void (^downloadProgressBlock)(CGFloat),
                                                                  void (^completion)(CGImageRef, NSError *)) {
      // Fake image downloader immediately returns a blue image, but since component
      // URL is nil, this image will never be used.
      completion(ck_fakeImage([UIColor blueColor], CGSizeMake(50, 50)).CGImage, nil);
      return nil;
  }];

  CKNetworkImageComponent *c =
  [CKNetworkImageComponent
   newWithURL:nil
   imageDownloader:imageDownloader
   size:{}
   options:{}
   attributes:{
     // Snapshot will show a red image, not the purple image provided by the image downloader.
     {{@selector(setBackgroundColor:), [UIColor redColor]}},
   }];

  static CKSizeRange kSize = {{50, 50}, {50, 50}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testWhenURLIsNotNilAndImageDownloaderCallsCompletionBlockWithImageThatImageIsSetAsTheImageViewImageInsteadOfTheDefaultImage
{
  CKTestImageDownloader *imageDownloader =
    [[CKTestImageDownloader alloc] initWithDownloadImageBlock:^id(NSURL *url,
                                                                  id caller,
                                                                  dispatch_queue_t callbackQueue,
                                                                  void (^downloadProgressBlock)(CGFloat),
                                                                  void (^completion)(CGImageRef, NSError *)) {
      // This half-transparent blue image will be overlaid on top of the red background image.
      UIImage *blueImage = ck_fakeImage([UIColor colorWithRed:0 green:0 blue:1 alpha:.5],
                                        CGSizeMake(50, 50));
      completion(blueImage.CGImage, nil);
      return nil;
  }];

  CKNetworkImageComponent *c =
  [CKNetworkImageComponent
   newWithURL:[NSURL URLWithString:@"http://literally-any-non-nil-url-can-be-used-here.com"]
   imageDownloader:imageDownloader
   size:{}
   options:{
     // This opaque green default image will be replaced in favor of the image provided by the image downloader.
     .defaultImage = ck_fakeImage([UIColor greenColor], CGSizeMake(50, 50)),
   }
   attributes:{
     {{@selector(setBackgroundColor:), [UIColor redColor]}},
   }];

  static CKSizeRange kSize = {{50, 50}, {50, 50}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testCropRectLimitsTheSizeOfTheImageToTheSpecifiedRect
{
  CKNetworkImageComponent *c =
  [CKNetworkImageComponent
   newWithURL:nil
   imageDownloader:nil
   size:{}
   options:{
     .cropRect = CGRectMake(0, 0, 40, 40),
     .defaultImage = ck_fakeImage([UIColor greenColor], CGSizeMake(50, 50)),
   }
   attributes:{
     {{@selector(setBackgroundColor:), [UIColor redColor]}},
   }];

  static CKSizeRange kSize = {{50, 50}, {50, 50}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

@end
