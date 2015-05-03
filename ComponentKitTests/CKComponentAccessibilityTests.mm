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

#import <ComponentKit/CKComponent.h>

#import "CKComponentAccessibility.h"
#import "CKComponentAccessibility_Private.h"

using namespace CK::Component::Accessibility;

@interface CKComponentAccessibilityTests : XCTestCase
@end

@interface UIAccessibleView : UIView
@end

@interface UIView (CKComponentAccessibilityTests)
- (void)setBlah:(NSString *)blah;
@end

@implementation CKComponentAccessibilityTests

- (void)testAccessibilityContextItemsAreProperlyTransformedToViewAttributes
{
  CKComponentViewConfiguration viewConfiguration = {
    [UIView class],
    {{@selector(setBlah:), @"Blah"}},
    {
      .accessibilityIdentifier = @"batman", .isAccessibilityElement = @NO, .accessibilityLabel = ^{ return @"accessibleBatman"; }
    }};
  CKComponentViewConfiguration expectedViewConfiguration = {
    [UIView class],
    {{@selector(setBlah:), @"Blah"}, {@selector(setAccessibilityIdentifier:), @"batman"}, {@selector(setAccessibilityLabel:), @"accessibleBatman"}, {@selector(setIsAccessibilityElement:), @NO}},
    {
      .accessibilityIdentifier = @"batman", .isAccessibilityElement = @NO, .accessibilityLabel = @"accessibleBatman"
    }};
  XCTAssertTrue(AccessibleViewConfiguration(viewConfiguration) == expectedViewConfiguration, @"Accessibility attributes were applied incorrectly");
}

- (void)testEmptyAccessibilityContextLeavesTheViewConfigurationUnchanged
{
  CKComponentViewConfiguration viewConfiguration = {[UIView class], {{@selector(setBlah:), @"Blah"}}};
  XCTAssertTrue(AccessibleViewConfiguration(viewConfiguration) == viewConfiguration, @"Accessibility attributes were applied incorrectly");
}

- (void)testSetForceAccessibilityEnabledEnablesAccessibility
{
  SetForceAccessibilityEnabled(YES);
  XCTAssertTrue(IsAccessibilityEnabled());
}

- (void)testSetForceAccessibilityEnabledDisablesAccessibility
{
  SetForceAccessibilityEnabled(NO);
  XCTAssertFalse(IsAccessibilityEnabled());
}

@end

@implementation UIAccessibleView
@end
