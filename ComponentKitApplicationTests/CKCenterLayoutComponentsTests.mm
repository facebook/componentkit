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
  CKComponent *c = [CKBackgroundLayoutComponent
                    newWithComponent:
                    [CKCenterLayoutComponent
                     newWithCenteringOptions:options
                     sizingOptions:sizingOptions
                     child:[CKComponent
                            newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}}
                            size:{70.0, 100.0}]
                     size:{}]
                    background:
                    [CKComponent
                     newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}}
                     size:{}]];

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
  CKCenterLayoutComponent *c =
  [CKCenterLayoutComponent
   newWithCenteringOptions:CKCenterLayoutComponentCenteringNone
   sizingOptions:{}
   child:
   [CKBackgroundLayoutComponent
    newWithComponent:
    [CKFlexboxComponent
     newWithView:{}
     size:{}
     style:{.alignItems = CKFlexboxAlignItemsStart}
     children:{
       {
         [CKComponent
          newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}}
          size:{10,10}],
         .flexGrow = 1,
       }
     }]
    background:
    [CKComponent
     newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}}
     size:{}]]
   size:{}];
  CKSnapshotVerifyComponent(c, kSize, nil);
}

@end
