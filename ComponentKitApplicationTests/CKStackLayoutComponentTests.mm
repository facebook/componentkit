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

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKRatioLayoutComponent.h>
#import <ComponentKit/CKStackLayoutComponent.h>

static CKComponentViewConfiguration kWhiteBackgroundView = {
  [UIView class], {{@selector(setBackgroundColor:), [UIColor whiteColor]}}
};

@interface CKStackLayoutComponentTests : CKComponentSnapshotTestCase
@end

@implementation CKStackLayoutComponentTests

- (void)setUp
{
  [super setUp];
  self.recordMode = NO;
}

- (void)testUnderflowBehaviors
{
  // width 300px; height 0-300px
  static CKSizeRange kSize = {{300, 0}, {300, 300}};
  CKSnapshotVerifyComponent([self _layoutWithJustify:CKStackLayoutJustifyContentStart flexFactor:0], kSize, @"justifyStart");
  CKSnapshotVerifyComponent([self _layoutWithJustify:CKStackLayoutJustifyContentCenter flexFactor:0], kSize, @"justifyCenter");
  CKSnapshotVerifyComponent([self _layoutWithJustify:CKStackLayoutJustifyContentEnd flexFactor:0], kSize, @"justifyEnd");
  CKSnapshotVerifyComponent([self _layoutWithJustify:CKStackLayoutJustifyContentStart flexFactor:1], kSize, @"flex");
}

- (void)testOverflowBehaviors
{
  // width 110px; height 0-300px
  static CKSizeRange kSize = {{110, 0}, {110, 300}};
  CKSnapshotVerifyComponent([self _layoutWithJustify:CKStackLayoutJustifyContentStart flexFactor:0], kSize, @"justifyStart");
  CKSnapshotVerifyComponent([self _layoutWithJustify:CKStackLayoutJustifyContentCenter flexFactor:0], kSize, @"justifyCenter");
  CKSnapshotVerifyComponent([self _layoutWithJustify:CKStackLayoutJustifyContentEnd flexFactor:0], kSize, @"justifyEnd");
  CKSnapshotVerifyComponent([self _layoutWithJustify:CKStackLayoutJustifyContentStart flexFactor:1], kSize, @"flex");
}

- (void)testOverflowBehaviorsWhenAllFlexShrinkComponentsHaveBeenClampedToZeroButViolationStillExists
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{.direction = CKStackLayoutDirectionHorizontal}
   children:{
     // After flexShrink-able children are all clamped to zero, the sum of their widths is 100px.
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}],
       .flexShrink = 0,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}],
       .flexShrink = 1,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}],
       .flexShrink = 0,
     },
   }];

  // Width is 75px--that's less than the sum of the widths of the child components, which is 100px.
  static CKSizeRange kSize = {{75, 0}, {75, 150}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testFlexWithUnequalIntrinsicSizes
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal,
   }
   children:{
     flexChild([CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}], 1),
     flexChild([CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{150,150}], 1),
     flexChild([CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}], 1),
   }];

  // width 300px; height 0-150px.
  static CKSizeRange kUnderflowSize = {{300, 0}, {300, 150}};
  CKSnapshotVerifyComponent(c, kUnderflowSize, @"underflow");

  // width 200px; height 0-150px.
  static CKSizeRange kOverflowSize = {{200, 0}, {200, 150}};
  CKSnapshotVerifyComponent(c, kOverflowSize, @"overflow");
}

- (void)testCrossAxisSizeBehaviors
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical,
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}]},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,50}]},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,50}]},
   }];

  // width 0-300px; height 300px
  static CKSizeRange kVariableHeight = {{0, 300}, {300, 300}};
  CKSnapshotVerifyComponent(c, kVariableHeight, @"variableHeight");

  // width 300px; height 300px
  static CKSizeRange kFixedHeight = {{300, 300}, {300, 300}};
  CKSnapshotVerifyComponent(c, kFixedHeight, @"fixedHeight");
}

- (void)testStackSpacing
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical,
     .spacing = 10,
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}]},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,50}]},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,50}]},
   }];

  // width 0-300px; height 300px
  static CKSizeRange kVariableHeight = {{0, 300}, {300, 300}};
  CKSnapshotVerifyComponent(c, kVariableHeight, @"variableHeight");
}

