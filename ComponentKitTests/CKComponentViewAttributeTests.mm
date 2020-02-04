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
#import <XCTest/XCTest.h>

#import <ComponentKitTestHelpers/CKComponentLifecycleTestHelper.h>

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentSubclass.h>

@interface CKComponentViewAttributeTests : XCTestCase
@end

@interface CKSetterCounterView : UIView
@property (nonatomic, copy) NSString *title;
@property (nonatomic, readonly) NSUInteger numberOfTimesSetTitleWasCalled;
@end

@interface CKHidingCounterView : UIView
@property (nonatomic, readonly) NSUInteger numberOfTimesViewWasHidden;
@end

@interface CKNSNumberView : UIControl
@property (nonatomic) char primitiveChar;
@property (nonatomic) int primitiveInt;
@property (nonatomic) short primitiveShort;
@property (nonatomic) int32_t primitiveInt32;
@property (nonatomic) long long primitiveInt64;
@property (nonatomic) unsigned char primitiveUChar;
@property (nonatomic) unsigned int primitiveUInt;
@property (nonatomic) unsigned short primitiveUShort;
@property (nonatomic) uint32_t primitiveUInt32;
@property (nonatomic) unsigned long long primitiveUInt64;
@property (nonatomic) double primitiveDouble;
@property (nonatomic) float primitiveFloat;
@end

@implementation CKComponentViewAttributeTests

- (void)testThatMountingViewWithNSValueAttributeActuallyAppliesAttributeToView
{
  CKComponent *testComponent = CK::ComponentBuilder()
                                   .viewClass([CKNSNumberView class])
                                   .attribute(@selector(setSelected:), @YES)
                                   .attribute(CKComponentViewAttribute::LayerAttribute(@selector(setOpacity:)), @(0.5))
                                   .attribute(@selector(setTag:), @2)
                                   .attribute(@selector(setPrimitiveChar:), @'D')
                                   .attribute(@selector(setPrimitiveShort:), @(short(1)))
                                   .attribute(@selector(setPrimitiveInt:), @14)
                                   .attribute(@selector(setPrimitiveInt32:), @9L)
                                   .attribute(@selector(setPrimitiveInt64:), @5LL)
                                   .attribute(@selector(setPrimitiveUChar:), [NSNumber numberWithUnsignedChar:'L'])
                                   .attribute(@selector(setPrimitiveUShort:), [NSNumber numberWithUnsignedShort:23])
                                   .attribute(@selector(setPrimitiveUInt32:), @15UL)
                                   .attribute(@selector(setPrimitiveUInt64:), @18ULL)
                                   .attribute(@selector(setPrimitiveDouble:), @11.3)
                                   .attribute(@selector(setPrimitiveFloat:), @21.1F)
                                   .build();
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:nullptr
                                                                                                                             sizeRangeProvider:nil];
  [componentLifecycleTestController updateWithState:{
    .componentLayout = [testComponent layoutThatFits:{{0, 0}, {10, 10}} parentSize:kCKComponentParentSizeUndefined]
  }];

  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];
  CKNSNumberView *c = [[view subviews] firstObject];
  XCTAssertTrue([c isSelected], @"Expected selected to be applied to view");
  XCTAssertTrue(c.layer.opacity == 0.5, @"Expected opacity to be applied to view's layer");
}

