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

#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKStackLayoutComponent.h>
#import <ComponentKit/CKInsetComponent.h>
#import <ComponentKit/CKRatioLayoutComponent.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentLayoutBaseline.h>

#import <FIGColor/FIGColor.h>

/* Sets baseline to be 10 points higher than normal. */
@interface CKCustomBaselineComponent : CKComponent

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view
                       size:(const CKComponentSize &)size
                   baseline:(CGFloat)baseline;
@end

@implementation CKCustomBaselineComponent
{
  CGFloat _baseline;
}

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view
                       size:(const CKComponentSize &)size
                   baseline:(CGFloat)baseline
{
  CKCustomBaselineComponent *c = [super newWithView:view size:size];
  if (c) {
    c->_baseline = baseline;
  }
  
  return c;
}

- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
{
  CKComponentLayout parentLayout = [super computeLayoutThatFits:constrainedSize];
  NSMutableDictionary *extra = parentLayout.extra ? [parentLayout.extra mutableCopy]: [NSMutableDictionary dictionary];
  extra[kCKComponentLayoutExtraBaselineKey] = @(_baseline);
  parentLayout.extra = extra;
  return parentLayout;
}

@end

// This will be removed after we merge CSSLayout component into main body

#define FBTakeSnapshotOfComponentWithInsets(component__, sizeRange__, insets__, identifier__) \
{ \
FBTakeSnapshotOfComponent([CKInsetComponent newWithInsets:insets__ component:component__], sizeRange__, identifier__); \
}

static CKComponentViewConfiguration kWhiteBackgroundView = {
  [UIView class], {{@selector(setBackgroundColor:), [UIColor whiteColor]}}
};

static CKComponentViewConfiguration kLightGrayBackgroundView = {
  [UIView class], {{@selector(setBackgroundColor:), [UIColor lightGrayColor]}}
};

@interface CKStackLayoutComponentSnapshotTests : FBServerSnapshotTestCase
@end

@implementation CKStackLayoutComponentSnapshotTests

- (void)testUnderflowBehaviors
{
  // width 300px; height 0-300px
  static CKSizeRange kSize = {{300, 0}, {300, 300}};
  FBTakeSnapshotOfComponent([self _layoutWithJustify:CKStackLayoutJustifyContentStart flexFactor:0], kSize, @"justifyStart");
  FBTakeSnapshotOfComponent([self _layoutWithJustify:CKStackLayoutJustifyContentCenter flexFactor:0], kSize, @"justifyCenter");
  FBTakeSnapshotOfComponent([self _layoutWithJustify:CKStackLayoutJustifyContentEnd flexFactor:0], kSize, @"justifyEnd");
  FBTakeSnapshotOfComponent([self _layoutWithJustify:CKStackLayoutJustifyContentStart flexFactor:1], kSize, @"flex");
}

- (void)testOverflowBehaviors
{
  // width 110px; height 0-300px
  static CKSizeRange kSize = {{110, 0}, {110, 300}};
  FBTakeSnapshotOfComponent([self _layoutWithJustify:CKStackLayoutJustifyContentStart flexFactor:0], kSize, @"justifyStart");
  FBTakeSnapshotOfComponent([self _layoutWithJustify:CKStackLayoutJustifyContentCenter flexFactor:0], kSize, @"justifyCenter");
  FBTakeSnapshotOfComponent([self _layoutWithJustify:CKStackLayoutJustifyContentEnd flexFactor:0], kSize, @"justifyEnd");
  FBTakeSnapshotOfComponent([self _layoutWithJustify:CKStackLayoutJustifyContentStart flexFactor:1], kSize, @"flex");
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
  FBTakeSnapshotOfComponent(c, kSize, nil);
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
  FBTakeSnapshotOfComponent(c, kUnderflowSize, @"underflow");
  
  // width 200px; height 0-150px.
  static CKSizeRange kOverflowSize = {{200, 0}, {200, 150}};
  FBTakeSnapshotOfComponent(c, kOverflowSize, @"overflow");
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
  FBTakeSnapshotOfComponent(c, kVariableHeight, @"variableHeight");
  
  // width 300px; height 300px
  static CKSizeRange kFixedHeight = {{300, 300}, {300, 300}};
  FBTakeSnapshotOfComponent(c, kFixedHeight, @"fixedHeight");
}

