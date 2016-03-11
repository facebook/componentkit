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
  CKButtonComponent *b = [CKButtonComponent newWithTitles:{{UIControlStateNormal, @"Hello World"}}
                                              titleColors:{}
                                                   images:{}
                                         backgroundImages:{}
                                                titleFont:nil
                                                 selected:NO
                                                  enabled:YES
                                                   action:{}
                                                     size:{}
                                               attributes:{}
                               accessibilityConfiguration:{}];
  CKSizeRange size;
  CKSnapshotVerifyComponent(b, size, nil);
}

- (void)testButtonWithImage
{
  CKButtonComponent *b = [CKButtonComponent newWithTitles:{}
                                              titleColors:{}
                                                   images:{{UIControlStateNormal, fakeImage()}}
                                         backgroundImages:{}
                                                titleFont:nil
                                                 selected:NO
                                                  enabled:YES
                                                   action:{}
                                                     size:{}
                                               attributes:{}
                               accessibilityConfiguration:{}];
  CKSizeRange size;
  CKSnapshotVerifyComponent(b, size, nil);
}

- (void)testButtonWithTitleAndImage
{
  CKButtonComponent *b = [CKButtonComponent newWithTitles:{{UIControlStateNormal, @"Hello World"}}
                                              titleColors:{}
                                                   images:{{UIControlStateNormal, fakeImage()}}
                                         backgroundImages:{}
                                                titleFont:nil
                                                 selected:NO
                                                  enabled:YES
                                                   action:{}
                                                     size:{}
                                               attributes:{}
                               accessibilityConfiguration:{}];
  CKSizeRange size;
  CKSnapshotVerifyComponent(b, size, nil);
}

- (void)testButtonWithTitleAndImageAndContentEdgeInsets
{
  NSValue *insets = [NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
  CKButtonComponent *b = [CKButtonComponent newWithTitles:{{UIControlStateNormal, @"Hello World"}}
                                              titleColors:{}
                                                   images:{{UIControlStateNormal, fakeImage()}}
                                         backgroundImages:{}
                                                titleFont:nil
                                                 selected:NO
                                                  enabled:YES
                                                   action:{}
                                                     size:{}
                                               attributes:{{@selector(setContentEdgeInsets:), insets}}
                               accessibilityConfiguration:{}];
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

  CKButtonComponent *normal = [CKButtonComponent newWithTitles:{{UIControlStateNormal, @"Hello"}}
                                                   titleColors:titleColors
                                                        images:{}
                                              backgroundImages:{}
                                                     titleFont:nil
                                                      selected:NO
                                                       enabled:YES
                                                        action:{}
                                                          size:{}
                                                    attributes:{}
                                    accessibilityConfiguration:{}];
  CKSnapshotVerifyComponent(normal, size, @"normal");

  CKButtonComponent *hi = [CKButtonComponent newWithTitles:{{UIControlStateNormal, @"Hello"}}
                                               titleColors:titleColors
                                                    images:{}
                                          backgroundImages:{}
                                                 titleFont:nil
                                                  selected:NO
                                                   enabled:YES
                                                    action:{}
                                                      size:{}
                                                attributes:{{@selector(setHighlighted:), @YES}}
                                accessibilityConfiguration:{}];
  CKSnapshotVerifyComponent(hi, size, @"highlighted");

  CKButtonComponent *sel = [CKButtonComponent newWithTitles:{{UIControlStateNormal, @"Hello"}}
                                                titleColors:titleColors
                                                     images:{}
                                           backgroundImages:{}
                                                  titleFont:nil
                                                   selected:YES
                                                    enabled:YES
                                                     action:{}
                                                       size:{}
                                                 attributes:{}
                                 accessibilityConfiguration:{}];
  CKSnapshotVerifyComponent(sel, size, @"selected");

  CKButtonComponent *dis = [CKButtonComponent newWithTitles:{{UIControlStateNormal, @"Hello"}}
                                                titleColors:titleColors
                                                     images:{}
                                           backgroundImages:{}
                                                  titleFont:nil
                                                   selected:NO
                                                    enabled:NO
                                                     action:{}
                                                       size:{}
                                                 attributes:{}
                                 accessibilityConfiguration:{}];
  CKSnapshotVerifyComponent(dis, size, @"disabled");

  CKButtonComponent *dissel = [CKButtonComponent newWithTitles:{{UIControlStateNormal, @"Hello"}}
                                                   titleColors:titleColors
                                                        images:{}
                                              backgroundImages:{}
                                                     titleFont:nil
                                                      selected:YES
                                                       enabled:NO
                                                        action:{}
                                                          size:{}
                                                    attributes:{}
                                    accessibilityConfiguration:{}];
  CKSnapshotVerifyComponent(dissel, size, @"disabled_selected");

  CKButtonComponent *selhi = [CKButtonComponent newWithTitles:{{UIControlStateNormal, @"Hello"}}
                                                  titleColors:titleColors
                                                       images:{}
                                             backgroundImages:{}
                                                    titleFont:nil
                                                     selected:YES
                                                      enabled:YES
                                                       action:{}
                                                         size:{}
                                                   attributes:{{@selector(setHighlighted:), @YES}}
                                   accessibilityConfiguration:{}];
  CKSnapshotVerifyComponent(selhi, size, @"selected_highlighted");
}

@end
