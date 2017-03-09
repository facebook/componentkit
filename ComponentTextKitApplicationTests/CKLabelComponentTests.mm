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

#import <ComponentKit/CKLabelComponent.h>

static const CKSizeRange kFlexibleSize = {{0, 0}, {320, 100}};

static const CKSizeRange kStrictSize = {{320, 100}, {320, 100}};

static const CKSizeRange kUnrestrictedSize = {};

@interface CKLabelComponentTests : CKComponentSnapshotTestCase

@end

@implementation CKLabelComponentTests

- (void)setUp
{
  [super setUp];
  self.recordMode = NO;
}

- (void)testSimpleLabelInFlexibleContainer
{
  CKLabelComponent *labelComponent =
  [CKLabelComponent
   newWithLabelAttributes:{
     .string = @"Hello!"
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   size:{ }];
  CKSnapshotVerifyComponent(labelComponent, kFlexibleSize, @"");
}

- (void)testSimpleLabelInUnrestrictedContainer
{
  CKLabelComponent *labelComponent =
  [CKLabelComponent
   newWithLabelAttributes:{
     .string = @"Hello!"
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   size:{ }];
  CKSnapshotVerifyComponent(labelComponent, kUnrestrictedSize, @"");
}

- (void)testCenteredLabelInStrictContainer
{
  CKLabelComponent *labelComponent =
  [CKLabelComponent
   newWithLabelAttributes:{
     .string = @"Hello!",
     .alignment = NSTextAlignmentCenter
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   size:{ }];
  CKSnapshotVerifyComponent(labelComponent, kStrictSize, @"");
}

- (void)testRightAlignedLabelInStrictContainer
{
  CKLabelComponent *labelComponent =
  [CKLabelComponent
   newWithLabelAttributes:{
     .string = @"Hello!",
     .alignment = NSTextAlignmentRight
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   size:{ }];
  CKSnapshotVerifyComponent(labelComponent, kStrictSize, @"");
}

- (void)testCenteredLabelInFlexibleContainer
{
  CKLabelComponent *labelComponent =
  [CKLabelComponent
   newWithLabelAttributes:{
     .string = @"Hello!",
     .alignment = NSTextAlignmentCenter
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   size:{ }];
  CKSnapshotVerifyComponent(labelComponent, kFlexibleSize, @"");
}

- (void)testRightAlignedLabelInFlexibleContainer
{
  CKLabelComponent *labelComponent =
  [CKLabelComponent
   newWithLabelAttributes:{
     .string = @"Hello!",
     .alignment = NSTextAlignmentRight
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   size:{ }];
  CKSnapshotVerifyComponent(labelComponent, kFlexibleSize, @"");
}

- (void)testSettingFont
{
  CKLabelComponent *labelComponent =
  [CKLabelComponent
   newWithLabelAttributes:{
     .string = @"Hello!",
     .font = [UIFont fontWithName:@"Zapfino" size:15]
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   size:{ }];
  CKSnapshotVerifyComponent(labelComponent, kFlexibleSize, @"");
}

- (void)testSettingColor
{
  CKLabelComponent *labelComponent =
  [CKLabelComponent
   newWithLabelAttributes:{
     .string = @"Hello!",
     .color = [UIColor blueColor]
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   size:{ }];
  CKSnapshotVerifyComponent(labelComponent, kFlexibleSize, @"");
}

- (void)testShadowsAppear
{
  CKLabelComponent *labelComponent =
  [CKLabelComponent
   newWithLabelAttributes:{
     .string = @"Hello!",
     .shadowOffset = {1, 1},
     .shadowColor = [UIColor redColor],
     .shadowOpacity = 0.5,
     .shadowRadius = 5
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   size:{ }];
  CKSnapshotVerifyComponent(labelComponent, kFlexibleSize, @"");
}

- (void)testShadowOffsetsDontClipDownwardsAndRightwards
{
  CKLabelComponent *labelComponent =
  [CKLabelComponent
   newWithLabelAttributes:{
     .string = @"Hello!",
     .shadowOffset = {10, 10},
     .shadowColor = [UIColor redColor],
     .shadowOpacity = 1,
     .shadowRadius = 1
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   size:{ }];
  CKSnapshotVerifyComponent(labelComponent, kFlexibleSize, @"");
}

- (void)testShadowOffsetsDontClipUpwardsAndLeftwards
{
  CKLabelComponent *labelComponent =
  [CKLabelComponent
   newWithLabelAttributes:{
     .string = @"Hello!",
     .shadowOffset = {-10, -10},
     .shadowColor = [UIColor redColor],
     .shadowOpacity = 1,
     .shadowRadius = 1
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   size:{ }];
  CKSnapshotVerifyComponent(labelComponent, kFlexibleSize, @"");
}

- (void)testTruncationStringAppears
{
  CKLabelComponent *labelComponent =
  [CKLabelComponent
   newWithLabelAttributes:{
     .string = @"90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony. 90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony. 90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony.",
     .truncationString = @"..."
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   size:{ }];
  CKSnapshotVerifyComponent(labelComponent, kFlexibleSize, @"");
}

- (void)testTruncationStringStyledSameAsString
{
  CKLabelComponent *labelComponent =
  [CKLabelComponent
   newWithLabelAttributes:{
     .string = @"90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony. 90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony. 90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony.",
     .truncationString = @" truncated",
     .color = [UIColor blueColor],
     .font = [UIFont fontWithName:@"Zapfino" size:12]
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   size:{ }];
  CKSnapshotVerifyComponent(labelComponent, kFlexibleSize, @"");
}

- (void)testMaximumNumberOfLines
{
  CKLabelComponent *labelComponent =
  [CKLabelComponent
   newWithLabelAttributes:{
     .string = @"90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony. 90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony. 90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony.",
     .maximumNumberOfLines = 2
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   size:{ }];
  CKSnapshotVerifyComponent(labelComponent, kFlexibleSize, @"");
}

- (void)testMaximumNumberOfLinesWithTruncationString
{
  CKLabelComponent *labelComponent =
  [CKLabelComponent
   newWithLabelAttributes:{
     .string = @"90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony. 90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony. 90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony.",
     .maximumNumberOfLines = 2,
     .truncationString = @"..."
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   size:{ }];
  CKSnapshotVerifyComponent(labelComponent, kFlexibleSize, @"");
}

- (void)testFirstLineHeadIndent
{
  CKLabelComponent *labelComponent =
  [CKLabelComponent
   newWithLabelAttributes:{
     .string = @"90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony. 90's cray photo booth tote bag bespoke Carles.\nPlaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony. 90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony.",
     .firstLineHeadIndent = 50,
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   size:{ }];
  CKSnapshotVerifyComponent(labelComponent, kFlexibleSize, @"");
}

- (void)testHeadIndent
{
  CKLabelComponent *labelComponent =
  [CKLabelComponent
   newWithLabelAttributes:{
     .string = @"90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony. 90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony. 90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony.",
     .headIndent = 50,
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   size:{ }];
  CKSnapshotVerifyComponent(labelComponent, kFlexibleSize, @"");
}

- (void)testTailIndent
{
  CKLabelComponent *labelComponent =
  [CKLabelComponent
   newWithLabelAttributes:{
     .string = @"90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony. 90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony. 90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony.",
     .tailIndent = 10,
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   size:{ }];
  CKSnapshotVerifyComponent(labelComponent, kFlexibleSize, @"");
}

- (void)testLineHeightMultiple
{
  CKLabelComponent *labelComponent =
  [CKLabelComponent
   newWithLabelAttributes:{
     .string = @"90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony. 90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony. 90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony.",
     .lineHeightMultiple = 1.5
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   size:{ }];
  CKSnapshotVerifyComponent(labelComponent, kFlexibleSize, @"");
}

- (void)testLineSpacing
{
  CKLabelComponent *labelComponent =
  [CKLabelComponent
   newWithLabelAttributes:{
     .string = @"90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony. 90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony. 90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony.",
     .lineSpacing = 10
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   size:{ }];
  CKSnapshotVerifyComponent(labelComponent, kFlexibleSize, @"");
}

- (void)testParagraphSpacing
{
  CKLabelComponent *labelComponent =
  [CKLabelComponent
   newWithLabelAttributes:{
     .string = @"90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony. 90's cray photo booth tote bag bespoke Carles.\nPlaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony. 90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony.",
     .paragraphSpacing = 20,
     .font = [UIFont systemFontOfSize:8]
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   size:{ }];
  CKSnapshotVerifyComponent(labelComponent, kFlexibleSize, @"");
}

- (void)testLineBreakModeCharWrap
{
  CKLabelComponent *labelComponent =
  [CKLabelComponent
   newWithLabelAttributes:{
     .string = @"90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony. 90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony. 90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony.",
     .lineBreakMode = NSLineBreakByCharWrapping
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   size:{ }];
  CKSnapshotVerifyComponent(labelComponent, kFlexibleSize, @"");
}

- (void)testLineBreakModeTruncatingTail
{
  CKLabelComponent *labelComponent =
  [CKLabelComponent
   newWithLabelAttributes:{
     .string = @"90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony. 90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony. 90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony.",
     .lineBreakMode = NSLineBreakByTruncatingTail
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   size:{ }];
  CKSnapshotVerifyComponent(labelComponent, kFlexibleSize, @"");
}

- (void)testLineBreakModeTruncatingMiddle
{
  CKLabelComponent *labelComponent =
  [CKLabelComponent
   newWithLabelAttributes:{
     .string = @"90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony. 90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony. 90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony.",
     .lineBreakMode = NSLineBreakByTruncatingMiddle
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   size:{ }];
  CKSnapshotVerifyComponent(labelComponent, kFlexibleSize, @"");
}

- (void)testLineBreakModeTruncatingClipping
{
  CKLabelComponent *labelComponent =
  [CKLabelComponent
   newWithLabelAttributes:{
     .string = @"90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony. 90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony. 90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony.",
     .lineBreakMode = NSLineBreakByClipping
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   size:{ }];
  CKSnapshotVerifyComponent(labelComponent, kFlexibleSize, @"");
}

- (void)testRightAlignedSingleLineTruncation
{
  CKLabelComponent *labelComponent =
  [CKLabelComponent
   newWithLabelAttributes:{
     .string = @"90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony. 90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony. 90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony.",
     .truncationString = @"... more",
     .maximumNumberOfLines = 1,
     .alignment = NSTextAlignmentRight
   }
   viewAttributes:{
     {@selector(setBackgroundColor:),[UIColor clearColor]}
   }
   size:{ }];
  CKSnapshotVerifyComponent(labelComponent, kFlexibleSize, @"");
}

@end