- (void)testSpacing
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
  FBTakeSnapshotOfComponent(c, kVariableHeight, @"variableHeight");
}

- (void)testNegativeSpacing
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical,
     .spacing = -10,
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}]},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,50}]},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,50}]},
   }];
  
  // width 0-300px; height 300px
  static CKSizeRange kVariableHeight = {{0, 300}, {300, 300}};
  FBTakeSnapshotOfComponent(c, kVariableHeight, @"variableHeight");
}

- (void)testSpacingWithChildrenHavingNilComponents
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
  FBTakeSnapshotOfComponentWithInsets(c, kVariableHeight, UIEdgeInsetsMake(10, 10, 10, 10), @"variableHeight");
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
  FBTakeSnapshotOfComponent(spacingBefore, kAnySize, @"spacingBefore");
  
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
  FBTakeSnapshotOfComponent(spacingAfter, kAnySize, @"spacingAfter");
  
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
  FBTakeSnapshotOfComponent(spacingBalancedOut, kAnySize, @"spacingBalancedOut");
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
  FBTakeSnapshotOfComponent(c, kVariableHeight, @"variableHeight");
}

- (void)testZOrderNoChangeLayoutOrder
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical,
     .spacing = -10,
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}],
       .zIndex = 0},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,50}],
       .zIndex = 1},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,50}],
       .zIndex = 2},
   }];
  
  // width 0-300px; height 300px
  static CKSizeRange kVariableHeight = {{0, 300}, {300, 300}};
  FBTakeSnapshotOfComponent(c, kVariableHeight, @"variableHeight");
}

- (void)testZOrderPartialChangeLayoutOrder
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical,
     .spacing = -10,
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}],
       .zIndex = 0},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,50}],
       .zIndex = 1},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,50}],
       .zIndex = 0},
   }];
  
  // width 0-300px; height 300px
  static CKSizeRange kVariableHeight = {{0, 300}, {300, 300}};
  FBTakeSnapshotOfComponent(c, kVariableHeight, @"variableHeight");
}

- (void)testZOrderChangeLayoutOrder
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical,
     .spacing = -10,
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}],
       .zIndex = 2},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,50}],
       .zIndex = 1},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,50}],
       .zIndex = 0},
   }];
  
  // width 0-300px; height 300px
  static CKSizeRange kVariableHeight = {{0, 300}, {300, 300}};
  FBTakeSnapshotOfComponent(c, kVariableHeight, @"variableHeight");
}

/**
 The expected layout is [-------red------|---blue--], with no gray visible.
 The blue doesn't extend all the way.
 Fiddle: https://jsfiddle.net/g0kaahb7/1/
 */
- (void)testMinWidthIsRespected
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kLightGrayBackgroundView
   size:{.width=120}
   style:{
     .direction = CKStackLayoutDirectionHorizontal,
     .alignItems = CKStackLayoutAlignItemsStretch,
   }
   children:{
     {[CKComponent
       newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}}
       size:{
         .minWidth = 90,
         .height = 50
       }],
       .flexGrow = 1,
       .flexShrink = 1,
       .flexBasis = 80
     },
     {[CKComponent
       newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}}
       size:{
         .height = 50
       }],
       .flexGrow = 1,
       .flexShrink = 1,
       .flexBasis = 80
     },
   }];
  
  static CKSizeRange kSize = {{0, 50}, {120, 50}};
  FBTakeSnapshotOfComponent(c, kSize, nil);
}

/**
 This just crashes. It's supposed to look like the fiddle below, where the blue side is longer
 Fiddle: https://jsfiddle.net/62h401ce/1/
 */
