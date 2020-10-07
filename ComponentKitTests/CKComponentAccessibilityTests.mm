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

#import "CKComponentTestCase.h"

using namespace CK::Component::Accessibility;

@interface CKComponentAccessibilityTests : CKComponentTestCase
@end

@interface UIView (CKComponentAccessibilityTests)
- (void)setBlah:(NSString *)blah;
@end

@implementation CKComponentAccessibilityTests

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
  NSSet *mountedComponents = CKMountComponentLayout([testComponent layoutThatFits:{} parentSize:{}], container, nil, nil);

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
  NSSet *mountedComponents = CKMountComponentLayout([testComponent layoutThatFits:{} parentSize:{}], container, nil, nil);

  XCTAssertEqual(testComponent.viewContext.view.isAccessibilityElement, NO);
  XCTAssertNil(testComponent.viewContext.view.accessibilityLabel);
  XCTAssertNil(testComponent.viewContext.view.accessibilityHint);
  XCTAssertNil(testComponent.viewContext.view.accessibilityValue);
  XCTAssertEqual(testComponent.viewContext.view.accessibilityTraits, UIAccessibilityTraitNone);

  CKUnmountComponents(mountedComponents);
}

@end
