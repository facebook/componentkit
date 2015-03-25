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

#import "CKTextKitAttributes.h"
#import "CKTextKitRenderer.h"

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
  return [controller compareReferenceImage:labelImage toImage:textKitImage error:nil];
}

@implementation CKTextKitTests

- (void)testSimpleStrings
{
  CKTextKitAttributes attributes {
    .attributedString = [[NSAttributedString alloc] initWithString:@"hello" attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:12]}]
  };
  XCTAssert(checkAttributes(attributes, { 100, 100 }));
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

@end