- (void)testMinAndMaxWidthTakePriorityOverPreferredSize
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kLightGrayBackgroundView
   size:{.width=120}
   style:{
     .direction = CKStackLayoutDirectionHorizontal,
     .alignItems = CKStackLayoutAlignItemsStretch,
   }
   children:{
     {[CKComponent
       newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}}
       size:{
         .minWidth = 60,
         .height = 50
       }],
       .flexGrow = 1,
       .flexShrink = 0,
       .flexBasis = 0
     },
     {[CKComponent
       newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}}
       size:{
         .height = 50,
         .maxWidth = 20,
       }],
       .flexGrow = 1,
       .flexShrink = 0,
       .flexBasis = CKRelativeDimension::Percent(0.5)
     },
   }];
  
  static CKSizeRange kSize = {{0, 50}, {120, 50}};
  FBTakeSnapshotOfComponent(c, kSize, nil);
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
  FBTakeSnapshotOfComponent(c, kFixedWidth, nil);
}

- (void)testAlignContentStart
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal,
     .alignContent = CKStackLayoutAlignContentStart,
     .wrap = CKStackLayoutWrapWrap,
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{100,20}],
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,20}],
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{100,20}],
     },
   }];
  
  static CKSizeRange kFixedWidthAndHeight = {{100, 100}, {100, 100}};
  FBTakeSnapshotOfComponent(c, kFixedWidthAndHeight, nil);
}

- (void)testAlignContentEnd
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal,
     .alignContent = CKStackLayoutAlignContentEnd,
     .wrap = CKStackLayoutWrapWrap,
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{100,20}],
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,20}],
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{100,20}],
     },
   }];
  
  static CKSizeRange kFixedWidthAndHeight = {{100, 100}, {100, 100}};
  FBTakeSnapshotOfComponent(c, kFixedWidthAndHeight, nil);
}

- (void)testAlignContentCenter
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal,
     .alignContent = CKStackLayoutAlignContentCenter,
     .wrap = CKStackLayoutWrapWrap,
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{100,20}],
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,20}],
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{100,20}],
     },
   }];
  
  static CKSizeRange kFixedWidthAndHeight = {{100, 100}, {100, 100}};
  FBTakeSnapshotOfComponent(c, kFixedWidthAndHeight, nil);
}

- (void)testAlignContentSpaceBetween
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal,
     .alignContent = CKStackLayoutAlignContentSpaceBetween,
     .wrap = CKStackLayoutWrapWrap,
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{100,20}],
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,20}],
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{100,20}],
     },
   }];
  
  static CKSizeRange kFixedWidthAndHeight = {{100, 100}, {100, 100}};
  FBTakeSnapshotOfComponent(c, kFixedWidthAndHeight, nil);
}

- (void)testAlignContentSpaceAround
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal,
     .alignContent = CKStackLayoutAlignContentSpaceAround,
     .wrap = CKStackLayoutWrapWrap,
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{100,20}],
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,20}],
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{100,20}],
     },
   }];
  
  static CKSizeRange kFixedWidthAndHeight = {{100, 100}, {100, 100}};
  FBTakeSnapshotOfComponent(c, kFixedWidthAndHeight, nil);
}

- (void)testAlignContentStretch
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal,
     .alignContent = CKStackLayoutAlignContentStretch,
     .wrap = CKStackLayoutWrapWrap,
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{100,20}],
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,20}],
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{100,20}],
     },
   }];
  
  static CKSizeRange kFixedWidthAndHeight = {{100, 100}, {100, 100}};
  FBTakeSnapshotOfComponent(c, kFixedWidthAndHeight, nil);
}

- (void)testAlignBaseline
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:{
     [UIView class],
     {{@selector(setBackgroundColor:), [UIColor lightGrayColor]}},
   }
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal,
     .alignItems = CKStackLayoutAlignItemsBaseline,
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,100}],
       .flexShrink = 1,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}],
       .flexShrink = 1,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,75}],
       .flexShrink = 1,
     },
   }];
  
  static CKSizeRange kFixedWidthAndHeight = {{200, 200}, {200, 200}};
  FBTakeSnapshotOfComponent(c, kFixedWidthAndHeight, nil);
}

