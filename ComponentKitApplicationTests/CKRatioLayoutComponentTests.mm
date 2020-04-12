/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */


#import <ComponentKit/CKBackgroundLayoutComponent.h>
#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKRatioLayoutComponent.h>

#import <ComponentSnapshotTestCase/CKComponentSnapshotTestCase.h>

@interface CKRatioLayoutComponentTests : CKComponentSnapshotTestCase

@end

@implementation CKRatioLayoutComponentTests

- (void)setUp
{
  [super setUp];
  self.recordMode = NO;
}

static CKComponent *ratioLayoutComponent(CGFloat ratio, const CKComponentSize &size)
{
  return
  CK::RatioLayoutComponentBuilder()
  .ratio(ratio)
  .component(
    CK::ComponentBuilder()
    .viewClass([UIView class])
    .backgroundColor([UIColor greenColor])
    .size(size)
    .build()
  )
  .build();
}

- (void)testRatioLayout
{
  CKSizeRange kFixedSize = {{0, 0}, {100, 100}};
  CKSnapshotVerifyComponent(ratioLayoutComponent(0.5, {100, 100}), kFixedSize, @"HalfRatio");
  CKSnapshotVerifyComponent(ratioLayoutComponent(2.0, {100, 100}), kFixedSize, @"DoubleRatio");
  CKSnapshotVerifyComponent(ratioLayoutComponent(7.0, {100, 100}), kFixedSize, @"SevenTimesRatio");

  CKComponentSize tallSize = {20, 200};
  CKSnapshotVerifyComponent(ratioLayoutComponent(10.0, tallSize), kFixedSize, @"TenTimesRatioWithItemTooBig");
}

- (void)testRatioLayoutRendersToNilForNilInput
{
  const auto c =
  CK::RatioLayoutComponentBuilder()
  .ratio(0.5)
  .component(nil)
  .build();
  XCTAssertNil(c);
}

@end
