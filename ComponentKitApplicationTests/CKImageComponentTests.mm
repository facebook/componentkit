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

#import <ComponentKit/CKComponentSize.h>
#import <ComponentKit/CKImageComponent.h>
#import <ComponentKit/CKAutoSizedImageComponent.h>

#pragma mark - Helpers

static UIImage *TestImageWithColorAndSize(UIColor *color, CGSize size)
{
  UIGraphicsBeginImageContext(size);
  CGContextRef context = UIGraphicsGetCurrentContext();
  for (NSInteger i=0; i<size.width; i+=10) {
    for (NSInteger j=0; j<size.height; j+=10) {
      NSInteger row = i/10, col = j/10;
      CGContextSetFillColorWithColor(context, ((row+col)%2==0)?[color CGColor]:[[UIColor whiteColor] CGColor]);
      CGContextFillRect(context, CGRectMake(i, j, 10, 10));
    }
  }
  UIImage *const img = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return img;
}

#pragma mark - Tests

@interface CKImageComponentTests : CKComponentSnapshotTestCase
@end

@implementation CKImageComponentTests

- (void)setUp
{
  [super setUp];
  self.recordMode = NO;
}

- (void)testImageComponentWithImageSize
{
  CKAutoSizedImageComponent *c =
  [CKAutoSizedImageComponent
   newWithImage:TestImageWithColorAndSize([UIColor redColor], CGSizeMake(200, 200))
   attributes:{}];

  static CKSizeRange kSize = {{0, 0}, {400, 400}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testImageComponentWithFixedSize
{
  CKImageComponent *c =
  [CKImageComponent
   newWithImage:TestImageWithColorAndSize([UIColor orangeColor], CGSizeMake(200, 200))
   attributes:{}
   size:CKComponentSize::fromCGSize(CGSizeMake(50, 50))];

  static CKSizeRange kSize = {{0, 0}, {400, 400}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testImageComponentWithNilImageAndCustomBackgroundColor
{
  CKImageComponent *c =
  [CKImageComponent
   newWithImage:nil
   attributes:{
     {@selector(setBackgroundColor:), [UIColor darkGrayColor]},
     {CKComponentViewAttribute::LayerAttribute(@selector(setCornerRadius:)), 50}
   }
   size:CKComponentSize::fromCGSize(CGSizeMake(180, 180))];

  static CKSizeRange kSize = {{0, 0}, {400, 400}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

@end
