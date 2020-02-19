/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

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
  auto const b =
  CK::ButtonComponentBuilder()
  .action(nullptr)
  .title(@"Hello World")
  .build();

  CKSizeRange size;
  CKSnapshotVerifyComponent(b, size, nil);
}

- (void)testButtonWithTitleAndTitleEdgeInsets
{
  auto const b =
  CK::ButtonComponentBuilder()
  .action({})
  .title(@"Hello World")
  .titleEdgeInsets(UIEdgeInsetsMake(10, 10, 10, 10))
  .build();
  CKSizeRange size;
  CKSnapshotVerifyComponent(b, size, nil);
}

- (void)testButtonWithImage
{
  auto const b =
  CK::ButtonComponentBuilder()
  .action({})
  .image(fakeImage())
  .build();
  CKSizeRange size;
  CKSnapshotVerifyComponent(b, size, nil);
}

- (void)testButtonWithImageAndImageEdgeInsets
{
  auto const b =
  CK::ButtonComponentBuilder()
  .action({})
  .image(fakeImage())
  .imageEdgeInsets(UIEdgeInsetsMake(10, 10, 10, 10))
  .build();
  CKSizeRange size;
  CKSnapshotVerifyComponent(b, size, nil);
}

- (void)testButtonWithTitleAndImage
{
  auto const b =
  CK::ButtonComponentBuilder()
  .action(nullptr)
  .title(@"Hello World")
  .image(fakeImage())
  .build();

  CKSizeRange size;
  CKSnapshotVerifyComponent(b, size, nil);
}

- (void)testButtonWithTitleAndImageWithImageEdgeInsets
{
  auto const b =
  CK::ButtonComponentBuilder()
  .action({})
  .title(@"Hello World")
  .image(fakeImage())
  .imageEdgeInsets(UIEdgeInsetsMake(10, 10, 10, 10))
  .build();
  CKSizeRange size;
  CKSnapshotVerifyComponent(b, size, nil);
}

- (void)testButtonWithTitleAndImageWithTitleEdgeInsets
{
  auto const b =
  CK::ButtonComponentBuilder()
  .action({})
  .title(@"Hello World")
  .image(fakeImage())
  .titleEdgeInsets(UIEdgeInsetsMake(10, 10, 10, 10))
  .build();
  CKSizeRange size;
  CKSnapshotVerifyComponent(b, size, nil);
}

- (void)testButtonWithTitleAndImageWithTitleEdgeInsetsAndImageEdgeInsets
{
  auto const b =
  CK::ButtonComponentBuilder()
  .action({})
  .title(@"Hello World")
  .image(fakeImage())
  .titleEdgeInsets(UIEdgeInsetsMake(10, 10, 10, 10))
  .imageEdgeInsets(UIEdgeInsetsMake(20, 20, 20, 20))
  .build();
  CKSizeRange size;
  CKSnapshotVerifyComponent(b, size, nil);
}

- (void)testButtonWithTitleAndImageAndContentEdgeInsets
{
  auto const b =
  CK::ButtonComponentBuilder()
  .action({})
  .title(@"Hello World")
  .image(fakeImage())
  .contentEdgeInsets(UIEdgeInsetsMake(10, 10, 10, 10))
  .build();
  CKSizeRange size;
  CKSnapshotVerifyComponent(b, size, nil);
}

- (void)testButtonWithTitleAndImageAndContentEdgeInsetsAndTitleEdgeInsetsAndImageEdgeInsets
{
  auto const b =
  CK::ButtonComponentBuilder()
  .action({})
  .title(@"Hello World")
  .image(fakeImage())
  .contentEdgeInsets(UIEdgeInsetsMake(10, 10, 10, 10))
  .titleEdgeInsets(UIEdgeInsetsMake(20, 20, 20, 20))
  .imageEdgeInsets(UIEdgeInsetsMake(10, 10, 10, 10))
  .build();
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

  auto const normal =
  CK::ButtonComponentBuilder()
  .action({})
  .title(@"Hello")
  .titleColors(titleColors)
  .build();
  CKSnapshotVerifyComponent(normal, size, @"normal");

  auto const hi =
  CK::ButtonComponentBuilder()
  .action({})
  .title(@"Hello")
  .titleColors(titleColors)
  .attribute(@selector(setHighlighted:), YES)
  .build();
  CKSnapshotVerifyComponent(hi, size, @"highlighted");

  auto const sel =
  CK::ButtonComponentBuilder()
  .action({})
  .title(@"Hello")
  .titleColors(titleColors)
  .selected(YES)
  .build();
  CKSnapshotVerifyComponent(sel, size, @"selected");

  auto const dis =
  CK::ButtonComponentBuilder()
  .action({})
  .title(@"Hello")
  .titleColors(titleColors)
  .enabled(NO)
  .build();
  CKSnapshotVerifyComponent(dis, size, @"disabled");

  auto const dissel =
  CK::ButtonComponentBuilder()
  .action({})
  .title(@"Hello")
  .titleColors(titleColors)
  .selected(YES)
  .enabled(NO)
  .build();
  CKSnapshotVerifyComponent(dissel, size, @"disabled_selected");

  auto const selhi =
  CK::ButtonComponentBuilder()
  .action({})
  .title(@"Hello")
  .titleColors(titleColors)
  .selected(YES)
  .attribute(@selector(setHighlighted:), YES)
  .build();
  CKSnapshotVerifyComponent(selhi, size, @"selected_highlighted");
}

- (void)testUIButtonEdgeInsetsDefaultValues
{
  UIButton const *button = [UIButton buttonWithType:UIButtonTypeSystem];
  button.frame = CGRectMake(0, 0, 100, 100);
  [button setImage:fakeImage() forState:UIControlStateNormal];
  [button setTitle:@"Title label" forState:UIControlStateNormal];
  const CKButtonComponentOptions options = CKButtonComponentOptions();

  XCTAssertTrue([NSStringFromUIEdgeInsets(button.contentEdgeInsets)
  isEqualToString:NSStringFromUIEdgeInsets(options.contentEdgeInsets)],
                  @"iOS has changed the default value of contentEdgeInsets");

  XCTAssertTrue([NSStringFromUIEdgeInsets(button.titleEdgeInsets)
  isEqualToString:NSStringFromUIEdgeInsets(options.titleEdgeInsets)],
                  @"iOS has changed the default value of titleEdgeInsets");

  XCTAssertTrue([NSStringFromUIEdgeInsets(button.imageEdgeInsets)
  isEqualToString:NSStringFromUIEdgeInsets(options.imageEdgeInsets)],
                  @"iOS has changed the default value of imageEdgeInsets");
}
@end