- (void)testCustomBaselineComponent
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:{
     [UIView class],
     {{@selector(setBackgroundColor:), [UIColor lightGrayColor]}},
   }
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal,
     .alignItems = CKStackLayoutAlignItemsBaseline,
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,100}],
       .flexShrink = 1,
     },
     {
       [CKCustomBaselineComponent
        newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}}
        size:{50,50}
        baseline:40],
       .flexShrink = 1,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,75}],
       .flexShrink = 1,
     },
   }];
  
  static CKSizeRange kFixedWidthAndHeight = {{200, 200}, {200, 200}};
  FBTakeSnapshotOfComponent(c, kFixedWidthAndHeight, nil);
}

- (void)testVariableBaselines
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:{
     [UIView class],
     {{@selector(setBackgroundColor:), [UIColor lightGrayColor]}},
   }
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal,
     .alignItems = CKStackLayoutAlignItemsBaseline,
   }
   children:{
     {
       [CKCustomBaselineComponent
        newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}}
        size:{50,50}
        baseline:30],
       .flexShrink = 1,
     },
     {
       [CKCustomBaselineComponent
        newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}}
        size:{50,50}
        baseline:40],
       .flexShrink = 1,
     },
     {
       [CKCustomBaselineComponent
        newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}}
        size:{50,50}
        baseline:10],
       .flexShrink = 1,
     },
   }];
  
  static CKSizeRange kFixedWidthAndHeight = {{200, 200}, {200, 200}};
  FBTakeSnapshotOfComponent(c, kFixedWidthAndHeight, nil);
}

- (void)testContainerPadding
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical,
     .padding = {
       .top = 20,
       .start = 30,
       .end = 10,
       .bottom = 5
     },
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{75,75}],
       .flexShrink = 1,
     },
   }];
  
  static CKSizeRange kSize = {{0, 0}, {300, INFINITY}};
  FBTakeSnapshotOfComponent(c, kSize, nil);
}

- (void)testChildPadding
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal,
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{.minWidth = 20, .minHeight = 20}],
       .padding = {
         .end = 10,
         .start = 20,
         .top = 15,
         .bottom = 20,
       },
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{.minWidth = 20, .minHeight = 20}],
     },
   }];
  
  static CKSizeRange kSize = {{200, 200}, {200, 200}};
  FBTakeSnapshotOfComponent(c, kSize, nil);
}

- (void)testPercentagePadding
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal,
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{.minWidth = 20, .minHeight = 20}],
       .padding = {
         .start = CKRelativeDimension::Percent(0.4),
         .end = CKRelativeDimension::Percent(0.2),
         .top = CKRelativeDimension::Percent(0.35),
         .bottom = CKRelativeDimension::Percent(0.4),
       },
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{.minWidth = 20, .minHeight = 20}],
     },
   }];
  
  static CKSizeRange kSize = {{200, 200}, {200, 200}};
  FBTakeSnapshotOfComponent(c, kSize, nil);
}

- (void)testUnspecifiedPaddingIsSameAsZero
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal,
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{.minWidth = 50, .minHeight = 50}],
       .padding = {},
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{.minWidth = 50, .minHeight = 50}],
       .padding = {
         .top = 10,
       },
     },
   }];
  
  static CKSizeRange kSize = {{200, 200}, {200, 200}};
  FBTakeSnapshotOfComponent(c, kSize, nil);
}

- (void)testStandardMargins
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical,
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{.minWidth = 10, .minHeight = 10}],
       .margin = {
         .top = 10,
         .start = 30,
         .end = 10,
         .bottom = 20,
       },
       .flexGrow = 1,
     },
   }];
  
  static CKSizeRange kSize = {{300, 300}, {300, 300}};
  FBTakeSnapshotOfComponent(c, kSize, nil);
}

