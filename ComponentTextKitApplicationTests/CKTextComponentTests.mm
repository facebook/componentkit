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

#import <ComponentKit/CKTextComponent.h>

static const CKSizeRange kFlexibleSize = {{0, 0}, {320, 100}};

static const CKSizeRange kStrictSize = {{320, 100}, {320, 100}};

static const CKSizeRange kUnrestrictedSize = {};

static NSParagraphStyle *rtlWritingDirectionParagraphStyle() {
  // We have to manually specify this because NSWritingDirectionNatural doesn't actually do what is advertised in the
  // headers.
  NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
  ps.alignment = NSTextAlignmentNatural;
  ps.baseWritingDirection = NSWritingDirectionRightToLeft;
  return ps;
}

@interface CKTextComponentTestLayoutManager : NSLayoutManager

@end

@implementation CKTextComponentTestLayoutManager

- (void)fillBackgroundRectArray:(const CGRect *)rectArray count:(NSUInteger)rectCount forCharacterRange:(NSRange)charRange color:(UIColor *)color
{
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  CGContextSetFillColorWithColor(ctx, [UIColor redColor].CGColor);
  CGContextFillRects(ctx, rectArray, rectCount);
}

@end

static NSLayoutManager *testLayoutManagerFactory(void) {
  return [[CKTextComponentTestLayoutManager alloc] init];
}

@interface CKTextComponentTests : CKComponentSnapshotTestCase

@end

@implementation CKTextComponentTests

- (void)setUp
{
  [super setUp];
  self.recordMode = NO;
}