- (void)testStackSpacingWithChildrenHavingNilComponents
{
  // This should take a zero height since all children have a nil component. If it takes a height > 0, a blue border
  // will show up, hence failing the test.

  static const CKComponentViewAttribute borderAttribute = {"CKStackLayoutComponentTest.border", ^(UIView *view, id value) {
    view.layer.borderColor = [UIColor blueColor].CGColor;
    view.layer.borderWidth = 3.0f;
  }};

  CKComponent *c =
  [CKStackLayoutComponent
   newWithView:{[UIView class], {{borderAttribute, nil}}}
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical,
     .spacing = 10,
     .alignItems = CKStackLayoutAlignItemsStretch
   }
   children:{
     {nil},
     {nil},
   }];

  // width 300px; height 0-300px
  static CKSizeRange kVariableHeight = {{300, 0}, {300, 300}};
  CKSnapshotVerifyComponentWithInsets(c, kVariableHeight, UIEdgeInsetsMake(10, 10, 10, 10), @"variableHeight");
}

- (void)testComponentSpacing
{
  // width 0-INF; height 0-INF
  static CKSizeRange kAnySize = {{0, 0}, {INFINITY, INFINITY}};

  CKStackLayoutComponent *spacingBefore =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical,
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}]
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,70}],
       .spacingBefore = 10
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,90}],
       .spacingBefore = 20
     },
   }];
  CKSnapshotVerifyComponent(spacingBefore, kAnySize, @"spacingBefore");

  CKStackLayoutComponent *spacingAfter =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical,
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}]
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,70}],
       .spacingAfter = 10
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,90}],
       .spacingAfter = 20
     },
   }];
  CKSnapshotVerifyComponent(spacingAfter, kAnySize, @"spacingAfter");

  CKStackLayoutComponent *spacingBalancedOut =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical,
     .spacing = 10,
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}]
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,70}],
       .spacingBefore = -10,
       .spacingAfter = -10
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,90}],
     },
   }];
  CKSnapshotVerifyComponent(spacingBalancedOut, kAnySize, @"spacingBalancedOut");
}

- (void)testJustifiedCenterWithComponentSpacing
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical,
     .justifyContent = CKStackLayoutJustifyContentCenter,
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}], 0},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,70}], 20},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,90}], 30},
   }];

  // width 0-300px; height 300px
  static CKSizeRange kVariableHeight = {{0, 300}, {300, 300}};
  CKSnapshotVerifyComponent(c, kVariableHeight, @"variableHeight");
}

- (void)testComponentThatChangesCrossSizeWhenMainSizeIsFlexed
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal,
   }
   children:{
     {
       [CKRatioLayoutComponent
        newWithRatio:1.5
        size:{}
        component:
        [CKComponent
         newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}}
         size:{.height = 150}]],
       .flexBasis = CKRelativeDimension::Percent(1),
       .flexGrow = 1,
       .flexShrink = 1
     },
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}]},
   }];

   static CKSizeRange kFixedWidth = {{150, 0}, {150, INFINITY}};
  CKSnapshotVerifyComponent(c, kFixedWidth, nil);
}

- (void)testAlignCenterWithFlexedMainDimension
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical,
     .alignItems = CKStackLayoutAlignItemsCenter,
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{100,100}],
       .flexShrink = 1,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}],
       .flexShrink = 1,
     },
   }];

  static CKSizeRange kFixedWidth = {{150, 0}, {150, 100}};
  CKSnapshotVerifyComponent(c, kFixedWidth, nil);
}

- (void)testAlignCenterWithIndefiniteCrossDimension
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal,
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{100,100}]
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}],
       .alignSelf = CKStackLayoutAlignSelfCenter,
     },
   }];

  static CKSizeRange kFixedWidth = {{150, 0}, {150, INFINITY}};
  CKSnapshotVerifyComponent(c, kFixedWidth, nil);
}

- (void)testAlignedStart
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical,
     .justifyContent = CKStackLayoutJustifyContentCenter,
     .alignItems = CKStackLayoutAlignItemsStart
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}], 0},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,70}], 20},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,90}], 30},
   }];
  static CKSizeRange kExactSize = {{300, 300}, {300, 300}};
  CKSnapshotVerifyComponent(c, kExactSize, nil);
}