- (void)testMultipleMargins
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal,
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{.minWidth = 10, .minHeight = 10}],
       .margin = {
         .top = 20,
         .start = 20,
         .end = 20,
         .bottom = 20,
       },
       .flexGrow = 1,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{.minWidth = 10, .minHeight = 10}],
       .margin = {
         .top = 30,
         .start = 30,
         .end = 30,
         .bottom = 30,
       },
       .flexGrow = 1,
     },
   }];
  
  static CKSizeRange kSize = {{300, 300}, {300, 300}};
  FBTakeSnapshotOfComponent(c, kSize, nil);
}

- (void)testMarginOverridesSpacing
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal,
     .spacing = 20,
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{.minWidth = 10, .minHeight = 10}],
       .margin = {
         .top = 20,
         .start = 20,
         .end = 0,
         .bottom = 20,
       },
       .flexGrow = 1,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{.minWidth = 10, .minHeight = 10}],
       .margin = {
         .top = 20,
         .start = 0,
         .end = 20,
         .bottom = 20,
       },
       .flexGrow = 1,
     },
   }];
  
  static CKSizeRange kSize = {{300, 300}, {300, 300}};
  FBTakeSnapshotOfComponent(c, kSize, nil);
}

- (void)testAlignSelfBaseline
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:{
     [UIView class],
     {{@selector(setBackgroundColor:), [UIColor lightGrayColor]}},
   }
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal,
     .alignItems = CKStackLayoutAlignItemsCenter,
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,100}],
       .flexShrink = 1,
     },
     {
       [CKCustomBaselineComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}],
       .flexShrink = 1,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,75}],
       .flexShrink = 1,
     },
   }];
  
  static CKSizeRange kFixedWidthAndHeight = {{200, 200}, {200, 200}};
  FBTakeSnapshotOfComponent(c, kFixedWidthAndHeight, nil);
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
  FBTakeSnapshotOfComponent(c, kFixedWidth, nil);
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
  FBTakeSnapshotOfComponent(c, kFixedWidth, nil);
}

- (void)testBasicAbsolutePositioning
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical,
   }
   children:{
     {
       [CKStackLayoutComponent
        newWithView:kWhiteBackgroundView
        size:{}
        style:{
          .direction = CKStackLayoutDirectionVertical
        }
        children:{
          {
            [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}],
          },
          {
            .position = {
              .type = CKStackLayoutPositionTypeAbsolute,
              .top = 20,
              .start = 30,
            },
            .component =
            [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}]
          }
        }]
     },
   }];
  
  static CKSizeRange kFixedWidthHeight = {{150, 100}, {150, 100}};
  FBTakeSnapshotOfComponent(c, kFixedWidthHeight, nil);
}

- (void)testPercentAbsolutePositioning
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical,
   }
   children:{
     {
       [CKStackLayoutComponent
        newWithView:{}
        size:{150,100}
        style:{
          .direction = CKStackLayoutDirectionVertical
        }
        children:{
          {
            [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}],
          },
          {
            .position = {
              .type = CKStackLayoutPositionTypeAbsolute,
              .top = CKRelativeDimension::Percent(0.2),
              .start = CKRelativeDimension::Percent(0.05),
            },
            .component =
            [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}]
          }
        }]
     },
   }];
  
  static CKSizeRange kFixedWidthHeight = {{150, 100}, {150, 100}};
  FBTakeSnapshotOfComponent(c, kFixedWidthHeight, nil);
}

- (void)testRightBottomAbsolutePositioning
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical,
   }
   children:{
     {
       [CKStackLayoutComponent
        newWithView:{}
        size:{150,100}
        style:{
          .direction = CKStackLayoutDirectionVertical
        }
        children:{
          {
            [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}],
          },
          {
            .position = {
              .type = CKStackLayoutPositionTypeAbsolute,
              .right = CKRelativeDimension::Percent(0.2),
              .bottom = CKRelativeDimension::Percent(0.2),
            },
            .component =
            [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}]
          }
        }]
     },
   }];
  
  static CKSizeRange kFixedWidthHeight = {{150, 100}, {150, 100}};
  FBTakeSnapshotOfComponent(c, kFixedWidthHeight, nil);
}

