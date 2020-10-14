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

#import <ComponentKit/CKBackgroundLayoutComponent.h>
#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentLayout.h>

#import <ComponentKit/CKTreeVerificationHelpers.h>

#import "CKComponentTestCase.h"

#pragma mark - Tests

@interface CKDetectDuplicateComponentTests : CKComponentTestCase

@end

@implementation CKDetectDuplicateComponentTests

- (void)testFindDuplicateComponentWithDuplicateComponent
{
  auto const c = [CKComponent new];
  auto const b = CK::BackgroundLayoutComponentBuilder()
                     .component(c)
                     .background(c)
                     .build();

  auto const layout = CKComputeComponentLayout(b, {}, {});
  auto const info = CKFindDuplicateComponent(layout);
  XCTAssertEqual(c, info.component);
}

- (void)testFindDuplicateComponentWithNoDuplicateComponent
{
  auto const b = CK::BackgroundLayoutComponentBuilder()
                     .component([CKComponent new])
                     .background([CKComponent new])
                     .build();

  auto const layout = CKComputeComponentLayout(b, {}, {});
  auto const info = CKFindDuplicateComponent(layout);
  XCTAssertNil(info.component);
}

@end
