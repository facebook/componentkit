/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */


#import <XCTest/XCTest.h>

#import <FBSnapshotTestCase/FBSnapshotTestController.h>

#import <ComponentKit/CKTextKitEntityAttribute.h>
#import <ComponentKit/CKTextKitAttributes.h>
#import <ComponentKit/CKTextKitRenderer.h>
#import <ComponentKit/CKTextKitRenderer+Positioning.h>

@interface CKTextKitTests : XCTestCase

@end

static UITextView *UITextViewWithAttributes(const CKTextKitAttributes &attributes, const CGSize constrainedSize)
{
  UITextView *textView = [[UITextView alloc] initWithFrame:{ .size = constrainedSize }];
  textView.backgroundColor = [UIColor clearColor];
  textView.textContainer.lineBreakMode = attributes.lineBreakMode;
  textView.textContainer.lineFragmentPadding = 0.f;
  textView.textContainer.maximumNumberOfLines = attributes.maximumNumberOfLines;
  textView.textContainerInset = UIEdgeInsetsZero;
  textView.layoutManager.usesFontLeading = NO;
  textView.attributedText = attributes.attributedString;
  return textView;
}

static UIImage *UITextViewImageWithAttributes(const CKTextKitAttributes &attributes, const CGSize constrainedSize)
{
  UITextView *textView = UITextViewWithAttributes(attributes, constrainedSize);
  UIGraphicsBeginImageContextWithOptions(constrainedSize, NO, 0);
  CGContextRef context = UIGraphicsGetCurrentContext();

  CGContextSaveGState(context);
  {
    [textView.layer renderInContext:context];
  }
  CGContextRestoreGState(context);

  UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return snapshot;
}

static UIImage *CKTextKitImageWithAttributes(const CKTextKitAttributes &attributes, const CGSize constrainedSize)
{
  CKTextKitRenderer *renderer = [[CKTextKitRenderer alloc] initWithTextKitAttributes:attributes
                                                                     constrainedSize:constrainedSize];
  UIGraphicsBeginImageContextWithOptions(constrainedSize, NO, 0);
  CGContextRef context = UIGraphicsGetCurrentContext();

  CGContextSaveGState(context);
  {
    [renderer drawInContext:context bounds:{.size = constrainedSize}];
  }
  CGContextRestoreGState(context);

  UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return snapshot;
}

static BOOL checkAttributes(const CKTextKitAttributes &attributes, const CGSize constrainedSize)
{
  FBSnapshotTestController *controller = [[FBSnapshotTestController alloc] init];
  UIImage *labelImage = UITextViewImageWithAttributes(attributes, constrainedSize);
  UIImage *textKitImage = CKTextKitImageWithAttributes(attributes, constrainedSize);
  return [controller compareReferenceImage:labelImage toImage:textKitImage tolerance:0 error:nil];
}

@implementation CKTextKitTests

- (void)testSimpleStrings
{
  CKTextKitAttributes attributes {
    .attributedString = [[NSAttributedString alloc] initWithString:@"hello" attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:12]}]
  };
  XCTAssert(checkAttributes(attributes, { 100, 100 }));
}

- (void)testChangingAPropertyChangesHash
{
  NSAttributedString *as = [[NSAttributedString alloc] initWithString:@"hello" attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:12]}];

  CKTextKitAttributes attrib1 {
    .attributedString = as,
    .lineBreakMode =  NSLineBreakByClipping,
  };
  CKTextKitAttributes attrib2 {
    .attributedString = as,
  };

  XCTAssertNotEqual(attrib1.hash(), attrib2.hash(), @"Hashes should differ when NSLineBreakByClipping changes.");
}

- (void)testSameStringHashesSame
{
  CKTextKitAttributes attrib1 {
    .attributedString = [[NSAttributedString alloc] initWithString:@"hello" attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:12]}],
  };
  CKTextKitAttributes attrib2 {
    .attributedString = [[NSAttributedString alloc] initWithString:@"hello" attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:12]}],
  };

  XCTAssertEqual(attrib1.hash(), attrib2.hash(), @"Hashes should be the same!");
}


- (void)testStringsWithVariableAttributes
{
  NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:@"hello" attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:12]}];
  for (int i = 0; i < attrStr.length; i++) {
    // Color each character something different
    CGFloat factor = ((CGFloat)i) / ((CGFloat)attrStr.length);
    [attrStr addAttribute:NSForegroundColorAttributeName
                    value:[UIColor colorWithRed:factor
                                          green:1.0 - factor
                                           blue:0.0
                                          alpha:1.0]
                    range:NSMakeRange(i, 1)];
  }
  CKTextKitAttributes attributes {
    .attributedString = attrStr
  };
  XCTAssert(checkAttributes(attributes, { 100, 100 }));
}

- (void)testRectsForRangeBeyondTruncationSizeReturnsNonZeroNumberOfRects
{
  NSAttributedString *attributedString =
  [[NSAttributedString alloc]
   initWithString:@"90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony.  " attributes:@{CKTextKitEntityAttributeName : [[CKTextKitEntityAttribute alloc] initWithEntity:@"entity"]}];

  CKTextKitRenderer *renderer =
  [[CKTextKitRenderer alloc]
   initWithTextKitAttributes:{
     .attributedString = attributedString,
     .maximumNumberOfLines = 1,
     .truncationAttributedString = [[NSAttributedString alloc] initWithString:@"... Continue Reading"]
   }
   constrainedSize:{ 100, 100 }];

  XCTAssert([renderer rectsForTextRange:NSMakeRange(0, attributedString.length) measureOption:CKTextKitRendererMeasureOptionBlock].count > 0);
}

@end