- (void)testAbsolutePositionsDontOverrideFixedDimensions
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical,
   }
   children:{
     {
       [CKStackLayoutComponent
        newWithView:{}
        size:{150,100}
        style:{
          .direction = CKStackLayoutDirectionVertical
        }
        children:{
          {
            [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}],
          },
          {
            .position = {
              .type = CKStackLayoutPositionTypeAbsolute,
              .left = 10,
              .right = 10,
            },
            .component =
            [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}]
          }
        }]
     },
   }];
  
  static CKSizeRange kFixedWidthHeight = {{150, 100}, {150, 100}};
  FBTakeSnapshotOfComponent(c, kFixedWidthHeight, nil);
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
  FBTakeSnapshotOfComponent(c, kExactSize, nil);
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
  FBTakeSnapshotOfComponent(c, kExactSize, nil);
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
  FBTakeSnapshotOfComponent(c, kExactSize, nil);
}

- (void)testAlignedStretchCrossSizing
{
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionVertical,
     .alignItems = CKStackLayoutAlignItemsStretch
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}}
                          size:{.width = CKRelativeDimension::Percent(1.0), .height = 50}]},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150, 150}], 20},
   }];
  static CKSizeRange kVariableSize = {{100, 100}, {200, 200}};
  
  // all children should be 200px wide
  FBTakeSnapshotOfComponent(c, kVariableSize, nil);
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
  FBTakeSnapshotOfComponent(c, kVariableSize, nil);
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
  FBTakeSnapshotOfComponent(c, kVariableSize, nil);
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
  FBTakeSnapshotOfComponent(c, kUnderflowSize, @"underflow");
  
  // width 200px; height 0-150px.
  static CKSizeRange kOverflowSize = {{200, 0}, {200, 150}};
  FBTakeSnapshotOfComponent(c, kOverflowSize, @"overflow");
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
  FBTakeSnapshotOfComponent(c, kSize, nil);
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
  FBTakeSnapshotOfComponent(c, kSize, nil);
}

- (void)testCrossAxisStretchingOccursAfterMainAxisFlexing
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
  FBTakeSnapshotOfComponent(c, kSize, nil);
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
  FBTakeSnapshotOfComponent(c, kSize, nil);
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
  FBTakeSnapshotOfComponent(c, kSize, nil);
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
  FBTakeSnapshotOfComponent(c, kSize, nil);
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
  FBTakeSnapshotOfComponent(c, kSize, nil);
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
  FBTakeSnapshotOfComponent(c, kSize, nil);
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
  FBTakeSnapshotOfComponent(c, kSize, nil);
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
  FBTakeSnapshotOfComponent(c, kSize, nil);
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
  FBTakeSnapshotOfComponent(c, kSize, nil);
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
  FBTakeSnapshotOfComponent(c, kSize, nil);
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
  FBTakeSnapshotOfComponent(c, kSize, nil);
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
  FBTakeSnapshotOfComponent(c, kSize, nil);
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
  FBTakeSnapshotOfComponent(c, kSize, nil);
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
  FBTakeSnapshotOfComponent(c, kSize, nil);
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
  FBTakeSnapshotOfComponent(c, kSize, nil);
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
  FBTakeSnapshotOfComponent(c, kSize, nil);
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
  FBTakeSnapshotOfComponent(c, kSize, nil);
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
  FBTakeSnapshotOfComponent(c, kSize, nil);
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
  FBTakeSnapshotOfComponent(c, kSize, nil);
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
  FBTakeSnapshotOfComponent(c, kSize, nil);
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
  FBTakeSnapshotOfComponent(c, kSize, nil);
}

- (void)testNestedLayoutStretchDoesNotViolateWidth
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
  FBTakeSnapshotOfComponent(c, kSize, nil);
}

# pragma mark - UI Docs

/**
 * @uidocs CKStackLayoutComponent
 * @uidocs_title Start alignment
 */
