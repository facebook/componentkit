/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant 
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKitTestLib/CKComponentSnapshotTestCase.h>

#import "CKComponent.h"
#import "CKComponentSubclass.h"
#import "CKRatioLayoutComponent.h"
#import "CKStackLayoutComponent.h"

static CKComponentViewConfiguration whiteBg = {[UIView class], {{@selector(setBackgroundColor:), [UIColor whiteColor]}}};

@interface CKStackLayoutComponentTests : CKComponentSnapshotTestCase
@end

@implementation CKStackLayoutComponentTests

- (void)setUp
{
  [super setUp];
  self.recordMode = NO;
}

static CKStackLayoutComponentChild flexChild(CKComponent *c, BOOL flex)
{
  return {c, .flexGrow = flex, .flexShrink = flex};
}

- (CKStackLayoutComponent *)_layoutWithJustify:(CKStackLayoutJustifyContent)justify
                                          flex:(BOOL)flex
{
  return [CKStackLayoutComponent
          newWithView:whiteBg
          size:{}
          style:{
            .direction = CKStackLayoutDirectionHorizontal,
            .justifyContent = justify,
          }
          children:{
            flexChild([CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}], flex),
            flexChild([CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}], flex),
            flexChild([CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}], flex),
          }];
}

- (void)testUnderflowBehaviors
{
  // width 300px; height 0-300px
  static CKSizeRange kSize = {{300, 0}, {300, 300}};
  CKSnapshotVerifyComponent([self _layoutWithJustify:CKStackLayoutJustifyContentStart flex:NO], kSize, @"justifyStart");
  CKSnapshotVerifyComponent([self _layoutWithJustify:CKStackLayoutJustifyContentCenter flex:NO], kSize, @"justifyCenter");
  CKSnapshotVerifyComponent([self _layoutWithJustify:CKStackLayoutJustifyContentEnd flex:NO], kSize, @"justifyEnd");
  CKSnapshotVerifyComponent([self _layoutWithJustify:CKStackLayoutJustifyContentStart flex:YES], kSize, @"flex");
}

- (void)testOverflowBehaviors
{
  // width 110px; height 0-300px
  static CKSizeRange kSize = {{110, 0}, {110, 300}};
  CKSnapshotVerifyComponent([self _layoutWithJustify:CKStackLayoutJustifyContentStart flex:NO], kSize, @"justifyStart");
  CKSnapshotVerifyComponent([self _layoutWithJustify:CKStackLayoutJustifyContentCenter flex:NO], kSize, @"justifyCenter");
  CKSnapshotVerifyComponent([self _layoutWithJustify:CKStackLayoutJustifyContentEnd flex:NO], kSize, @"justifyEnd");
  CKSnapshotVerifyComponent([self _layoutWithJustify:CKStackLayoutJustifyContentStart flex:YES], kSize, @"flex");
}

- (void)testOverflowBehaviorsWhenAllFlexShrinkComponentsHaveBeenClampedToZeroButViolationStillExists
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:whiteBg
   size:{}
   style:{.direction = CKStackLayoutDirectionHorizontal}
   children:{
     // After flexShrink-able children are all clamped to zero, the sum of their widths is 100px.
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}],
       .flexShrink = NO,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}],
       .flexShrink = YES,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}],
       .flexShrink = NO,
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
   newWithView:whiteBg
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal,
   }
   children:{
     flexChild([CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}], YES),
     flexChild([CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{150,150}], YES),
     flexChild([CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}], YES),
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
   newWithView:whiteBg
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
   newWithView:whiteBg
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
   newWithView:whiteBg
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
   newWithView:whiteBg
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
   newWithView:whiteBg
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
   newWithView:whiteBg
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
   newWithView:whiteBg
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
       .flexGrow = YES,
       .flexShrink = YES
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
   newWithView:whiteBg
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical,
     .alignItems = CKStackLayoutAlignItemsCenter,
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{100,100}],
       .flexShrink = YES,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}],
       .flexShrink = YES,
     },
   }];

  static CKSizeRange kFixedWidth = {{150, 0}, {150, 100}};
  CKSnapshotVerifyComponent(c, kFixedWidth, nil);
}

- (void)testAlignCenterWithIndefiniteCrossDimension
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:whiteBg
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
   newWithView:whiteBg
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
   newWithView:whiteBg
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
   newWithView:whiteBg
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
   newWithView:whiteBg
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
   newWithView:whiteBg
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
   newWithView:whiteBg
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
   newWithView:whiteBg
   size:{}
   style:{.direction = CKStackLayoutDirectionHorizontal}
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}],
       .flexGrow = YES,
       .flexBasis = 10
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{150,150}],
       .flexGrow = YES,
       .flexBasis = 10,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}],
       .flexGrow = YES,
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
   newWithView:whiteBg
   size:{}
   style:{.direction = CKStackLayoutDirectionHorizontal}
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}],
       .flexGrow = YES,
       // This should override the intrinsic size of 50pts and instead compute to 50% = 100pts.
       // The result should be that the red box is twice as wide as the blue and gree boxes after flexing.
       .flexBasis = CKRelativeDimension::Percent(0.5)
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}],
       .flexGrow = YES,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}],
       .flexGrow = YES,
     },
   }];

  static CKSizeRange kSize = {{200, 0}, {200, INFINITY}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testFixedFlexBasisOverridesIntrinsicSizeForNonFlexingChildren
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:whiteBg
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
         size:{.width = 10, .height = 0}],
      },
      {
        [CKRatioLayoutComponent
         newWithRatio:1.0
         size:{}
         component:
         [CKComponent
          newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}}
          size:{3000, 3000}]],
        .flexGrow = YES,
        .flexShrink = YES,
      },
    }]];

  static CKSizeRange kSize = {{300, 0}, {300, INFINITY}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testViolationIsDistributedEquallyAmongFlexibleChildComponents
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:whiteBg
   size:{}
   style:{.direction = CKStackLayoutDirectionHorizontal}
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{300,50}],
       .flexShrink = YES,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,50}],
       .flexShrink = NO,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{200,50}],
       .flexShrink = YES,
     },
   }];

  // A width of 400px results in a violation of 200px. This is distributed equally among each flexible component,
  // causing both of them to be shrunk by 100px, resulting in widths of 300px, 100px, and 50px.
  // In the W3 flexbox standard, flexible components are shrunk proportionate to their original sizes,
  // resulting in widths of 180px, 100px, and 120px.
  // This test verifies the current behavior--the snapshot contains widths 300px, 100px, and 50px.
  static CKSizeRange kSize = {{400, 0}, {400, 150}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

@end
