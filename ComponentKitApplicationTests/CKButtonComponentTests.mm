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
//  self.recordMode = YES;
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

    CGContextSetAllowsAntialiasing(ref, true);
    CGContextSetInterpolationQuality(ref, kCGInterpolationHigh);
    CGContextSetFillColorWithColor(ref, [[UIColor redColor] CGColor]);
    CGContextFillRect(ref, {CGPointZero, size});
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
  CKSnapshotVerifyComponentAndIntrinsicSize(b, size, nil);
}

- (void)testButtonWithAttributedTitle
{
  NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:@"Menlo" size:17.0f]};
  NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:@"Hello World" attributes:attributes];
  
  [attributedTitle setAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"Menlo-Bold" size:24.0f],
                                   NSForegroundColorAttributeName: [UIColor greenColor]}
                           range:NSMakeRange(6, 5)];
  
  CKButtonComponent *b = [CKButtonComponent newWithTitles:{{UIControlStateNormal, attributedTitle}}
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
  CKSnapshotVerifyComponentAndIntrinsicSize(b, size, nil);
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
  CKSnapshotVerifyComponentAndIntrinsicSize(b, size, nil);
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
  CKSnapshotVerifyComponentAndIntrinsicSize(b, size, nil);
}

- (void)testButtonWithAttributedTitleAndImage
{
  NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:@"Hello World" attributes:@{}];
  
  [attributedTitle setAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12.0f weight:UIFontWeightLight],
                                   NSForegroundColorAttributeName: [UIColor whiteColor]}
                           range:NSMakeRange(6, 5)];
  
  CKButtonComponent *b = [CKButtonComponent newWithTitles:{{UIControlStateNormal, attributedTitle}}
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
  CKSnapshotVerifyComponentAndIntrinsicSize(b, size, nil);
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
  CKSnapshotVerifyComponentAndIntrinsicSize(b, size, nil);
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
  CKSnapshotVerifyComponentAndIntrinsicSize(normal, size, @"normal");

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
  CKSnapshotVerifyComponentAndIntrinsicSize(hi, size, @"highlighted");

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
  CKSnapshotVerifyComponentAndIntrinsicSize(sel, size, @"selected");

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
  CKSnapshotVerifyComponentAndIntrinsicSize(dis, size, @"disabled");

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
  CKSnapshotVerifyComponentAndIntrinsicSize(dissel, size, @"disabled_selected");

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
  CKSnapshotVerifyComponentAndIntrinsicSize(selhi, size, @"selected_highlighted");
}

@end