- (void)test_uidocs_alignedStart
{
  static CKSizeRange kSize = {{0,0}, {INFINITY, INFINITY}};
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
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), FIGColor(FIGCoreColors.blue)}}} size:{25,25}], 0},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), FIGColor(FIGCoreColors.blue)}}} size:{75,25}], 10},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), FIGColor(FIGCoreColors.blue)}}} size:{100,25}], 10},
   }];
  FBTakeSnapshotOfComponent(c, kSize, nil);
}

/**
 * @uidocs CKStackLayoutComponent
 * @uidocs_title Center alignment
 */
- (void)test_uidocs_alignedCenter
{
  static CKSizeRange kSize = {{0,0}, {INFINITY, INFINITY}};
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
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), FIGColor(FIGCoreColors.blue)}}} size:{25,25}], 0},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), FIGColor(FIGCoreColors.blue)}}} size:{75,25}], 10},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), FIGColor(FIGCoreColors.blue)}}} size:{100,25}], 10},
   }];
  FBTakeSnapshotOfComponent(c, kSize, nil);
}

/**
 * @uidocs CKStackLayoutComponent
 * @uidocs_title End alignment
 */
- (void)test_uidocs_alignedEnd
{
  static CKSizeRange kSize = {{0,0}, {INFINITY, INFINITY}};
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
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), FIGColor(FIGCoreColors.blue)}}} size:{25,25}], 0},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), FIGColor(FIGCoreColors.blue)}}} size:{75,25}], 10},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), FIGColor(FIGCoreColors.blue)}}} size:{100,25}], 10},
   }];
  FBTakeSnapshotOfComponent(c, kSize, nil);
}

- (void)testAspectRatioOneToOne {
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{10,5}],
       .aspectRatio = 1
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{25,5}],
       .aspectRatio = 1
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{40,5}],
       .aspectRatio = 1
     },
   }];
  
  static CKSizeRange kSize = {{75, 75}, {75, 75}};
  FBTakeSnapshotOfComponent(c, kSize, nil);
}

- (void)testAspectRatioTwoToOne {
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{10,5}],
       .aspectRatio = 2
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{25,5}],
       .aspectRatio = 2
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{40,5}],
       .aspectRatio = 2
     },
   }];
  
  static CKSizeRange kSize = {{75, 50}, {75, 50}};
  FBTakeSnapshotOfComponent(c, kSize, nil);
}

- (void)testAspectRatioOneToTwo {
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{10,5}],
       .aspectRatio = 0.5
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{25,5}],
       .aspectRatio = 0.5
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{40,5}],
       .aspectRatio = 0.5
     },
   }];
  
  static CKSizeRange kSize = {{75, 100}, {75, 100}};
  FBTakeSnapshotOfComponent(c, kSize, nil);
}

- (void)testNegativeAspectRatioOneToOne {
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{10,5}],
       .aspectRatio = -1
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{25,5}],
       .aspectRatio = -1
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{40,5}],
       .aspectRatio = -1
     },
   }];
  
  static CKSizeRange kSize = {{75, 75}, {75, 75}};
  FBTakeSnapshotOfComponent(c, kSize, nil);
}

- (void)testMinAspectRatio {
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{10,5}],
       .aspectRatio = FLT_EPSILON + FLT_MIN_EXP
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{25,5}],
       .aspectRatio = FLT_EPSILON + FLT_MIN_EXP
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{40,5}],
       .aspectRatio = FLT_EPSILON + FLT_MIN_EXP
     },
   }];
  
  static CKSizeRange kSize = {{75, 75}, {75, 75}};
  FBTakeSnapshotOfComponent(c, kSize, nil);
}

- (void)testDifferentAspectRatioPerChild {
  CKStackLayoutComponent *c =
  [CKStackLayoutComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKStackLayoutDirectionHorizontal
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{10,5}],
       .aspectRatio = 0.5
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{25,5}],
       .aspectRatio = 2
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{40,5}],
       .aspectRatio = 1
     },
   }];
  
  static CKSizeRange kSize = {{75, 75}, {75, 75}};
  FBTakeSnapshotOfComponent(c, kSize, nil);
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

@end
