// Copyright 2004-present Facebook. All Rights Reserved.

#import <XCTest/XCTest.h>

#import <ComponentKit/CKIndexSetDescription.h>
#import <ComponentKitTestHelpers/NSIndexSetExtensions.h>

@interface CKIndexSetDescriptionTests : XCTestCase
@end

@implementation CKIndexSetDescriptionTests

- (void)test_WhenIndexSetIsEmpty_ReturnsEmptyString
{
  XCTAssertEqualObjects(CK::indexSetDescription([NSIndexSet new]), @"");
}

- (void)test_WhenIndexSetHasOneIndex_ReturnsTheIndexAsString
{
  XCTAssertEqualObjects(CK::indexSetDescription(CK::makeIndexSet({1})), @"1");
}

- (void)test_WhenIndexSetHasDisjointIndexes_ReturnsIndexesSeparatedByComma
{
  XCTAssertEqualObjects(CK::indexSetDescription(CK::makeIndexSet({1, 3})), @"1, 3");
}

- (void)test_WhenIndexSetHasAdjacentIndexes_CombinesThemIntoOneRange
{
  XCTAssertEqualObjects(CK::indexSetDescription(CK::makeIndexSet({1, 2, 3})), @"1–3");
}

@end

@interface CKIndexSetDescriptionTests_WithTitleAndIndent : XCTestCase
@end

@implementation CKIndexSetDescriptionTests_WithTitleAndIndent

- (void)test_WhenIndexSetIsEmptyButHasTitle_ReturnsEmptyString
{
  XCTAssertEqualObjects(CK::indexSetDescription([NSIndexSet new], @"Removed Sections", 2), @"");
}

- (void)test_WhenIndentIsNonZero_AddsIndentBeforeTitle
{
  const auto is = CK::makeIndexSet({1, 2, 4});
  const auto expectedDescription = @"  Removed Sections: 1–2, 4";

  XCTAssertEqualObjects(CK::indexSetDescription(is, @"Removed Sections", 2), expectedDescription);
}

- (void)test_WhenIndentIsZero_AddsOnlyTitle
{
  const auto is = CK::makeIndexSet({1, 2, 4});
  const auto expectedDescription = @"Removed Sections: 1–2, 4";

  XCTAssertEqualObjects(CK::indexSetDescription(is, @"Removed Sections"), expectedDescription);
}

@end