- (void)testAlignedEnd
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical,
     .justifyContent = CKStackLayoutJustifyContentCenter,
     .alignItems = CKStackLayoutAlignItemsEnd
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}], 0},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,70}], 20},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,90}], 30},
   }];
  static CKSizeRange kExactSize = {{300, 300}, {300, 300}};
  CKSnapshotVerifyComponent(c, kExactSize, nil);
}

- (void)testAlignedCenter
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical,
     .justifyContent = CKStackLayoutJustifyContentCenter,
     .alignItems = CKStackLayoutAlignItemsCenter
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}], 0},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,70}], 20},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,90}], 30},
   }];
  static CKSizeRange kExactSize = {{300, 300}, {300, 300}};
  CKSnapshotVerifyComponent(c, kExactSize, nil);
}

- (void)testAlignedStretchNoChildExceedsMin
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical,
     .justifyContent = CKStackLayoutJustifyContentCenter,
     .alignItems = CKStackLayoutAlignItemsStretch
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}], 0},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,70}], 20},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,90}], 30},
   }];
  static CKSizeRange kVariableSize = {{200, 200}, {300, 300}};

  // all children should be 200px wide
  CKSnapshotVerifyComponent(c, kVariableSize, nil);
}

- (void)testAlignedStretchOneChildExceedsMin
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical,
     .justifyContent = CKStackLayoutJustifyContentCenter,
     .alignItems = CKStackLayoutAlignItemsStretch
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}], 0},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,70}], 20},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,90}], 30},
   }];
  static CKSizeRange kVariableSize = {{50, 50}, {300, 300}};

  // all children should be 150px wide
  CKSnapshotVerifyComponent(c, kVariableSize, nil);
}

- (void)testEmptyStack
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{}
   children:{}];
  static CKSizeRange kVariableSize = {{50, 50}, {300, 300}};

  CKSnapshotVerifyComponent(c, kVariableSize, nil);
}

- (void)testFixedFlexBasisAppliedWhenFlexingItems
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{.direction = CKStackLayoutDirectionHorizontal}
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}],
       .flexGrow = 1,
       .flexBasis = 10
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{150,150}],
       .flexGrow = 1,
       .flexBasis = 10,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}],
       .flexGrow = 1,
       .flexBasis = 10,
     },
   }];

  // width 300px; height 0-150px.
  static CKSizeRange kUnderflowSize = {{300, 0}, {300, 150}};
  CKSnapshotVerifyComponent(c, kUnderflowSize, @"underflow");

  // width 200px; height 0-150px.
  static CKSizeRange kOverflowSize = {{200, 0}, {200, 150}};
  CKSnapshotVerifyComponent(c, kOverflowSize, @"overflow");
}

