/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentSnapshotTestCase/CKComponentSnapshotTestCase.h>

#import <ComponentKit/CKBackgroundLayoutComponent.h>
#import <ComponentKit/CKCompositeComponent.h>
#import <ComponentKit/CKInsetComponent.h>
#import <ComponentKit/CKStaticLayoutComponent.h>


typedef NS_OPTIONS(NSUInteger, CKInsetComponentTestEdge) {
  CKInsetComponentTestEdgeTop    = 1 << 0,
  CKInsetComponentTestEdgeLeft   = 1 << 1,
  CKInsetComponentTestEdgeBottom = 1 << 2,
  CKInsetComponentTestEdgeRight  = 1 << 3,
};

static CGFloat insetForEdge(NSUInteger combination, CKInsetComponentTestEdge edge, CGFloat insetValue)
{
  return combination & edge ? INFINITY : insetValue;
}

static UIEdgeInsets insetsForCombination(NSUInteger combination, CGFloat insetValue)
{
  return {
    .top = insetForEdge(combination, CKInsetComponentTestEdgeTop, insetValue),
    .left = insetForEdge(combination, CKInsetComponentTestEdgeLeft, insetValue),
    .bottom = insetForEdge(combination, CKInsetComponentTestEdgeBottom, insetValue),
    .right = insetForEdge(combination, CKInsetComponentTestEdgeRight, insetValue),
  };
}

static NSString *nameForInsets(UIEdgeInsets insets)
{
  return [NSString stringWithFormat:@"%.f-%.f-%.f-%.f", insets.top, insets.left, insets.bottom, insets.right];
}

@interface CKInsetTestBlockComponent : CKCompositeComponent
+ (instancetype)newWithColor:(UIColor *)color size:(const CKComponentSize &)size;
@end

@interface CKInsetTestBackgroundComponent : CKCompositeComponent
@end

@interface CKInsetComponentTests : CKComponentSnapshotTestCase
@end

@implementation CKInsetComponentTests

- (void)setUp
{
  [super setUp];
  self.recordMode = NO;
}

- (void)testInsetsWithVariableSize
{
  for (NSUInteger combination = 0; combination < 16; combination++) {
    UIEdgeInsets insets = insetsForCombination(combination, 10);
    CKComponent *component = [CKInsetTestBackgroundComponent
                              newWithComponent:
                              [CKInsetComponent
                               newWithInsets:insets
                               component:[CKInsetTestBlockComponent newWithColor:[UIColor greenColor] size:{10,10}]]];
    static CKSizeRange kVariableSize = {{0, 0}, {300, 300}};
    CKSnapshotVerifyComponent(component, kVariableSize, nameForInsets(insets));
  }
}

- (void)testInsetsWithFixedSize
{
  for (NSUInteger combination = 0; combination < 16; combination++) {
    UIEdgeInsets insets = insetsForCombination(combination, 10);
    CKComponent *component = [CKInsetTestBackgroundComponent
                              newWithComponent:
                              [CKInsetComponent
                               newWithInsets:insets
                               component:[CKInsetTestBlockComponent newWithColor:[UIColor greenColor] size:{10,10}]]];
    static CKSizeRange kFixedSize = {{300, 300}, {300, 300}};
    CKSnapshotVerifyComponent(component, kFixedSize, nameForInsets(insets));
  }
}

/** Regression test, there was a bug mixing insets with infinite and zero sizes */
- (void)testInsetsWithInfinityAndZeroInsetValue
{
  for (NSUInteger combination = 0; combination < 16; combination++) {
    UIEdgeInsets insets = insetsForCombination(combination, 0);
    CKComponent *component = [CKInsetTestBackgroundComponent
                              newWithComponent:
                              [CKInsetComponent
                               newWithInsets:insets
                               component:[CKInsetTestBlockComponent newWithColor:[UIColor greenColor] size:{10,10}]]];
    static CKSizeRange kFixedSize = {{300, 300}, {300, 300}};
    CKSnapshotVerifyComponent(component, kFixedSize, nameForInsets(insets));
  }
}

@end

@implementation CKInsetTestBackgroundComponent

+ (instancetype)newWithComponent:(CKComponent *)component
{
  return [super newWithComponent:
          [CKBackgroundLayoutComponent
                            newWithComponent:
                            component
                            background:
           [CKInsetTestBlockComponent newWithColor:[UIColor grayColor] size:{}]]];
}

@end

@implementation CKInsetTestBlockComponent

+ (instancetype)newWithColor:(UIColor *)color size:(const CKComponentSize &)size
{
  return [super newWithComponent:
          [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), color}}} size:size]];
}

@end