- (void)testThatMountingViewWithPrimitiveAttributeActuallyAppliesAttributeToView
{
  CKComponent *testComponent = CK::ComponentBuilder()
                                   .viewClass([CKNSNumberView class])
                                   .attribute(@selector(setSelected:), YES)
                                   .attribute(CKComponentViewAttribute::LayerAttribute(@selector(setOpacity:)), @0.5)
                                   .attribute(@selector(setTag:), 2)
                                   .attribute(@selector(setPrimitiveChar:), 'D')
                                   .attribute(@selector(setPrimitiveShort:), short(1))
                                   .attribute(@selector(setPrimitiveInt:), 14)
                                   .attribute(@selector(setPrimitiveInt32:), 9L)
                                   .attribute(@selector(setPrimitiveInt64:), 5LL)
                                   .attribute(@selector(setPrimitiveUChar:), (unsigned char)('L'))
                                   .attribute(@selector(setPrimitiveUShort:), (ushort)(23))
                                   .attribute(@selector(setPrimitiveUInt32:), 15UL)
                                   .attribute(@selector(setPrimitiveUInt64:), 18ULL)
                                   .attribute(@selector(setPrimitiveDouble:), 11.3)
                                   .attribute(@selector(setPrimitiveFloat:), 21.1F)
                                   .build();
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:nullptr
                                                                                                                             sizeRangeProvider:nil];
  [componentLifecycleTestController updateWithState:{
    .componentLayout = [testComponent layoutThatFits:{{0, 0}, {10, 10}} parentSize:kCKComponentParentSizeUndefined]
  }];

  UIView *container = [[UIView alloc] init];
  [componentLifecycleTestController attachToView:container];
  CKNSNumberView *c = [[container subviews] firstObject];
  XCTAssertTrue([c isSelected], @"Expected selected to be applied to view");
  XCTAssertTrue(c.layer.opacity == 0.5, @"Expected opacity to be applied to view's layer");
}


- (void)testThatRecyclingViewWithSameAttributeValueDoesNotReApplyAttributeToView
{
  CKComponent *testComponent1 = CK::ComponentBuilder()
                                    .viewClass([CKSetterCounterView class])
                                    .attribute(@selector(setTitle:), @"Test")
                                    .backgroundColor([UIColor blueColor])
                                    .build();
  CKComponentLifecycleTestHelper *componentLifecycleTestController1 = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:nullptr
                                                                                                                              sizeRangeProvider:nil];
  [componentLifecycleTestController1 updateWithState:{
    .componentLayout = [testComponent1 layoutThatFits:{{0, 0}, {10, 10}} parentSize:kCKComponentParentSizeUndefined]
  }];

  UIView *view = [UIView new];
  [componentLifecycleTestController1 attachToView:view];

  CKComponent *testComponent2 = CK::ComponentBuilder()
                                    .viewClass([CKSetterCounterView class])
                                    .attribute(@selector(setTitle:), @"Test")
                                    .backgroundColor([UIColor redColor])
                                    .build();
  CKComponentLifecycleTestHelper *componentLifecycleTestController2 = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:nullptr
                                                                                                                              sizeRangeProvider:nil];
  [componentLifecycleTestController2 updateWithState:{
    .componentLayout = [testComponent2 layoutThatFits:{{0, 0}, {10, 10}} parentSize:kCKComponentParentSizeUndefined]
  }];
  [componentLifecycleTestController2 attachToView:view];

  CKSetterCounterView *c = [[view subviews] firstObject];
  XCTAssertEqual([c numberOfTimesSetTitleWasCalled], 1u, @"Expected setTitle: to called only once since it didn't change");
  XCTAssertEqualObjects([c backgroundColor], [UIColor redColor], @"Expected background color to be updated by m2");
}

