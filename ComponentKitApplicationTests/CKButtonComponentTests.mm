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

#import <ComponentKit/CKButtonComponent.h>

@interface CKButtonComponentTests : CKComponentSnapshotTestCase
@end

@implementation CKButtonComponentTests

- (void)setUp
{
  [super setUp];
  self.recordMode = NO;
}

static UIImage *fakeImage()
{
  static UIImage *fakeImage;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    CGSize size = { 17, 17 };
    size_t bytesPerRow = ((((size_t)size.width * 4)+31)&~0x1f);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ref = CGBitmapContextCreate(NULL, size.width, size.height, 8, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
    CGColorSpaceRelease(colorSpace);

    CGContextSetAllowsAntialiasing(ref, YES);
    CGContextSetInterpolationQuality(ref, kCGInterpolationHigh);
    CGContextSetFillColorWithColor(ref, [[UIColor redColor] CGColor]);
    CGContextFillRect(ref, {{0,0}, {17, 17}});
    CGImageRef im = CGBitmapContextCreateImage(ref);
    CGContextRelease(ref);
    fakeImage = [UIImage imageWithCGImage:im scale:1.0 orientation:UIImageOrientationUp];
    CGImageRelease(im);
  });
  return fakeImage;
}

- (void)testButtonWithTitle
{
  CKButtonComponent *b = [CKButtonComponent
                          newWithAction:{}
                          options:{
                            .titles = @"Hello World",
                          }
                         ];
  CKSizeRange size;
  CKSnapshotVerifyComponent(b, size, nil);
}

- (void)testButtonWithImage
{
  CKButtonComponent *b = [CKButtonComponent
                          newWithAction:{}
                          options:{
                            .images = fakeImage(),
                          }
                         ];
  CKSizeRange size;
  CKSnapshotVerifyComponent(b, size, nil);
}

- (void)testButtonWithTitleAndImage
{
  CKButtonComponent *b = [CKButtonComponent
                          newWithAction:{}
                          options:{
                            .titles = @"Hello World",
                            .images = fakeImage(),
                          }
                         ];
  CKSizeRange size;
  CKSnapshotVerifyComponent(b, size, nil);
}

- (void)testButtonWithTitleAndImageAndContentEdgeInsets
{
  NSValue *insets = [NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
  CKButtonComponent *b = [CKButtonComponent
                          newWithAction:{}
                          options:{
                            .titles = @"Hello World",
                            .images = fakeImage(),
                            .attributes = {{@selector(setContentEdgeInsets:), insets}},
                          }
                         ];
  CKSizeRange size;
  CKSnapshotVerifyComponent(b, size, nil);
}

- (void)testButtonStates
{
  std::unordered_map<UIControlState, UIColor *> titleColors = {
    {UIControlStateNormal, [UIColor blackColor]},
    {UIControlStateHighlighted, [UIColor redColor]},
    {UIControlStateSelected, [UIColor blueColor]},
    {UIControlStateDisabled, [UIColor greenColor]},
    {UIControlStateDisabled|UIControlStateSelected, [UIColor yellowColor]},
    {UIControlStateSelected|UIControlStateHighlighted, [UIColor orangeColor]},
  };
  CKSizeRange size;

  CKButtonComponent *normal = [CKButtonComponent
                               newWithAction:{}
                               options:{
                                 .titles = @"Hello",
                                 .titleColors = titleColors,
                               }
                              ];
  CKSnapshotVerifyComponent(normal, size, @"normal");

  CKButtonComponent *hi = [CKButtonComponent
                           newWithAction:{}
                           options:{
                             .titles = @"Hello",
                             .titleColors = titleColors,
                             .attributes = {{@selector(setHighlighted:), @YES}},
                           }
                          ];
  CKSnapshotVerifyComponent(hi, size, @"highlighted");

  CKButtonComponent *sel = [CKButtonComponent
                            newWithAction:{}
                            options:{
                              .titles = @"Hello",
                              .titleColors = titleColors,
                              .selected = YES,
                            }
                           ];
  CKSnapshotVerifyComponent(sel, size, @"selected");

  CKButtonComponent *dis = [CKButtonComponent
                            newWithAction:{}
                            options:{
                              .titles = @"Hello",
                              .titleColors = titleColors,
                              .enabled = NO,
                            }
                           ];
  CKSnapshotVerifyComponent(dis, size, @"disabled");

  CKButtonComponent *dissel = [CKButtonComponent
                               newWithAction:{}
                               options:{
                                 .titles = @"Hello",
                                 .titleColors = titleColors,
                                 .selected = YES,
                                 .enabled = NO,
                               }
                              ];
  CKSnapshotVerifyComponent(dissel, size, @"disabled_selected");

  CKButtonComponent *selhi = [CKButtonComponent
                              newWithAction:{}
                              options:{
                                .titles = @"Hello",
                                .titleColors = titleColors,
                                .selected = YES,
                                .attributes = {{@selector(setHighlighted:), @YES}},
                              }
                             ];
  CKSnapshotVerifyComponent(selhi, size, @"selected_highlighted");
}

@end