- (void)testSimpleString
{
  CKTextComponent *c =
  [CKTextComponent
   newWithTextAttributes:{
     [[NSAttributedString
       alloc]
      initWithString:@"CKTextComponent"]
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   options:{ }
   size:{ }];
  CKSnapshotVerifyComponent(c, kFlexibleSize, @"");
}

- (void)testSimpleRTLString
{
  CKTextComponent *c =
  [CKTextComponent
   newWithTextAttributes:{
     [[NSAttributedString
       alloc]
      initWithString:@"\u05E8\u05DB\u05D9\u05D1 \u05D8\u05E7\u05E1\u05D8"
      attributes:@{NSParagraphStyleAttributeName : rtlWritingDirectionParagraphStyle()}]
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   options:{ }
   size:{ }];
  CKSnapshotVerifyComponent(c, kFlexibleSize, @"");
}

- (void)testSimpleShadowedString
{
  CKTextComponent *c =
  [CKTextComponent
   newWithTextAttributes:{
     .attributedString =
     [[NSAttributedString
       alloc]
      initWithString:@"CKTextComponent"],
     .shadowColor = [UIColor blackColor],
     .shadowOpacity = 1,
     .shadowOffset = CGSizeMake(1, 1),
     .shadowRadius = 4
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   options:{ }
   size:{ }];
  CKSnapshotVerifyComponent(c, kFlexibleSize, @"");
}

- (void)testMultilineString
{
  CKTextComponent *c =
  [CKTextComponent
   newWithTextAttributes:{
     [[NSAttributedString
       alloc]
      initWithString:@"90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony."]
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   options:{ }
   size:{ }];
  CKSnapshotVerifyComponent(c, kFlexibleSize, @"");
}

- (void)testMultilineRTLString
{
  CKTextComponent *c =
  [CKTextComponent
   newWithTextAttributes:{
     [[NSAttributedString
       alloc]
      initWithString:@"\u05EA\u05D9\u05E7 \u05EA\u05D0\n\u0645\u0643\u0648\u0646 \u0627\u0644\u0646\u0635\n \u05E6\u05D9\u05DC\u05D5\u05DD \u05D4\u05E2\u05D9\u05D3 \u05E7\u05E8\u05DC\u05E1 \u05D7\u05D5\u05EA\u05DC\u05D5\u05EA \u05DC\u05D8\u05D4\u05E8 \u05D0\u05D3\u05D5\u05DF \u05E2\u05D5\u05D1\u05E8\u05D9 \u05D0\u05D5\u05E8\u05D7 \u05DE\u05E9\u05D5\u05D1\u05E5 \u05DE\u05E7\u05D5\u05E2\u05E7\u05E2 \u05D8\u05D5\u05E1\u05D8 \u05D0\u05E8\u05D1\u05E2\u05D4 \u05D3\u05D5\u05DC\u05E8 \u05DB\u05E8\u05D5\u05D1 \u05D0\u05E6\u05D5\u05D5\u05D4 \u05E7\u05D8\u05DF \u05E9\u05D1\u05D1\u05D9 \u05EA\u05D0 \u05E6\u05D9\u05DC\u05D5\u05DD \u05DC\u05DB\u05D1\u05D5\u05E9 \u05DE\u05E9\u05D5\u05D1\u05E5 \u05DE\u05E7\u05D5\u05E2\u05E7\u05E2 \u05D8\u05D5\u05E1\u05D8 \u05D0\u05E8\u05D1\u05E2\u05D4 \u05D3\u05D5\u05DC\u05E8 \u05DB\u05E8\u05D5\u05D1 \u05D0\u05E6\u05D5\u05D5\u05D4 \u05E7\u05D8\u05DF \u05E9\u05D1\u05D1\u05D9 \u05EA\u05D0 \u05E6\u05D9\u05DC\u05D5\u05DD \u05DC\u05DB\u05D1\u05D5\u05E9"
      attributes:@{NSParagraphStyleAttributeName : rtlWritingDirectionParagraphStyle()}]
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   options:{ }
   size:{ }];
  CKSnapshotVerifyComponent(c, kFlexibleSize, @"");
}

- (void)testMaximumNumberOfLines
{
  CKTextComponent *c =
  [CKTextComponent
   newWithTextAttributes:{
     .attributedString =
     [[NSAttributedString
       alloc]
      initWithString:@"90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony."],
     .maximumNumberOfLines = 2
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   options:{ }
   size:{ }];
  CKSnapshotVerifyComponent(c, kFlexibleSize, @"");
}

- (void)testMaximumNumberOfLinesWithTruncationString
{
  CKTextComponent *c =
  [CKTextComponent
   newWithTextAttributes:{
     .attributedString =
     [[NSAttributedString
       alloc]
      initWithString:@"90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony."],
     .maximumNumberOfLines = 2,
     .truncationAttributedString =
     [[NSAttributedString
       alloc]
      initWithString:@"\u2026"]
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   options:{ }
   size:{ }];
  CKSnapshotVerifyComponent(c, kFlexibleSize, @"");
}

- (void)testMaximumNumberOfLinesWithTruncationStringRTL
{
  CKTextComponent *c =
  [CKTextComponent
   newWithTextAttributes:{
     .attributedString =
     [[NSAttributedString
       alloc]
      initWithString:@"\u05EA\u05D9\u05E7 \u05EA\u05D0 \u05E6\u05D9\u05DC\u05D5\u05DD \u05D4\u05E2\u05D9\u05D3 \u05E7\u05E8\u05DC\u05E1 \u05D7\u05D5\u05EA\u05DC\u05D5\u05EA \u05DC\u05D8\u05D4\u05E8 \u05D0\u05D3\u05D5\u05DF \u05E2\u05D5\u05D1\u05E8\u05D9 \u05D0\u05D5\u05E8\u05D7 \u05DE\u05E9\u05D5\u05D1\u05E5 \u05DE\u05E7\u05D5\u05E2\u05E7\u05E2 \u05D8\u05D5\u05E1\u05D8 \u05D0\u05E8\u05D1\u05E2\u05D4 \u05D3\u05D5\u05DC\u05E8 \u05DB\u05E8\u05D5\u05D1 \u05D0\u05E6\u05D5\u05D5\u05D4 \u05E7\u05D8\u05DF \u05E9\u05D1\u05D1\u05D9 \u05EA\u05D0 \u05E6\u05D9\u05DC\u05D5\u05DD \u05DC\u05DB\u05D1\u05D5\u05E9 \u05EA\u05D9\u05E7 \u05EA\u05D0 \u05E6\u05D9\u05DC\u05D5\u05DD \u05D4\u05E2\u05D9\u05D3 \u05E7\u05E8\u05DC\u05E1 \u05D7\u05D5\u05EA\u05DC\u05D5\u05EA \u05DC\u05D8\u05D4\u05E8 \u05D0\u05D3\u05D5\u05DF \u05E2\u05D5\u05D1\u05E8\u05D9 \u05D0\u05D5\u05E8\u05D7 \u05DE\u05E9\u05D5\u05D1\u05E5 \u05DE\u05E7\u05D5\u05E2\u05E7\u05E2 \u05D8\u05D5\u05E1\u05D8 \u05D0\u05E8\u05D1\u05E2\u05D4 \u05D3\u05D5\u05DC\u05E8 \u05DB\u05E8\u05D5\u05D1 \u05D0\u05E6\u05D5\u05D5\u05D4 \u05E7\u05D8\u05DF \u05E9\u05D1\u05D1\u05D9 \u05EA\u05D0 \u05E6\u05D9\u05DC\u05D5\u05DD \u05DC\u05DB\u05D1\u05D5\u05E9"
      attributes:@{NSParagraphStyleAttributeName : rtlWritingDirectionParagraphStyle()}],
     .maximumNumberOfLines = 2,
     .truncationAttributedString =
     [[NSAttributedString
       alloc]
      initWithString:@"\u2026"]
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   options:{ }
   size:{ }];
  CKSnapshotVerifyComponent(c, kFlexibleSize, @"");
}

- (void)testNaturalTruncation
{
  // This is using the default truncation avoidance character set so it should truncate along word boundaries, avoiding
  // hanging punctuation.
  CKTextComponent *c =
  [CKTextComponent
   newWithTextAttributes:{
     .attributedString =
     [[NSAttributedString
       alloc]
      initWithString:@"90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony.  90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony.  90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony."],
     .truncationAttributedString =
     [[NSAttributedString
       alloc]
      initWithString:@"\u2026"]
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   options:{ }
   size:{ }];
  CKSnapshotVerifyComponent(c, kFlexibleSize, @"");
}

- (void)testEmptyTruncationCharacterSet
{
  // The default tail truncation avoidance set means that the truncater should truncate along word boundaries, excluding
  // hanging punctuation like "Hello, my name is Oliver. ...".  Instead it would truncate as "Hello, my name is
  // Oliver...".  This test uses the empty character set for the avoidance set so it should just clip at the tail,
  // ignoring word boundaries or punctuation.
  CKTextComponent *c =
  [CKTextComponent
   newWithTextAttributes:{
     .attributedString =
     [[NSAttributedString
       alloc]
      initWithString:@"90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony.  90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony.  90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony."],
     .truncationAttributedString =
     [[NSAttributedString
       alloc]
      initWithString:@"\u2026"],
     .avoidTailTruncationSet =
     [NSCharacterSet
      characterSetWithCharactersInString:@""]
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   options:{ }
   size:{ }];
  CKSnapshotVerifyComponent(c, kFlexibleSize, @"");
}

- (void)testDoesNotClipDescenders
{
  // CoreText clips the bottom of the descender in the "g" in this string at this specific size.
  CKTextComponent *c =
  [CKTextComponent
   newWithTextAttributes:{
     .attributedString =
     [[NSAttributedString
       alloc]
      initWithString:@"Nighttime\nNightingale"
      attributes:
      @{NSFontAttributeName : [UIFont fontWithName:@"Helvetica Neue" size:11.0]}]
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   options:{ }
   size:{ }];
  CKSnapshotVerifyComponent(c, kFlexibleSize, @"");
}

- (void)testDoesNotCrashWithArabicUnicodeSequenceThatUsedToCrashCoreText
{
  CKTextComponent *c =
  [CKTextComponent
   newWithTextAttributes:{
     .attributedString =
     [[NSAttributedString
       alloc]
      initWithString:@"\u062E \u0337\u0334\u0310\u062E"
      attributes:@{NSParagraphStyleAttributeName : rtlWritingDirectionParagraphStyle()}]
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   options:{ }
   size:{ }];
  CKSnapshotVerifyComponent(c, kFlexibleSize, @"");
}

- (void)testCenterAlignmentFlexibleBounds
{
  NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
  ps.alignment = NSTextAlignmentCenter;
  CKTextComponent *c =
  [CKTextComponent
   newWithTextAttributes:{
     .attributedString =
     [[NSAttributedString
       alloc]
      initWithString:@"90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony.  "
      attributes:@{NSParagraphStyleAttributeName : ps}]
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   options:{ }
   size:{ }];
  CKSnapshotVerifyComponent(c, kFlexibleSize, @"");
}

- (void)testCenterAlignmentStrictBounds
{
  NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
  ps.alignment = NSTextAlignmentCenter;
  CKTextComponent *c =
  [CKTextComponent
   newWithTextAttributes:{
     .attributedString =
     [[NSAttributedString
       alloc]
      initWithString:@"90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony.  "
      attributes:@{NSParagraphStyleAttributeName : ps}]
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   options:{ }
   size:{ }];
  CKSnapshotVerifyComponent(c, kStrictSize, @"");
}

- (void)testVerticallyLaidOutText
{
  // This is officially "undefined" on iOS, but thought I'd throw in a snapshot test here so we know when the API
  // becomes supported.
  CKTextComponent *c =
  [CKTextComponent
   newWithTextAttributes:{
     .attributedString = [[NSAttributedString
                           alloc]
                          initWithString:@"\u7E26\u66F8\u304D"
                          attributes:@{NSVerticalGlyphFormAttributeName : @1}]
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   options:{ }
   size:{ }];
  CKSnapshotVerifyComponent(c, kFlexibleSize, @"");
}

- (void)testDrawsUnderlinesAndStrikethroughs
{
  NSMutableAttributedString *attrStr =
  [[NSMutableAttributedString
    alloc]
   initWithString:@"90's cray photo booth tote bag bespoke Carles."
   attributes:@{NSUnderlineColorAttributeName : [UIColor redColor],
                NSUnderlineStyleAttributeName : @1}];
  [attrStr appendAttributedString:
   [[NSAttributedString alloc]
    initWithString:@" And here is a string with strikethrough applied."
    attributes:@{NSStrikethroughStyleAttributeName : @1,
                 NSStrikethroughColorAttributeName : [UIColor blueColor]}]];
  CKTextComponent *c =
  [CKTextComponent
   newWithTextAttributes:{
     .attributedString = attrStr
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   options:{ }
   size:{ }];
  CKSnapshotVerifyComponent(c, kFlexibleSize, @"");
}

- (void)testComplexLigatures
{
  // Make sure nothing is conflicting with our ligature attributes.
  CKTextComponent *c =
  [CKTextComponent
   newWithTextAttributes:{
     .attributedString =
     [[NSAttributedString
       alloc]
      initWithString:@"Zapfino is the best"
      attributes:@{NSFontAttributeName : [UIFont fontWithName:@"Zapfino" size:28],
                   NSLigatureAttributeName : @2}]
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   options:{ }
   size:{ }];
  CKSnapshotVerifyComponent(c, kUnrestrictedSize, @"");
}

- (void)testTruncationStringLargerThanLastLine
{
  CKTextComponent *c =
  [CKTextComponent
   newWithTextAttributes:{
     .attributedString =
     [[NSAttributedString
       alloc]
      initWithString:@"asdf\nasdf\nasdf\nasdf\nasdf\nasdf\nasdf\nasdf\nasdf\nasdf\nasdf\nasdf\nasdf"
      attributes:@{NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue" size:12.5]}],
     .maximumNumberOfLines = 3,
     .truncationAttributedString = [[NSAttributedString
                                     alloc]
                                    initWithString:@"... Read More"
                                    attributes:@{NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue" size:12.5]}],
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   options:{ }
   size:{ }];
  CKSnapshotVerifyComponent(c, kUnrestrictedSize, @"");
}

- (void)testShouldUseCustomLayoutManagerClass
{
	NSString *contentString = @"This is a string with a border behind every other word";
  NSMutableAttributedString *attributed = [[NSMutableAttributedString alloc] initWithString:contentString attributes:@{NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue" size:12.5]}];
  __block NSUInteger index = 0;
  [contentString enumerateSubstringsInRange:[contentString rangeOfString:contentString]
                                    options:NSStringEnumerationByWords
                                 usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                   if (index++ % 2) {
                                     [attributed addAttribute:NSBackgroundColorAttributeName value:[UIColor greenColor] range:substringRange];
                                   }
                                 }];

  CKTextComponent *c =
  [CKTextComponent
   newWithTextAttributes:{
     .attributedString = attributed,
     .layoutManagerFactory = testLayoutManagerFactory
   }
   viewAttributes:{
     {{@selector(setBackgroundColor:), [UIColor clearColor]}}
   }
   options:{ }
   size:{ }];
  CKSnapshotVerifyComponent(c, kUnrestrictedSize, @"");
}

@end