- (void)testPercentageFlexBasisResolvesAgainstParentSize
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{.direction = CKStackLayoutDirectionHorizontal}
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}],
       .flexGrow = 1,
       // This should override the intrinsic size of 50pts and instead compute to 50% = 100pts.
       // The result should be that the red box is twice as wide as the blue and gree boxes after flexing.
       .flexBasis = CKRelativeDimension::Percent(0.5)
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}],
       .flexGrow = 1,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}],
       .flexGrow = 1,
     },
   }];

  static CKSizeRange kSize = {{200, 0}, {200, INFINITY}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testFixedFlexBasisOverridesIntrinsicSizeForNonFlexingChildren
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{.direction = CKStackLayoutDirectionHorizontal}
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}],
       .flexBasis = 20
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{150,150}],
       .flexBasis = 20,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}],
       .flexBasis = 20,
     },
   }];

  static CKSizeRange kSize = {{300, 0}, {300, 150}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testCrossAxisStretchingOccursAfterStackAxisFlexing
{
  // If cross axis stretching occurred *before* flexing, then the blue child would be stretched to 3000 points tall.
  // Instead it should be stretched to 300 points tall, matching the red child and not overlapping the green inset.
  CKComponent *c =
  [CKInsetComponent
   newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}}
   insets:{10, 10, 10, 10}
   component:
   [CKStackLayoutComponent
    newWithView:{}
    size:{}
    style:{
      .direction = CKStackLayoutDirectionHorizontal,
      .alignItems = CKStackLayoutAlignItemsStretch,
    }
    children:{
      {
        [CKComponent
         newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}}
         size:{.width = 10}],
      },
      {
        [CKComponent
         newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}}
         size:{500, 500}],
        .flexGrow = 1,
        .flexShrink = 1,
      },
    }]];

  static CKSizeRange kSize = {{300, 0}, {300, INFINITY}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testPositiveViolationIsDistributedEqually
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}],
       .flexGrow = 1,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}],
       .flexGrow = 0,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}],
       .flexGrow = 1,
     },
   }];
  // In this scenario a width of 350 results in a positive violation of 200.
  // Due to each flexible child component specifying a flex grow factor of 1 the violation will be distributed evenly.
  static CKSizeRange kSize = {{350, 350}, {350, 350}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testPositiveViolationIsDistributedEquallyWithArbitraryFloats
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}],
       .flexGrow = 0.5,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}],
       .flexGrow = 0,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}],
       .flexGrow = 0.5,
     },
   }];
  // In this scenario a width of 350 results in a positive violation of 200.
  // Due to each flexible child component specifying a flex grow factor of 0.5 the violation will be distributed evenly.
  static CKSizeRange kSize = {{350, 350}, {350, 350}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testPositiveViolationIsDistributedProportionally
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}],
       .flexGrow = 1,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}],
       .flexGrow = 2,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}],
       .flexGrow = 1,
     },
   }];
  // In this scenario a width of 350 results in a positive violation of 200.
  // The first and third child components specify a flex grow factor of 1 and will flex by 50.
  // The second child component specifies a flex grow factor of 2 and will flex by 100.
  static CKSizeRange kSize = {{350, 350}, {350, 350}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testPositiveViolationIsDistributedProportionallyWithArbitraryFloats
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}],
       .flexGrow = 0.25,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}],
       .flexGrow = 0.50,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}],
       .flexGrow = 0.25,
     },
   }];
  // In this scenario a width of 350 results in a positive violation of 200.
  // The first and third child components specify a flex grow factor of 0.25 and will flex by 50.
  // The second child component specifies a flex grow factor of 0.25 and will flex by 100.
  static CKSizeRange kSize = {{350, 350}, {350, 350}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testPositiveViolationIsDistributedEquallyAmongMixedChildren
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}],
       .flexShrink = 1,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}],
       .flexGrow = 1,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}],
       .flexShrink = 0,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor yellowColor]}}} size:{50,50}],
       .flexGrow = 1,
     },
   }];
  // In this scenario a width of 400 results in a positive violation of 200.
  // The first and third child components specify a flex shrink factor of 1 and 0, respectively. They won't flex.
  // The second and fourth child components specify a flex grow factor of 1 and will flex by 100.
  static CKSizeRange kSize = {{400, 400}, {400, 400}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testPositiveViolationIsDistributedEquallyAmongMixedChildrenWithArbitraryFloats
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}],
       .flexShrink = 1,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}],
       .flexGrow = 0.5,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}],
       .flexShrink = 0,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor yellowColor]}}} size:{50,50}],
       .flexGrow = 0.5,
     },
   }];
  // In this scenario a width of 400 results in a positive violation of 200.
  // The first and third child components specify a flex shrink factor of 1 and 0, respectively. They won't flex.
  // The second and fourth child components specify a flex grow factor of 0.5 and will flex by 100.
  static CKSizeRange kSize = {{400, 400}, {400, 400}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testPositiveViolationIsDistributedProportionallyAmongMixedChildren
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}],
       .flexShrink = 1,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}],
       .flexGrow = 3,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}],
       .flexShrink = 0,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor yellowColor]}}} size:{50,50}],
       .flexGrow = 1,
     },
   }];
  // In this scenario a width of 400 results in a positive violation of 200.
  // The first and third child components specify a flex shrink factor of 1 and 0, respectively. They won't flex.
  // The second child component specifies a flex grow factor of 3 and will flex by 150.
  // The fourth child component specifies a flex grow factor of 1 and will flex by 50.
  static CKSizeRange kSize = {{400, 400}, {400, 400}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testPositiveViolationIsDistributedProportionallyAmongMixedChildrenWithArbitraryFloats
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}],
       .flexShrink = 1,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}],
       .flexGrow = 0.75,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}],
       .flexShrink = 0,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor yellowColor]}}} size:{50,50}],
       .flexGrow = 0.25,
     },
   }];
  // In this scenario a width of 400 results in a positive violation of 200.
  // The first and third child components specify a flex shrink factor of 1 and 0, respectively. They won't flex.
  // The second child component specifies a flex grow factor of 0.75 and will flex by 150.
  // The fourth child component specifies a flex grow factor of 0.25 and will flex by 50.
  static CKSizeRange kSize = {{400, 400}, {400, 400}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testRemainingViolationIsAppliedProperlyToFirstFlexibleChild
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,25}],
       .flexGrow = 0,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,0}],
       .flexGrow = 1,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,100}],
       .flexGrow = 1,
     },
   }];
  static CKSizeRange kSize = {{300, 300}, {300, 300}};
  // In this scenario a width of 300 results in a positive violation of 175.
  // The second and third child components specify a flex grow factor of 1 and will flex by 88 and 87, respectively.
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testRemainingViolationIsAppliedProperlyToFirstFlexibleChildWithArbitraryFloats
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,25}],
       .flexGrow = 0,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,0}],
       .flexGrow = 0.5,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,100}],
       .flexGrow = 0.5,
     },
   }];
  static CKSizeRange kSize = {{300, 300}, {300, 300}};
  // In this scenario a width of 300 results in a positive violation of 175.
  // The second and third child components specify a flex grow factor of 0.5 and will flex by 88 and 87, respectively.
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testNegativeViolationIsDistributedBasedOnSize
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{300,50}],
       .flexShrink = 1,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,50}],
       .flexShrink = 0,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{200,50}],
       .flexShrink = 1,
     },
   }];
  // In this scenario a width of 400 results in a negative violation of 200.
  // The first and third child components specify a flex shrink factor of 1 and will flex by -120 and -80, respectively.
  static CKSizeRange kSize = {{400, 400}, {400, 400}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testNegativeViolationIsDistributedBasedOnSizeWithArbitraryFloats
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{300,50}],
       .flexShrink = 0.5,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,50}],
       .flexShrink = 0,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{200,50}],
       .flexShrink = 0.5,
     },
   }];
  // In this scenario a width of 400 results in a negative violation of 200.
  // The first and third child components specify a flex shrink factor of 0.5 and will flex by -120 and -80, respectively.
  static CKSizeRange kSize = {{400, 400}, {400, 400}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testNegativeViolationIsDistributedBasedOnSizeAndFlexFactor
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,300}],
       .flexShrink = 2,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,100}],
       .flexShrink = 1,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,200}],
       .flexShrink = 2,
     },
   }];
  // In this scenario a width of 400 results in a negative violation of 200.
  // The first and third child components specify a flex shrink factor of 2 and will flex by -109 and -72, respectively.
  // The second child component specifies a flex shrink factor of 1 and will flex by -18.
  static CKSizeRange kSize = {{400, 400}, {400, 400}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testNegativeViolationIsDistributedBasedOnSizeAndFlexFactorWithArbitraryFloats
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,300}],
       .flexShrink = 0.4,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,100}],
       .flexShrink = 0.2,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,200}],
       .flexShrink = 0.4,
     },
   }];
  // In this scenario a width of 400 results in a negative violation of 200.
  // The first and third child components specify a flex shrink factor of 0.4 and will flex by -109 and -72, respectively.
  // The second child component specifies a flex shrink factor of 0.2 and will flex by -18.
  static CKSizeRange kSize = {{400, 400}, {400, 400}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testNegativeViolationIsDistributedBasedOnSizeAmongMixedChildrenChildren
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{150,50}],
       .flexGrow = 1,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{150,50}],
       .flexShrink = 1,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,50}],
       .flexGrow = 0,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor yellowColor]}}} size:{150,50}],
       .flexShrink = 1,
     },
   }];
  // In this scenario a width of 400 results in a negative violation of 200.
  // The first and third child components specify a flex grow factor of 1 and 0, respectively. They won't flex.
  // The second and fourth child components specify a flex shrink factor of 1 and will flex by -100.
  static CKSizeRange kSize = {{400, 400}, {400, 400}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testNegativeViolationIsDistributedBasedOnSizeAmongMixedChildrenWithArbitraryFloats
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{150,50}],
       .flexGrow = 1,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{150,50}],
       .flexShrink = 0.5,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,50}],
       .flexGrow = 0,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor yellowColor]}}} size:{150,50}],
       .flexShrink = 0.5,
     },
   }];
  // In this scenario a width of 400 results in a negative violation of 200.
  // The first and third child components specify a flex grow factor of 1 and 0, respectively. They won't flex.
  // The second and fourth child components specify a flex shrink factor of 0.5 and will flex by -100.
  static CKSizeRange kSize = {{400, 400}, {400, 400}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testNegativeViolationIsDistributedBasedOnSizeAndFlexFactorAmongMixedChildren
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,150}],
       .flexGrow = 1,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,100}],
       .flexShrink = 1,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,150}],
       .flexGrow = 0,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor yellowColor]}}} size:{50,200}],
       .flexShrink = 3,
     },
   }];
  // In this scenario a width of 400 results in a negative violation of 200.
  // The first and third child components specify a flex grow factor of 1 and 0, respectively. They won't flex.
  // The second child component specifies a flex shrink factor of 1 and will flex by -28.
  // The fourth child component specifies a flex shrink factor of 3 and will flex by -171.
  static CKSizeRange kSize = {{400, 400}, {400, 400}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testNegativeViolationIsDistributedBasedOnSizeAndFlexFactorAmongMixedChildrenArbitraryFloats
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,150}],
       .flexGrow = 1,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,100}],
       .flexShrink = 0.25,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,150}],
       .flexGrow = 0,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor yellowColor]}}} size:{50,200}],
       .flexShrink = 0.75,
     },
   }];
  // In this scenario a width of 400 results in a negative violation of 200.
  // The first and third child components specify a flex grow factor of 1 and 0, respectively. They won't flex.
  // The second child component specifies a flex shrink factor of 0.25 and will flex by -28.
  // The fourth child component specifies a flex shrink factor of 0.75 and will flex by -171.
  static CKSizeRange kSize = {{400, 400}, {400, 400}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testNegativeViolationIsDistributedBasedOnSizeAndFlexFactorDoesNotShrinkToZero
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{300,50}],
       .flexShrink = 1,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,50}],
       .flexShrink = 2,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{200,50}],
       .flexShrink = 1,
     },
   }];
  // In this scenario a width of 400 results in a negative violation of 200.
  // The first and third child components specify a flex shrink factor of 1 and will flex by 50.
  // The second child component specifies a flex shrink factor of 2 and will flex by -57. It will have a width of 43.
  static CKSizeRange kSize = {{400, 400}, {400, 400}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testNegativeViolationIsDistributedBasedOnSizeAndFlexFactorDoesNotShrinkToZeroWithArbitraryFloats
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{300,50}],
       .flexShrink = 0.25,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,50}],
       .flexShrink = 0.50,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{200,50}],
       .flexShrink = 0.25,
     },
   }];
  // In this scenario a width of 400 results in a negative violation of 200.
  // The first and third child components specify a flex shrink factor of 0.25 and will flex by 50.
  // The second child component specifies a flex shrink factor of 0.50 and will flex by -57. It will have a width of 43.
  static CKSizeRange kSize = {{400, 400}, {400, 400}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

static CKStackLayoutComponentChild flexChild(CKComponent *c, CGFloat flexFactor)
{
  return {c, .flexGrow = flexFactor, .flexShrink = flexFactor};
}

- (CKStackLayoutComponent *)_layoutWithJustify:(CKStackLayoutJustifyContent)justify flexFactor:(NSInteger)flexFactor
{
  return
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal,
     .justifyContent = justify,
   }
   children:{
     flexChild([CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}], flexFactor),
     flexChild([CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}], flexFactor),
     flexChild([CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}], flexFactor),
   }];
}

- (void)testNestedStackLayoutStretchDoesNotViolateWidth
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:{
     [UIView class],
     {
       {@selector(setBackgroundColor:), [UIColor blueColor]}
     }
   }
   size:{
     .width = 100,
     .height = 100
   }
   style:{
     .direction = CKStackLayoutDirectionVertical,
     .alignItems = CKStackLayoutAlignItemsStretch
   }
   children:{
     {
       [CKComponent
        newWithView:{
          [UIView class],
          {
            {@selector(setBackgroundColor:), [UIColor redColor]}
          }
        } size:{
          .width = 50,
          .height = 50
        }]
     }
   }];
  static CKSizeRange kSize = {{0, 0}, {300, INFINITY}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

@end
