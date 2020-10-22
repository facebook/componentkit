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

#import <ComponentSnapshotTestCase/CKComponentSnapshotTestCase.h>

#import <ComponentKit/CKBackgroundLayoutComponent.h>
#import <ComponentKit/CKCenterLayoutComponent.h>
#import <ComponentKit/CKFlexboxComponent.h>

static const CKSizeRange kSize = {{100, 120}, {320, 160}};

@interface CKCenterLayoutComponentsTests : CKComponentSnapshotTestCase

@end

@implementation CKCenterLayoutComponentsTests

- (void)setUp
{
  [super setUp];
  self.recordMode = NO;
}

- (void)testWithOptions
{
  [self testWithCenteringOptions:CKCenterLayoutComponentCenteringNone sizingOptions:{}];
  [self testWithCenteringOptions:CKCenterLayoutComponentCenteringXY sizingOptions:{}];
  [self testWithCenteringOptions:CKCenterLayoutComponentCenteringX sizingOptions:{}];
  [self testWithCenteringOptions:CKCenterLayoutComponentCenteringY sizingOptions:{}];
}

- (void)testWithSizingOptions
{
  [self testWithCenteringOptions:CKCenterLayoutComponentCenteringNone sizingOptions:CKCenterLayoutComponentSizingOptionDefault];
  [self testWithCenteringOptions:CKCenterLayoutComponentCenteringNone sizingOptions:CKCenterLayoutComponentSizingOptionMinimumX];
  [self testWithCenteringOptions:CKCenterLayoutComponentCenteringNone sizingOptions:CKCenterLayoutComponentSizingOptionMinimumY];
  [self testWithCenteringOptions:CKCenterLayoutComponentCenteringNone sizingOptions:CKCenterLayoutComponentSizingOptionMinimumXY];
}

- (void)testWithCenteringOptions:(CKCenterLayoutComponentCenteringOptions)options
                   sizingOptions:(CKCenterLayoutComponentSizingOptions)sizingOptions
{
  CKComponent *c = CK::BackgroundLayoutComponentBuilder()
                    .component(
                      CK::CenterLayoutComponentBuilder()
                        .centeringOptions(options)
                        .sizingOptions(sizingOptions)
                        .child(CK::ComponentBuilder()
                          .viewClass(UIView.class)
                          .backgroundColor(UIColor.greenColor)
                          .width(70)
                          .height(100)
                          .build())
                        .build())
                    .background(CK::ComponentBuilder()
                      .viewClass(UIView.class)
                      .backgroundColor(UIColor.redColor)
                      .build())
                    .build();

  CKSnapshotVerifyComponent(c, kSize, suffixForCenteringOptions(options, sizingOptions));
}

static NSString *suffixForCenteringOptions(CKCenterLayoutComponentCenteringOptions centeringOptions,
                                           CKCenterLayoutComponentSizingOptions sizingOptinos)
{
  NSMutableString *suffix = [NSMutableString string];

  if ((centeringOptions & CKCenterLayoutComponentCenteringX) != 0) {
    [suffix appendString:@"CenteringX"];
  }

  if ((centeringOptions & CKCenterLayoutComponentCenteringY) != 0) {
    [suffix appendString:@"CenteringY"];
  }

  if ((sizingOptinos & CKCenterLayoutComponentSizingOptionMinimumX) != 0) {
    [suffix appendString:@"SizingMinimumX"];
  }

  if ((sizingOptinos & CKCenterLayoutComponentSizingOptionMinimumY) != 0) {
    [suffix appendString:@"SizingMinimumY"];
  }

  return suffix;
}

- (void)testMinimumSizeRangeIsGivenToChildWhenNotCentering
{
  const auto c =
  CK::CenterLayoutComponentBuilder()
   .centeringOptions(CKCenterLayoutComponentCenteringNone)
   .child(CK::BackgroundLayoutComponentBuilder()
     .component(CK::FlexboxComponentBuilder()
       .alignItems(CKFlexboxAlignItemsStart)
       .child(CK::ComponentBuilder()
         .viewClass(UIView.class)
         .backgroundColor(UIColor.redColor)
         .width(10)
         .height(10)
         .build())
       .flexGrow(1)
       .build())
     .background(CK::ComponentBuilder()
       .viewClass(UIView.class)
       .backgroundColor(UIColor.redColor)
       .build())
     .build())
   .build();
  CKSnapshotVerifyComponent(c, kSize, nil);
}

@end
