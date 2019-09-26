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
#import <ComponentKit/CKComponentSubclass.h>

#import <ComponentKit/CKComponentAccessibility.h>

using namespace CK::Component::Accessibility;

@interface CKComponentAccessibilityTests : XCTestCase
@end

@interface UIView (CKComponentAccessibilityTests)
- (void)setBlah:(NSString *)blah;
@end

@implementation CKComponentAccessibilityTests

- (void)testAccessibilityContextItemsAreProperlyTransformedToViewAttributes
{
  CKComponentViewConfiguration viewConfiguration = {
    [UIView class],
    {
      {@selector(setBlah:), @"Blah"},
      {@selector(setAccessibilityIdentifier:), @"batman"},
    },
    {
      .isAccessibilityElement = @NO,
      .accessibilityLabel = ^{ return @"accessibleBatman";},
      .accessibilityHint = ^{ return @"accessibleBruce";},
      .accessibilityValue = ^{ return @"accessibleWayne";},
      .accessibilityTraits = @(UIAccessibilityTraitButton | UIAccessibilityTraitImage),
    }};

  CKComponentViewConfiguration expectedViewConfiguration = {
    [UIView class],
    {
      {@selector(setBlah:), @"Blah"},
      {@selector(setAccessibilityIdentifier:), @"batman"},
      {@selector(setIsAccessibilityElement:), @NO},
      {@selector(setAccessibilityLabel:), @"accessibleBatman"},
      {@selector(setAccessibilityHint:), @"accessibleBruce"},
      {@selector(setAccessibilityValue:), @"accessibleWayne"},
      {@selector(setAccessibilityTraits:), @(UIAccessibilityTraitButton | UIAccessibilityTraitImage)}
    },
    {
      .isAccessibilityElement = @NO,
      .accessibilityLabel = ^{ return @"accessibleBatman";},
      .accessibilityHint = ^{ return @"accessibleBruce";},
      .accessibilityValue = ^{ return @"accessibleWayne";},
      .accessibilityTraits = @(UIAccessibilityTraitButton | UIAccessibilityTraitImage),
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

- (void)testAccessibilityContextItemsAreTransformedToViewPropertiesWhenEnabled
{
  SetForceAccessibilityEnabled(YES);
  CKComponent *testComponent = CK::ComponentBuilder()
                                   .viewClass([UIView class])
                                   .accessibilityContext({
    .isAccessibilityElement = @YES,
    .accessibilityLabel = ^{ return @"accessibleSuperman";},
    .accessibilityHint = ^{ return @"accessibleClark";},
    .accessibilityValue = ^{ return @"accessibleKent";},
    .accessibilityTraits = @(UIAccessibilityTraitButton | UIAccessibilityTraitImage),
  })
                                   .build();

  UIView *container = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([testComponent layoutThatFits:{} parentSize:{}], container, nil, nil).mountedComponents;

  XCTAssertEqual(testComponent.viewContext.view.isAccessibilityElement, YES);
  XCTAssertEqual(testComponent.viewContext.view.accessibilityLabel, @"accessibleSuperman",);
  XCTAssertEqual(testComponent.viewContext.view.accessibilityHint, @"accessibleClark");
  XCTAssertEqual(testComponent.viewContext.view.accessibilityValue, @"accessibleKent");
  XCTAssertEqual(testComponent.viewContext.view.accessibilityTraits, UIAccessibilityTraitButton | UIAccessibilityTraitImage);

  CKUnmountComponents(mountedComponents);
}

- (void)testAccessibilityContextItemsAreNotTransformedToViewPropertiesWhenDisabled
{
  SetForceAccessibilityEnabled(NO);
  CKComponent *testComponent = CK::ComponentBuilder()
                                   .viewClass([UIView class])
                                   .accessibilityContext({
    .isAccessibilityElement = @YES,
    .accessibilityLabel = ^{ return @"accessibleSuperman";},
    .accessibilityHint = ^{ return @"accessibleClark";},
    .accessibilityValue = ^{ return @"accessibleKent";},
    .accessibilityTraits = @(UIAccessibilityTraitButton | UIAccessibilityTraitImage),
  })
                                   .build();

  UIView *container = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([testComponent layoutThatFits:{} parentSize:{}], container, nil, nil).mountedComponents;

  XCTAssertEqual(testComponent.viewContext.view.isAccessibilityElement, NO);
  XCTAssertNil(testComponent.viewContext.view.accessibilityLabel);
  XCTAssertNil(testComponent.viewContext.view.accessibilityHint);
  XCTAssertNil(testComponent.viewContext.view.accessibilityValue);
  XCTAssertEqual(testComponent.viewContext.view.accessibilityTraits, UIAccessibilityTraitNone);

  CKUnmountComponents(mountedComponents);
}

@end