- (void)testThatRecyclingViewWithDistinctAttributeValueDoesNotHideAndReShowView
{
  CKComponent *testComponent1 = CK::ComponentBuilder()
                                    .viewClass([CKHidingCounterView class])
                                    .backgroundColor([UIColor blueColor])
                                    .build();
  CKComponentLifecycleTestHelper *componentLifecycleTestController1 = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:nullptr
                                                                                                                             sizeRangeProvider:nil];
  [componentLifecycleTestController1 updateWithState:{
    .componentLayout = [testComponent1 layoutThatFits:{{0, 0}, {10, 10}} parentSize:kCKComponentParentSizeUndefined]
  }];

  UIView *view = [UIView new];
  [componentLifecycleTestController1 attachToView:view];

  CKComponent *testComponent2 = CK::ComponentBuilder()
                                    .viewClass([CKHidingCounterView class])
                                    .backgroundColor([UIColor redColor])
                                    .build();
  CKComponentLifecycleTestHelper *componentLifecycleTestController2 = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:nullptr
                                                                                                                             sizeRangeProvider:nil];
  [componentLifecycleTestController2 updateWithState:{
    .componentLayout = [testComponent2 layoutThatFits:{{0, 0}, {10, 10}} parentSize:kCKComponentParentSizeUndefined]
  }];
  [componentLifecycleTestController2 attachToView:view];

  CKHidingCounterView *c = [[view subviews] firstObject];
  XCTAssertEqual([c numberOfTimesViewWasHidden], 0u, @"Expected view never to be hidden if it didn't need to be");
}

- (void)testThatRecyclingViewWithAttributeRequiringUnapplicationCallsUnapplicator
{
  NSMutableSet *appliedValues = [NSMutableSet set];
  NSMutableSet *unappliedValues = [NSMutableSet set];
  CKComponentViewAttribute attrWithUnapplicator("test", ^(id view, id val){
    [appliedValues addObject:val];
  }, ^(id view, id val){
    [unappliedValues addObject:val];
  });

  CKComponent *testComponent1 = CK::ComponentBuilder()
                                    .viewClass([UIView class])
                                    .attribute(attrWithUnapplicator, @1)
                                    .build();

  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:nullptr
                                                                                                                             sizeRangeProvider:nil];
  [componentLifecycleTestController updateWithState:{
    .componentLayout = [testComponent1 layoutThatFits:{{0, 0}, {10, 10}} parentSize:kCKComponentParentSizeUndefined]
  }];

  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];

  XCTAssertEqualObjects(appliedValues, [NSSet setWithObject:@1], @"Expected @1 to be applied");
  XCTAssertEqualObjects(unappliedValues, [NSSet set], @"Expected nothing to be unapplied");

  CKComponent *testComponent2 = CK::ComponentBuilder()
                                    .viewClass([UIView class])
                                    .attribute(attrWithUnapplicator, @2)
                                    .build();
  [componentLifecycleTestController updateWithState:{
    .componentLayout = [testComponent2 layoutThatFits:{{0, 0}, {10, 10}} parentSize:kCKComponentParentSizeUndefined]
  }];

  NSSet *expectedApplied = [NSSet setWithObjects:@1, @2, nil]; // stupid STAssert macros
  XCTAssertEqualObjects(appliedValues, expectedApplied, @"Expected @1, @2 to be applied");
  XCTAssertEqualObjects(unappliedValues, [NSSet setWithObject:@1], @"Expected @1 to be unapplied");
}

- (void)testThatRecyclingViewWithAttributeOfferingUpdaterInvokesUpdaterInsteadOfApplicator
{
  __block std::vector<id> appliedValues;
  __block std::vector<std::pair<id, id>> updatedValues;
  CKComponentViewAttribute attrWithUpdater =
  {
    "test",
    ^(id view, id val){
      appliedValues.push_back(val);
    },
    nil,
    ^(id view, id oldVal, id newVal){
      updatedValues.push_back({oldVal, newVal});
    }
  };

  CKComponent *testComponent1 = CK::ComponentBuilder()
                                    .viewClass([UIView class])
                                    .attribute(attrWithUpdater, @1)
                                    .build();

  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:nullptr
                                                                                                                             sizeRangeProvider:nil];
  [componentLifecycleTestController updateWithState:{
    .componentLayout = [testComponent1 layoutThatFits:{{0, 0}, {10, 10}} parentSize:kCKComponentParentSizeUndefined]
  }];

  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];

  XCTAssertTrue(appliedValues.size() == 1 && [appliedValues[0] isEqual:@1], @"Expected @1 to be applied");
  XCTAssertEqual(updatedValues.size(), (size_t)0, @"Expected no updates yet");

  CKComponent *testComponent2 = CK::ComponentBuilder()
                                    .viewClass([UIView class])
                                    .attribute(attrWithUpdater, @2)
                                    .build();
  [componentLifecycleTestController updateWithState:{
    .componentLayout = [testComponent2 layoutThatFits:{{0, 0}, {10, 10}} parentSize:kCKComponentParentSizeUndefined]
  }];

  XCTAssertTrue(appliedValues.size() == 1, @"applicator should not have been called again");
  XCTAssertTrue(updatedValues.size() == 1, @"updater should have been called");
  std::pair<id, id> updateValue = updatedValues[0];
  XCTAssertTrue([updateValue.first isEqual:@1] && [updateValue.second isEqual:@2],
               @"updater should have been called with old and new values");
}

