/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKNetworkImageComponent.h"

@interface CKNetworkImageSpecifier : NSObject
- (instancetype)initWithURL:(NSURL *)url
               defaultImage:(UIImage *)defaultImage
            imageDownloader:(id<CKNetworkImageDownloading>)imageDownloader
                  scenePath:(id)scenePath
                   cropRect:(CGRect)cropRect;
@property (nonatomic, copy, readonly) NSURL *url;
@property (nonatomic, strong, readonly) UIImage *defaultImage;
@property (nonatomic, strong, readonly) id<CKNetworkImageDownloading> imageDownloader;
@property (nonatomic, strong, readonly) id scenePath;
@property (nonatomic, assign, readonly) CGRect cropRect;
@end

@interface CKNetworkImageComponentView : UIImageView
@property (nonatomic, strong) CKNetworkImageSpecifier *specifier;
- (void)didEnterReusePool;
- (void)willLeaveReusePool;
@end

@implementation CKNetworkImageComponent

+ (instancetype)newWithURL:(NSURL *)url
           imageDownloader:(id<CKNetworkImageDownloading>)imageDownloader
                 scenePath:(id)scenePath
                      size:(const CKComponentSize &)size
                   options:(const CKNetworkImageComponentOptions &)options
                attributes:(const CKViewComponentAttributeValueMap &)passedAttributes
{
  CGRect cropRect = options.cropRect;
  if (CGRectIsEmpty(cropRect)) {
    cropRect = CGRectMake(0, 0, 1, 1);
  }
  CKViewComponentAttributeValueMap attributes(passedAttributes);
  attributes.insert({
    {@selector(setSpecifier:), [[CKNetworkImageSpecifier alloc] initWithURL:url
                                                               defaultImage:options.defaultImage
                                                            imageDownloader:imageDownloader
                                                                  scenePath:scenePath
                                                                   cropRect:cropRect]},

  });
  return [super newWithView:{
    {[CKNetworkImageComponentView class], @selector(didEnterReusePool), @selector(willLeaveReusePool)},
    std::move(attributes)
  } size:size];
}

@end

@implementation CKNetworkImageSpecifier

- (instancetype)initWithURL:(NSURL *)url
               defaultImage:(UIImage *)defaultImage
            imageDownloader:(id<CKNetworkImageDownloading>)imageDownloader
                  scenePath:(id)scenePath
                   cropRect:(CGRect)cropRect
{
  if (self = [super init]) {
    _url = [url copy];
    _defaultImage = defaultImage;
    _imageDownloader = imageDownloader;
    _scenePath = scenePath;
    _cropRect = cropRect;
  }
  return self;
}

- (NSUInteger)hash
{
  return [_url hash];
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  } else if ([object isKindOfClass:[self class]]) {
    CKNetworkImageSpecifier *other = object;
    return CKObjectIsEqual(_url, other->_url)
    && CKObjectIsEqual(_defaultImage, other->_defaultImage)
    && CKObjectIsEqual(_imageDownloader, other->_imageDownloader)
    && CKObjectIsEqual(_scenePath, other->_scenePath)
    && CGRectEqualToRect(_cropRect, other->_cropRect);
  }
  return NO;
}

@end

@implementation CKNetworkImageComponentView
{
  BOOL _inReusePool;
  id _download;
}

- (void)dealloc
{
  if (_download) {
    [_specifier.imageDownloader cancelImageDownload:_download];
  }
}

- (void)didDownloadImage:(CGImageRef)image error:(NSError *)error
{
  if (image) {
    self.image = [UIImage imageWithCGImage:image];
    [self updateContentsRect];
  }
  _download = nil;
}

- (void)setSpecifier:(CKNetworkImageSpecifier *)specifier
{
  if (CKObjectIsEqual(specifier, _specifier)) {
    return;
  }

  if (!CGRectEqualToRect(_specifier.cropRect, specifier.cropRect)) {
    [self setNeedsLayout];
  }

  BOOL urlIsDifferent = !CKObjectIsEqual(_specifier.url, specifier.url);
  BOOL isShowingCurrentDefaultImage = CKObjectIsEqual(self.image, _specifier.defaultImage);
  if (urlIsDifferent || isShowingCurrentDefaultImage) {
    self.image = specifier.defaultImage;
  }

  if (urlIsDifferent && _download != nil) {
    [specifier.imageDownloader cancelImageDownload:_download];
    _download = nil;
  }

  _specifier = specifier;

  if (urlIsDifferent) {
    [self _startDownloadIfNotInReusePool];
  }
}

- (void)didEnterReusePool
{
  _inReusePool = YES;
  if (_download) {
    [_specifier.imageDownloader cancelImageDownload:_download];
    _download = nil;
  }
  // Release the downloaded image that we're holding to lower memory usage.
  self.image = _specifier.defaultImage;
}

- (void)willLeaveReusePool
{
  _inReusePool = NO;
  [self _startDownloadIfNotInReusePool];
}

- (void)_startDownloadIfNotInReusePool
{
  if (_inReusePool) {
    return;
  }

  if (_specifier.url == nil) {
    return;
  }

  __weak CKNetworkImageComponentView *weakSelf = self;
  _download = [_specifier.imageDownloader downloadImageWithURL:_specifier.url
                                                     scenePath:_specifier.scenePath
                                                        caller:self
                                                 callbackQueue:dispatch_get_main_queue()
                                         downloadProgressBlock:nil
                                                    completion:^(CGImageRef image, NSError *error)
               {
                 [weakSelf didDownloadImage:image error:error];
               }];
}

- (void)updateContentsRect
{
  if (CGRectIsEmpty(self.bounds)) {
    return;
  }

  // If we're about to crop the width or height, make sure the cropped version won't be upscaled
  CGFloat croppedWidth = self.image.size.width * _specifier.cropRect.size.width;
  CGFloat croppedHeight = self.image.size.height * _specifier.cropRect.size.height;
  if ((_specifier.cropRect.size.width == 1 || croppedWidth >= self.bounds.size.width) &&
      (_specifier.cropRect.size.height == 1 || croppedHeight >= self.bounds.size.height)) {
    self.layer.contentsRect = _specifier.cropRect;
  }
}

#pragma mark - UIView

- (void)layoutSubviews
{
  [super layoutSubviews];

  [self updateContentsRect];
}

@end
