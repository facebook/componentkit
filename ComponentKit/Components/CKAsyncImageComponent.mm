/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant 
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKAsyncImageComponent.h"

@interface CKAsyncImageSpecifier : NSObject
- (instancetype)initWithIdentifier:(id)identifier
                      defaultImage:(UIImage *)defaultImage
                   imageDownloader:(id<CKAsyncImageRetrieval>)imageDownloader
                         scenePath:(id)scenePath
                          cropRect:(CGRect)cropRect;
@property (nonatomic, readonly) id identifier;
@property (nonatomic, strong, readonly) UIImage *defaultImage;
@property (nonatomic, strong, readonly) id<CKAsyncImageRetrieval> imageDownloader;
@property (nonatomic, strong, readonly) id scenePath;
@property (nonatomic, assign, readonly) CGRect cropRect;
@end

@interface CKAsyncImageComponentView : UIImageView
@property (nonatomic, strong) CKAsyncImageSpecifier *specifier;
- (void)didEnterReusePool;
- (void)willLeaveReusePool;
@end

@implementation CKAsyncImageComponent

+ (instancetype)newWithIdentifier:(id)identifier
                  imageDownloader:(id<CKAsyncImageRetrieval>)imageDownloader
                        scenePath:(id)scenePath
                             size:(const CKComponentSize &)size
                          options:(const CKAsyncImageComponentOptions &)options
                       attributes:(const CKViewComponentAttributeValueMap &)passedAttributes
{
  CGRect cropRect = options.cropRect;
  if (CGRectIsEmpty(cropRect)) {
    cropRect = CGRectMake(0, 0, 1, 1);
  }
  CKViewComponentAttributeValueMap attributes(passedAttributes);
  attributes.insert({
    {@selector(setSpecifier:), [[CKAsyncImageSpecifier alloc] initWithIdentifier:identifier
                                                                    defaultImage:options.defaultImage
                                                                 imageDownloader:imageDownloader
                                                                       scenePath:scenePath
                                                                        cropRect:cropRect]},

  });
  return [super newWithView:{
    {[CKAsyncImageComponentView class], @selector(didEnterReusePool), @selector(willLeaveReusePool)},
    std::move(attributes)
  } size:size];
}

@end

@implementation CKAsyncImageSpecifier

- (instancetype)initWithIdentifier:(id)identifier
                      defaultImage:(UIImage *)defaultImage
                   imageDownloader:(id<CKAsyncImageRetrieval>)imageDownloader
                         scenePath:(id)scenePath
                          cropRect:(CGRect)cropRect
{
  if (self = [super init]) {
    if ([identifier respondsToSelector:@selector(copyWithZone:)]) {
      _identifier = [identifier copy];
    }
    else {
      _identifier = identifier;
    }
    _defaultImage = defaultImage;
    _imageDownloader = imageDownloader;
    _scenePath = scenePath;
    _cropRect = cropRect;
  }
  return self;
}

- (NSUInteger)hash
{
  return [_identifier hash];
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  } else if ([object isKindOfClass:[self class]]) {
    CKAsyncImageSpecifier *other = object;
    return CKObjectIsEqual(_identifier, other->_identifier)
           && CKObjectIsEqual(_defaultImage, other->_defaultImage)
           && CKObjectIsEqual(_imageDownloader, other->_imageDownloader)
           && CKObjectIsEqual(_scenePath, other->_scenePath);
  }
  return NO;
}

@end

@implementation CKAsyncImageComponentView
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

- (void)setSpecifier:(CKAsyncImageSpecifier *)specifier
{
  if (CKObjectIsEqual(specifier, _specifier)) {
    return;
  }

  if (_download) {
    [_specifier.imageDownloader cancelImageDownload:_download];
    _download = nil;
  }

  _specifier = specifier;
  self.image = specifier.defaultImage;

  [self _startDownloadIfNotInReusePool];
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

  if (_specifier.identifier == nil) {
    return;
  }

  __weak CKAsyncImageComponentView *weakSelf = self;
  _download = [_specifier.imageDownloader downloadImageWithIdentifier:_specifier.identifier
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