/**
 Tests that if:
 - If your attribute has BOTH an updater AND an unapplicator;
 - The view is initially configured to show a component WITH the attribute;
 - And the view is recycled to show a component WITHOUT the attribute;
 - And then the view is recycled to show a component WITH the attribute again;
 Then we should call the unapplicator followed by the applicator, not the updater.
 */
- (void)testThatRecyclingViewWithAttributeWithBothUpdaterAndUnapplicatorCallsUnapplicatorToRemoveThenApplicatorToReapply
{
  NSMutableSet *appliedValues = [NSMutableSet set];
  NSMutableSet *unappliedValues = [NSMutableSet set];
  __block NSUInteger updateCount = 0;
  CKComponentViewAttribute attr =
  {
    "test",
    ^(id view, id val){
      [appliedValues addObject:val];
    },
    ^(id view, id val) {
      [unappliedValues addObject:val];
    },
    ^(id view, id oldVal, id newVal){
      updateCount++;
    }
  };

  CKComponent *testComponent1 = CK::ComponentBuilder()
                                    .viewClass([UIView class])
                                    .attribute(attr, @1)
                                    .build();

  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:nullptr
                                                                                                                             sizeRangeProvider:nil];
  [componentLifecycleTestController updateWithState:{
    .componentLayout = [testComponent1 layoutThatFits:{{0, 0}, {10, 10}} parentSize:kCKComponentParentSizeUndefined]
  }];

  UIView *container = [[UIView alloc] init];
  [componentLifecycleTestController attachToView:container];

  NSSet *expectedAppliedValues = [NSSet setWithObject:@1];
  XCTAssertEqualObjects(appliedValues, expectedAppliedValues, @"Expected @1 to be applied");
  XCTAssertEqualObjects(unappliedValues, [NSSet set], @"Nothing should be unapplied yet");
  XCTAssertEqual(updateCount, 0u, @"Nothing should be updated");

  CKComponent *testComponent2 = CK::ComponentBuilder()
                                    .viewClass([UIView class])
                                    .build();
  [componentLifecycleTestController updateWithState:{
    .componentLayout = [testComponent2 layoutThatFits:{{0, 0}, {10, 10}} parentSize:kCKComponentParentSizeUndefined]
  }];

  NSSet *expectedUnappliedValues = [NSSet setWithObject:@1];
  XCTAssertEqualObjects(unappliedValues, expectedUnappliedValues, @"@1 should be unapplied");
  XCTAssertEqual(updateCount, 0u, @"Nothing should be updated");
}

@end

@implementation CKSetterCounterView

- (void)setTitle:(NSString *)title
{
  _numberOfTimesSetTitleWasCalled++;
  _title = [title copy];
}

@end

@implementation CKHidingCounterView

- (void)setHidden:(BOOL)hidden
{
  if (hidden) {
    _numberOfTimesViewWasHidden++;
  }
  [super setHidden:hidden];
}

@end

@implementation CKNSNumberView
@end
