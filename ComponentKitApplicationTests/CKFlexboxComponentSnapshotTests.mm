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
#import <ComponentKit/CKCompositeComponent.h>
#import <ComponentKit/CKFlexboxComponent.h>
#import <ComponentKit/CKInsetComponent.h>
#import <ComponentKit/CKRatioLayoutComponent.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentLayoutBaseline.h>
#import <ComponentKit/CKCompositeComponent.h>

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

@interface CKFlexboxComponent (Test)
+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view
                       size:(const CKComponentSize &)size
                      style:(const CKFlexboxComponentStyle &)style
                   children:(CKContainerWrapper<std::vector<CKFlexboxComponentChild>> &&)children
          usesDeepYogaTrees:(BOOL)usesDeepYogaTrees;
@end

static CKComponentViewConfiguration kWhiteBackgroundView = {
  [UIView class], {{@selector(setBackgroundColor:), [UIColor whiteColor]}}
};

static CKComponentViewConfiguration kLightGrayBackgroundView = {
  [UIView class], {{@selector(setBackgroundColor:), [UIColor lightGrayColor]}}
};

@interface CKFlexboxComponentSnapshotTests : CKComponentSnapshotTestCase

@property (nonatomic, assign) BOOL usesDeepYogaTrees;

@end

@implementation CKFlexboxComponentSnapshotTests

- (void)setUp
{
  [super setUp];
  self.recordMode = NO;
  _usesDeepYogaTrees = NO;
}

- (void)testUnderflowBehaviors
{
  // width 300px; height 0-300px
  static CKSizeRange kSize = {{300, 0}, {300, 300}};
  CKSnapshotVerifyComponent([self _layoutWithJustify:CKFlexboxJustifyContentStart flexFactor:0], kSize, @"justifyStart");
  CKSnapshotVerifyComponent([self _layoutWithJustify:CKFlexboxJustifyContentCenter flexFactor:0], kSize, @"justifyCenter");
  CKSnapshotVerifyComponent([self _layoutWithJustify:CKFlexboxJustifyContentEnd flexFactor:0], kSize, @"justifyEnd");
  CKSnapshotVerifyComponent([self _layoutWithJustify:CKFlexboxJustifyContentStart flexFactor:1], kSize, @"flex");
}

- (void)testOverflowBehaviors
{
  // width 110px; height 0-300px
  static CKSizeRange kSize = {{110, 0}, {110, 300}};
  CKSnapshotVerifyComponent([self _layoutWithJustify:CKFlexboxJustifyContentStart flexFactor:0], kSize, @"justifyStart");
  CKSnapshotVerifyComponent([self _layoutWithJustify:CKFlexboxJustifyContentCenter flexFactor:0], kSize, @"justifyCenter");
  CKSnapshotVerifyComponent([self _layoutWithJustify:CKFlexboxJustifyContentEnd flexFactor:0], kSize, @"justifyEnd");
  CKSnapshotVerifyComponent([self _layoutWithJustify:CKFlexboxJustifyContentStart flexFactor:1], kSize, @"flex");
}

- (void)testShrinkingBehaviourWithFullFlexGrow
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:{}
   size:{500,500}
   style:{
     .direction = CKFlexboxDirectionRow,
     .alignItems = CKFlexboxAlignItemsStart,
   }
   children: {
     {
       .component = [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{500, 500}],
       .flexGrow = 0, .flexShrink = 1,
     },
     {
       .component = [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{500, 500}],
       .flexGrow = 1, .flexShrink = 1,
     },
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  
  static CKSizeRange kSize = {{500, 500}, {500, 500}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testCorrectnessOfDeeplyNestedFlexboxHierarchies
{
  CKComponent *(^component)(UIColor *, const CKComponentSize &) = ^CKComponent *(UIColor *color, const CKComponentSize &size) {
    return [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), color}}} size:size];
  };
  CKFlexboxComponentChild(^leaf)(UIColor *, const CKComponentSize &) = ^CKFlexboxComponentChild (UIColor *color, const CKComponentSize &size) {
    return {
      .component = component(color, size),
      .position = {
        .type = CKFlexboxPositionTypeRelative,
      },
    };
  };
  BOOL usesDeepYogaTrees = _usesDeepYogaTrees;

  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:{}
   size:{500,500}
   style:{
     .direction = CKFlexboxDirectionRow,
     .alignItems = CKFlexboxAlignItemsStart,
     .padding = {
       .top = 10,
       .start = 10,
       .end = 10,
       .bottom = 10,
     },
   }
   children:{
     {
       .component =
       [CKCompositeComponent
        newWithComponent:
        [CKFlexboxComponent
         newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor lightGrayColor]}}}
         size:{NAN,NAN}
         style:{
           .direction = CKFlexboxDirectionRow,
           .alignItems = CKFlexboxAlignItemsStretch,
           .margin = {
             .top = 10,
             .start = 10,
             .end = 10,
             .bottom = 10,
           },
         }
         children:{
           {
             .component =
             [CKFlexboxComponent
              newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor brownColor]}}}
              size:{100,NAN}
              style:{
                .margin = {
                  .top = 5,
                  .bottom = 5,
                },
                .border = {
                  .top = 5,
                  .start = 5,
                  .end = 5,
                  .bottom = 5,
                },
              }
              children:{
                leaf([UIColor redColor], {100,100}),
                leaf([UIColor greenColor], {100,100}),
                leaf([UIColor blueColor], {100,100}),
                leaf([UIColor redColor], {100,100}),
              }
              usesDeepYogaTrees:usesDeepYogaTrees]
           },
           leaf([UIColor grayColor], {100,NAN}),
         }
         usesDeepYogaTrees:usesDeepYogaTrees]],
       .alignSelf = CKFlexboxAlignSelfStretch,
     },
     {
       .component =
       [CKFlexboxComponent
        newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor lightGrayColor]}}}
        size:{100,NAN}
        style:{
          .alignItems = CKFlexboxAlignItemsStretch,
          .padding = {
            .top = 10,
            .start = 10,
            .end = 10,
            .bottom = 10,
          },
        }
        children:{
          {
            .component =
            [CKFlexboxComponent
             newWithView:{}
             size:{NAN,100}
             style:{
               .direction = CKFlexboxDirectionRow,
               .alignItems = CKFlexboxAlignItemsStretch,
             }
             children:{
               {
                 .component = component([UIColor redColor], {NAN,NAN}),
                 .flexGrow = 0.2f,
                 .flexShrink = 1.0f,
                 .position = {
                   .type = CKFlexboxPositionTypeRelative,
                 },
               },
               {
                 .component = [CKCompositeComponent newWithComponent:component([UIColor blueColor], {NAN,NAN})],
                 .flexGrow = 0.2f,
                 .flexShrink = 1.0f,
                 .position = {
                   .type = CKFlexboxPositionTypeRelative,
                 },
               },
               {
                 .component = component([UIColor greenColor], {NAN,NAN}),
                 .flexGrow = 1.0f,
                 .flexShrink = 1.0f,
                 .position = {
                   .type = CKFlexboxPositionTypeRelative,
                 },
               },
             }
             usesDeepYogaTrees:usesDeepYogaTrees]
          },
          leaf([UIColor yellowColor], {NAN,50}),
          leaf([UIColor magentaColor], {NAN,50}),
          leaf([UIColor redColor], {NAN,50}),
          leaf([UIColor blueColor], {NAN,50}),
          leaf([UIColor greenColor], {NAN,50}),
        }
        usesDeepYogaTrees:usesDeepYogaTrees],
       .flexGrow = 1.0f,
       .flexShrink = 1.0f,
       .alignSelf = CKFlexboxAlignSelfStretch,
     },
     leaf([UIColor grayColor], {100,100}),
   }
   usesDeepYogaTrees:usesDeepYogaTrees];

  static CKSizeRange kSize = {{500, 500}, {500, 500}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testOverflowBehaviorsWhenAllFlexShrinkComponentsHaveBeenClampedToZeroButViolationStillExists
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow
   }
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  // Width is 75px--that's less than the sum of the widths of the child components, which is 100px.
  static CKSizeRange kSize = {{75, 0}, {75, 150}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testFlexWithUnequalIntrinsicSizes
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
   }
   children:{
     flexChild([CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}], 1),
     flexChild([CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{150,150}], 1),
     flexChild([CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}], 1),
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  // width 300px; height 0-150px.
  static CKSizeRange kUnderflowSize = {{300, 0}, {300, 150}};
  CKSnapshotVerifyComponent(c, kUnderflowSize, @"underflow");

  // width 200px; height 0-150px.
  static CKSizeRange kOverflowSize = {{200, 0}, {200, 150}};
  CKSnapshotVerifyComponent(c, kOverflowSize, @"overflow");
}

- (void)testCrossAxisSizeBehaviors
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}]},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,50}]},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,50}]},
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  // width 0-300px; height 300px
  static CKSizeRange kVariableHeight = {{0, 300}, {300, 300}};
  CKSnapshotVerifyComponent(c, kVariableHeight, @"variableHeight");

  // width 300px; height 300px
  static CKSizeRange kFixedHeight = {{300, 300}, {300, 300}};
  CKSnapshotVerifyComponent(c, kFixedHeight, @"fixedHeight");
}

- (void)testSpacing
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
     .spacing = 10,
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}]},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,50}]},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,50}]},
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  // width 0-300px; height 300px
  static CKSizeRange kVariableHeight = {{0, 300}, {300, 300}};
  CKSnapshotVerifyComponent(c, kVariableHeight, @"variableHeight");
}

- (void)testNegativeSpacing
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
     .spacing = -10,
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}]},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,50}]},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,50}]},
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  // width 0-300px; height 300px
  static CKSizeRange kVariableHeight = {{0, 300}, {300, 300}};
  CKSnapshotVerifyComponent(c, kVariableHeight, @"variableHeight");
}

- (void)testSpacingWithChildrenHavingNilComponents
{
  // This should take a zero height since all children have a nil component. If it takes a height > 0, a blue border
  // will show up, hence failing the test.

  static const CKComponentViewAttribute borderAttribute = {"CKFlexboxComponentTest.border", ^(UIView *view, id value) {
    view.layer.borderColor = [UIColor blueColor].CGColor;
    view.layer.borderWidth = 3.0f;
  }};

  CKComponent *c =
  [CKFlexboxComponent
   newWithView:{[UIView class], {{borderAttribute, nil}}}
   size:{}
   style:{
     .direction = CKFlexboxDirectionColumn,
     .spacing = 10,
     .alignItems = CKFlexboxAlignItemsStretch
   }
   children:{
     {nil},
     {nil},
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  // width 300px; height 0-300px
  static CKSizeRange kVariableHeight = {{300, 0}, {300, 300}};
  CKSnapshotVerifyComponentWithInsets(c, kVariableHeight, UIEdgeInsetsMake(10, 10, 10, 10), @"variableHeight");
}

- (void)testComponentSpacing
{
  // width 0-INF; height 0-INF
  static CKSizeRange kAnySize = {{0, 0}, {INFINITY, INFINITY}};

  CKFlexboxComponent *spacingBefore =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  CKSnapshotVerifyComponent(spacingBefore, kAnySize, @"spacingBefore");

  CKFlexboxComponent *spacingAfter =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  CKSnapshotVerifyComponent(spacingAfter, kAnySize, @"spacingAfter");

  CKFlexboxComponent *spacingBalancedOut =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  CKSnapshotVerifyComponent(spacingBalancedOut, kAnySize, @"spacingBalancedOut");
}

- (void)testHorizontalReverseSpacing
{
  // width 0-INF; height 0-INF
  static CKSizeRange kAnySize = {{0, 0}, {INFINITY, INFINITY}};

  CKFlexboxComponent *spacingBefore =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRowReverse,
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  CKSnapshotVerifyComponent(spacingBefore, kAnySize, @"spacingBefore");

  CKFlexboxComponent *spacingAfter =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRowReverse,
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  CKSnapshotVerifyComponent(spacingAfter, kAnySize, @"spacingAfter");

  CKFlexboxComponent *spacingBalancedOut =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRowReverse,
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  CKSnapshotVerifyComponent(spacingBalancedOut, kAnySize, @"spacingBalancedOut");
}

- (void)testVerticalReverseSpacing
{
  // width 0-INF; height 0-INF
  static CKSizeRange kAnySize = {{0, 0}, {INFINITY, INFINITY}};

  CKFlexboxComponent *spacingBefore =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumnReverse,
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  CKSnapshotVerifyComponent(spacingBefore, kAnySize, @"spacingBefore");

  CKFlexboxComponent *spacingAfter =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumnReverse,
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  CKSnapshotVerifyComponent(spacingAfter, kAnySize, @"spacingAfter");

  CKFlexboxComponent *spacingBalancedOut =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumnReverse,
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  CKSnapshotVerifyComponent(spacingBalancedOut, kAnySize, @"spacingBalancedOut");
}

- (void)testJustifiedCenterWithComponentSpacing
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
     .justifyContent = CKFlexboxJustifyContentCenter,
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}], 0},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,70}], 20},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,90}], 30},
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  // width 0-300px; height 300px
  static CKSizeRange kVariableHeight = {{0, 300}, {300, 300}};
  CKSnapshotVerifyComponent(c, kVariableHeight, @"variableHeight");
}

- (void)testZOrderNoChangeLayoutOrder
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
     .spacing = -10,
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}],
       .zIndex = 0},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,50}],
       .zIndex = 1},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,50}],
       .zIndex = 2},
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  // width 0-300px; height 300px
  static CKSizeRange kVariableHeight = {{0, 300}, {300, 300}};
  CKSnapshotVerifyComponent(c, kVariableHeight, @"variableHeight");
}

- (void)testZOrderPartialChangeLayoutOrder
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
     .spacing = -10,
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}],
       .zIndex = 0},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,50}],
       .zIndex = 1},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,50}],
       .zIndex = 0},
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  // width 0-300px; height 300px
  static CKSizeRange kVariableHeight = {{0, 300}, {300, 300}};
  CKSnapshotVerifyComponent(c, kVariableHeight, @"variableHeight");
}

- (void)testZOrderChangeLayoutOrder
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
     .spacing = -10,
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}],
       .zIndex = 2},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,50}],
       .zIndex = 1},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,50}],
       .zIndex = 0},
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  // width 0-300px; height 300px
  static CKSizeRange kVariableHeight = {{0, 300}, {300, 300}};
  CKSnapshotVerifyComponent(c, kVariableHeight, @"variableHeight");
}

/**
 The expected layout is [-------red------|---blue--], with no gray visible.
 The blue doesn't extend all the way.
 Fiddle: https://jsfiddle.net/g0kaahb7/1/
 */
- (void)testMinWidthIsRespected
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{.width=120}
   style:{
     .direction = CKFlexboxDirectionRow,
     .alignItems = CKFlexboxAlignItemsStretch,
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kSize = {{0, 50}, {120, 50}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

/**
 This just crashes. It's supposed to look like the fiddle below, where the blue side is longer
 Fiddle: https://jsfiddle.net/62h401ce/1/
 */
- (void)testMinAndMaxWidthTakePriorityOverPreferredSize
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{.width=120}
   style:{
     .direction = CKFlexboxDirectionRow,
     .alignItems = CKFlexboxAlignItemsStretch,
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kSize = {{0, 50}, {120, 50}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testComponentThatChangesCrossSizeWhenMainSizeIsFlexed
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kFixedWidth = {{150, 0}, {150, INFINITY}};
  CKSnapshotVerifyComponent(c, kFixedWidth, nil);
}

- (void)testAlignContentStart
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .alignContent = CKFlexboxAlignContentStart,
     .wrap = CKFlexboxWrapWrap,
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kFixedWidthAndHeight = {{100, 100}, {100, 100}};
  CKSnapshotVerifyComponent(c, kFixedWidthAndHeight, nil);
}

- (void)testAlignContentEnd
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .alignContent = CKFlexboxAlignContentEnd,
     .wrap = CKFlexboxWrapWrap,
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kFixedWidthAndHeight = {{100, 100}, {100, 100}};
  CKSnapshotVerifyComponent(c, kFixedWidthAndHeight, nil);
}

- (void)testAlignContentCenter
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .alignContent = CKFlexboxAlignContentCenter,
     .wrap = CKFlexboxWrapWrap,
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kFixedWidthAndHeight = {{100, 100}, {100, 100}};
  CKSnapshotVerifyComponent(c, kFixedWidthAndHeight, nil);
}

- (void)testAlignContentSpaceBetween
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .alignContent = CKFlexboxAlignContentSpaceBetween,
     .wrap = CKFlexboxWrapWrap,
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kFixedWidthAndHeight = {{100, 100}, {100, 100}};
  CKSnapshotVerifyComponent(c, kFixedWidthAndHeight, nil);
}

- (void)testAlignContentSpaceAround
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .alignContent = CKFlexboxAlignContentSpaceAround,
     .wrap = CKFlexboxWrapWrap,
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kFixedWidthAndHeight = {{100, 100}, {100, 100}};
  CKSnapshotVerifyComponent(c, kFixedWidthAndHeight, nil);
}

- (void)testAlignContentStretch
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .alignContent = CKFlexboxAlignContentStretch,
     .wrap = CKFlexboxWrapWrap,
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kFixedWidthAndHeight = {{100, 100}, {100, 100}};
  CKSnapshotVerifyComponent(c, kFixedWidthAndHeight, nil);
}

- (void)testAlignBaseline
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:{
     [UIView class],
     {{@selector(setBackgroundColor:), [UIColor lightGrayColor]}},
   }
   size:{}
   style:{
     .direction = CKFlexboxDirectionRow,
     .alignItems = CKFlexboxAlignItemsBaseline,
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kFixedWidthAndHeight = {{200, 200}, {200, 200}};
  CKSnapshotVerifyComponent(c, kFixedWidthAndHeight, nil);
}

- (void)testCustomBaselineComponent
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:{
     [UIView class],
     {{@selector(setBackgroundColor:), [UIColor lightGrayColor]}},
   }
   size:{}
   style:{
     .direction = CKFlexboxDirectionRow,
     .alignItems = CKFlexboxAlignItemsBaseline,
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kFixedWidthAndHeight = {{200, 200}, {200, 200}};
  CKSnapshotVerifyComponent(c, kFixedWidthAndHeight, nil);
}

- (void)testVariableBaselines
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:{
     [UIView class],
     {{@selector(setBackgroundColor:), [UIColor lightGrayColor]}},
   }
   size:{}
   style:{
     .direction = CKFlexboxDirectionRow,
     .alignItems = CKFlexboxAlignItemsBaseline,
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kFixedWidthAndHeight = {{200, 200}, {200, 200}};
  CKSnapshotVerifyComponent(c, kFixedWidthAndHeight, nil);
}

- (void)testContainerPadding
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kSize = {{0, 0}, {300, INFINITY}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testChildPadding
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kSize = {{200, 200}, {200, 200}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testPercentagePadding
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kSize = {{200, 200}, {200, 200}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testUnspecifiedPaddingIsSameAsZero
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kSize = {{200, 200}, {200, 200}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testStandardMargins
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kSize = {{300, 300}, {300, 300}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testMultipleMargins
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kSize = {{300, 300}, {300, 300}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testMarginOverridesSpacing
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kSize = {{300, 300}, {300, 300}};
  @try {
    CKSnapshotVerifyComponent(c, kSize, nil);
  } @catch (NSException *exception) {
  }
}

- (void)testAlignSelfBaseline
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:{
     [UIView class],
     {{@selector(setBackgroundColor:), [UIColor lightGrayColor]}},
   }
   size:{}
   style:{
     .direction = CKFlexboxDirectionRow,
     .alignItems = CKFlexboxAlignItemsCenter,
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kFixedWidthAndHeight = {{200, 200}, {200, 200}};
  CKSnapshotVerifyComponent(c, kFixedWidthAndHeight, nil);
}

- (void)testAlignCenterWithFlexedMainDimension
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKFlexboxDirectionColumn,
     .alignItems = CKFlexboxAlignItemsCenter,
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kFixedWidth = {{150, 0}, {150, 100}};
  CKSnapshotVerifyComponent(c, kFixedWidth, nil);
}

- (void)testAlignCenterWithIndefiniteCrossDimension
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{100,100}]
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}],
       .alignSelf = CKFlexboxAlignSelfCenter,
     },
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kFixedWidth = {{150, 0}, {150, INFINITY}};
  CKSnapshotVerifyComponent(c, kFixedWidth, nil);
}

- (void)testBasicAbsolutePositioning
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
   }
   children:{
     {
       [CKFlexboxComponent
        newWithView:kWhiteBackgroundView
        size:{}
        style:{
          .alignItems = CKFlexboxAlignItemsStart,
          .direction = CKFlexboxDirectionColumn
        }
        children:{
          {
            [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}],
          },
          {
            .position = {
              .type = CKFlexboxPositionTypeAbsolute,
              .top = 20,
              .start = 30,
            },
            .component =
            [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}]
          }
        }
        usesDeepYogaTrees:_usesDeepYogaTrees]
     },
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kFixedWidthHeight = {{150, 100}, {150, 100}};
  CKSnapshotVerifyComponent(c, kFixedWidthHeight, nil);
}

- (void)testPercentAbsolutePositioning
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
   }
   children:{
     {
       [CKFlexboxComponent
        newWithView:{}
        size:{150,100}
        style:{
          .alignItems = CKFlexboxAlignItemsStart,
          .direction = CKFlexboxDirectionColumn
        }
        children:{
          {
            [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}],
          },
          {
            .position = {
              .type = CKFlexboxPositionTypeAbsolute,
              .top = CKRelativeDimension::Percent(0.2),
              .start = CKRelativeDimension::Percent(0.05),
            },
            .component =
            [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}]
          }
        }
        usesDeepYogaTrees:_usesDeepYogaTrees]
     },
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kFixedWidthHeight = {{150, 100}, {150, 100}};
  CKSnapshotVerifyComponent(c, kFixedWidthHeight, nil);
}

- (void)testRightBottomAbsolutePositioning
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
   }
   children:{
     {
       [CKFlexboxComponent
        newWithView:{}
        size:{150,100}
        style:{
          .alignItems = CKFlexboxAlignItemsStart,
          .direction = CKFlexboxDirectionColumn
        }
        children:{
          {
            [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}],
          },
          {
            .position = {
              .type = CKFlexboxPositionTypeAbsolute,
              .right = CKRelativeDimension::Percent(0.2),
              .bottom = CKRelativeDimension::Percent(0.2),
            },
            .component =
            [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}]
          }
        }
        usesDeepYogaTrees:_usesDeepYogaTrees]
     },
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kFixedWidthHeight = {{150, 100}, {150, 100}};
  CKSnapshotVerifyComponent(c, kFixedWidthHeight, nil);
}

- (void)testAbsolutePositionsDontOverrideFixedDimensions
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
   }
   children:{
     {
       [CKFlexboxComponent
        newWithView:{}
        size:{150,100}
        style:{
          .alignItems = CKFlexboxAlignItemsStart,
          .direction = CKFlexboxDirectionColumn
        }
        children:{
          {
            [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}],
          },
          {
            .position = {
              .type = CKFlexboxPositionTypeAbsolute,
              .left = 10,
              .right = 10,
            },
            .component =
            [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}]
          }
        }
        usesDeepYogaTrees:_usesDeepYogaTrees]
     },
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kFixedWidthHeight = {{150, 100}, {150, 100}};
  CKSnapshotVerifyComponent(c, kFixedWidthHeight, nil);
}

- (void)testAlignedStart
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKFlexboxDirectionColumn,
     .justifyContent = CKFlexboxJustifyContentCenter,
     .alignItems = CKFlexboxAlignItemsStart
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}], 0},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,70}], 20},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,90}], 30},
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  static CKSizeRange kExactSize = {{300, 300}, {300, 300}};
  CKSnapshotVerifyComponent(c, kExactSize, nil);
}

- (void)testAlignedEnd
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKFlexboxDirectionColumn,
     .justifyContent = CKFlexboxJustifyContentCenter,
     .alignItems = CKFlexboxAlignItemsEnd
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}], 0},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,70}], 20},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,90}], 30},
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  static CKSizeRange kExactSize = {{300, 300}, {300, 300}};
  CKSnapshotVerifyComponent(c, kExactSize, nil);
}

- (void)testAlignedCenter
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKFlexboxDirectionColumn,
     .justifyContent = CKFlexboxJustifyContentCenter,
     .alignItems = CKFlexboxAlignItemsCenter
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}], 0},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,70}], 20},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,90}], 30},
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  static CKSizeRange kExactSize = {{300, 300}, {300, 300}};
  CKSnapshotVerifyComponent(c, kExactSize, nil);
}

- (void)testAlignedStretchCrossSizing
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKFlexboxDirectionColumn,
     .alignItems = CKFlexboxAlignItemsStretch
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}}
                          size:{.width = CKRelativeDimension::Percent(1.0), .height = 50}]},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150, 150}], 20},
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  static CKSizeRange kVariableSize = {{100, 100}, {200, 200}};

  // all children should be 200px wide
  CKSnapshotVerifyComponent(c, kVariableSize, nil);
}

- (void)testAlignedStretchNoChildExceedsMin
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKFlexboxDirectionColumn,
     .justifyContent = CKFlexboxJustifyContentCenter,
     .alignItems = CKFlexboxAlignItemsStretch
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}], 0},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,70}], 20},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,90}], 30},
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  static CKSizeRange kVariableSize = {{200, 200}, {300, 300}};

  // all children should be 200px wide
  CKSnapshotVerifyComponent(c, kVariableSize, nil);
}

- (void)testAlignedStretchOneChildExceedsMin
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKFlexboxDirectionColumn,
     .justifyContent = CKFlexboxJustifyContentCenter,
     .alignItems = CKFlexboxAlignItemsStretch
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}], 0},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,70}], 20},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,90}], 30},
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  static CKSizeRange kVariableSize = {{50, 50}, {300, 300}};

  // all children should be 150px wide
  CKSnapshotVerifyComponent(c, kVariableSize, nil);
}

- (void)testFixedFlexBasisAppliedWhenFlexingItems
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow
   }
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  // width 300px; height 0-150px.
  static CKSizeRange kUnderflowSize = {{300, 0}, {300, 150}};
  CKSnapshotVerifyComponent(c, kUnderflowSize, @"underflow");

  // width 200px; height 0-150px.
  static CKSizeRange kOverflowSize = {{200, 0}, {200, 150}};
  CKSnapshotVerifyComponent(c, kOverflowSize, @"overflow");
}

- (void)testPercentageFlexBasisResolvesAgainstParentSize
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow
   }
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kSize = {{200, 0}, {200, INFINITY}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testFixedFlexBasisOverridesIntrinsicSizeForNonFlexingChildren
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow
   }
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kSize = {{300, 0}, {300, 150}};
  CKSnapshotVerifyComponent(c, kSize, nil);
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
   [CKFlexboxComponent
    newWithView:{}
    size:{}
    style:{
      .direction = CKFlexboxDirectionRow,
      .alignItems = CKFlexboxAlignItemsStretch,
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
    }
    usesDeepYogaTrees:_usesDeepYogaTrees]];

  static CKSizeRange kSize = {{300, 0}, {300, INFINITY}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testPositiveViolationIsDistributedEqually
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  // In this scenario a width of 350 results in a positive violation of 200.
  // Due to each flexible child component specifying a flex grow factor of 1 the violation will be distributed evenly.
  static CKSizeRange kSize = {{350, 350}, {350, 350}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testPositiveViolationIsDistributedEquallyWithArbitraryFloats
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  // In this scenario a width of 350 results in a positive violation of 200.
  // Due to each flexible child component specifying a flex grow factor of 0.5 the violation will be distributed evenly.
  static CKSizeRange kSize = {{350, 350}, {350, 350}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testPositiveViolationIsDistributedProportionally
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  // In this scenario a width of 350 results in a positive violation of 200.
  // The first and third child components specify a flex grow factor of 1 and will flex by 50.
  // The second child component specifies a flex grow factor of 2 and will flex by 100.
  static CKSizeRange kSize = {{350, 350}, {350, 350}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testPositiveViolationIsDistributedProportionallyWithArbitraryFloats
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  // In this scenario a width of 350 results in a positive violation of 200.
  // The first and third child components specify a flex grow factor of 0.25 and will flex by 50.
  // The second child component specifies a flex grow factor of 0.25 and will flex by 100.
  static CKSizeRange kSize = {{350, 350}, {350, 350}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testPositiveViolationIsDistributedEquallyAmongMixedChildren
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  // In this scenario a width of 400 results in a positive violation of 200.
  // The first and third child components specify a flex shrink factor of 1 and 0, respectively. They won't flex.
  // The second and fourth child components specify a flex grow factor of 1 and will flex by 100.
  static CKSizeRange kSize = {{400, 400}, {400, 400}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testPositiveViolationIsDistributedEquallyAmongMixedChildrenWithArbitraryFloats
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  // In this scenario a width of 400 results in a positive violation of 200.
  // The first and third child components specify a flex shrink factor of 1 and 0, respectively. They won't flex.
  // The second and fourth child components specify a flex grow factor of 0.5 and will flex by 100.
  static CKSizeRange kSize = {{400, 400}, {400, 400}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testPositiveViolationIsDistributedProportionallyAmongMixedChildren
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  // In this scenario a width of 400 results in a positive violation of 200.
  // The first and third child components specify a flex shrink factor of 1 and 0, respectively. They won't flex.
  // The second child component specifies a flex grow factor of 3 and will flex by 150.
  // The fourth child component specifies a flex grow factor of 1 and will flex by 50.
  static CKSizeRange kSize = {{400, 400}, {400, 400}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testPositiveViolationIsDistributedProportionallyAmongMixedChildrenWithArbitraryFloats
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  // In this scenario a width of 400 results in a positive violation of 200.
  // The first and third child components specify a flex shrink factor of 1 and 0, respectively. They won't flex.
  // The second child component specifies a flex grow factor of 0.75 and will flex by 150.
  // The fourth child component specifies a flex grow factor of 0.25 and will flex by 50.
  static CKSizeRange kSize = {{400, 400}, {400, 400}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testRemainingViolationIsAppliedProperlyToFirstFlexibleChild
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  static CKSizeRange kSize = {{300, 300}, {300, 300}};
  // In this scenario a width of 300 results in a positive violation of 175.
  // The second and third child components specify a flex grow factor of 1 and will flex by 88 and 87, respectively.
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testRemainingViolationIsAppliedProperlyToFirstFlexibleChildWithArbitraryFloats
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  static CKSizeRange kSize = {{300, 300}, {300, 300}};
  // In this scenario a width of 300 results in a positive violation of 175.
  // The second and third child components specify a flex grow factor of 0.5 and will flex by 88 and 87, respectively.
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testNegativeViolationIsDistributedBasedOnSize
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  // In this scenario a width of 400 results in a negative violation of 200.
  // The first and third child components specify a flex shrink factor of 1 and will flex by -120 and -80, respectively.
  static CKSizeRange kSize = {{400, 400}, {400, 400}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testNegativeViolationIsDistributedBasedOnSizeWithArbitraryFloats
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  // In this scenario a width of 400 results in a negative violation of 200.
  // The first and third child components specify a flex shrink factor of 0.5 and will flex by -120 and -80, respectively.
  static CKSizeRange kSize = {{400, 400}, {400, 400}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testNegativeViolationIsDistributedBasedOnSizeAndFlexFactor
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  // In this scenario a width of 400 results in a negative violation of 200.
  // The first and third child components specify a flex shrink factor of 2 and will flex by -109 and -72, respectively.
  // The second child component specifies a flex shrink factor of 1 and will flex by -18.
  static CKSizeRange kSize = {{400, 400}, {400, 400}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testNegativeViolationIsDistributedBasedOnSizeAndFlexFactorWithArbitraryFloats
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  // In this scenario a width of 400 results in a negative violation of 200.
  // The first and third child components specify a flex shrink factor of 0.4 and will flex by -109 and -72, respectively.
  // The second child component specifies a flex shrink factor of 0.2 and will flex by -18.
  static CKSizeRange kSize = {{400, 400}, {400, 400}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testNegativeViolationIsDistributedBasedOnSizeAmongMixedChildrenChildren
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  // In this scenario a width of 400 results in a negative violation of 200.
  // The first and third child components specify a flex grow factor of 1 and 0, respectively. They won't flex.
  // The second and fourth child components specify a flex shrink factor of 1 and will flex by -100.
  static CKSizeRange kSize = {{400, 400}, {400, 400}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testNegativeViolationIsDistributedBasedOnSizeAmongMixedChildrenWithArbitraryFloats
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  // In this scenario a width of 400 results in a negative violation of 200.
  // The first and third child components specify a flex grow factor of 1 and 0, respectively. They won't flex.
  // The second and fourth child components specify a flex shrink factor of 0.5 and will flex by -100.
  static CKSizeRange kSize = {{400, 400}, {400, 400}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testNegativeViolationIsDistributedBasedOnSizeAndFlexFactorAmongMixedChildren
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  // In this scenario a width of 400 results in a negative violation of 200.
  // The first and third child components specify a flex grow factor of 1 and 0, respectively. They won't flex.
  // The second child component specifies a flex shrink factor of 1 and will flex by -28.
  // The fourth child component specifies a flex shrink factor of 3 and will flex by -171.
  static CKSizeRange kSize = {{400, 400}, {400, 400}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testNegativeViolationIsDistributedBasedOnSizeAndFlexFactorAmongMixedChildrenArbitraryFloats
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  // In this scenario a width of 400 results in a negative violation of 200.
  // The first and third child components specify a flex grow factor of 1 and 0, respectively. They won't flex.
  // The second child component specifies a flex shrink factor of 0.25 and will flex by -28.
  // The fourth child component specifies a flex shrink factor of 0.75 and will flex by -171.
  static CKSizeRange kSize = {{400, 400}, {400, 400}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testNegativeViolationIsDistributedBasedOnSizeAndFlexFactorDoesNotShrinkToZero
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  // In this scenario a width of 400 results in a negative violation of 200.
  // The first and third child components specify a flex shrink factor of 1 and will flex by 50.
  // The second child component specifies a flex shrink factor of 2 and will flex by -57. It will have a width of 43.
  static CKSizeRange kSize = {{400, 400}, {400, 400}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testNegativeViolationIsDistributedBasedOnSizeAndFlexFactorDoesNotShrinkToZeroWithArbitraryFloats
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  // In this scenario a width of 400 results in a negative violation of 200.
  // The first and third child components specify a flex shrink factor of 0.25 and will flex by 50.
  // The second child component specifies a flex shrink factor of 0.50 and will flex by -57. It will have a width of 43.
  static CKSizeRange kSize = {{400, 400}, {400, 400}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testNestedLayoutStretchDoesNotViolateWidth
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
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
     .direction = CKFlexboxDirectionColumn,
     .alignItems = CKFlexboxAlignItemsStretch
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  static CKSizeRange kSize = {{0, 0}, {300, INFINITY}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testSimultaneousFlexGrowAndAlignStretch
{
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{.height = 100}
   style:{
     .direction = CKFlexboxDirectionRow,
     // This should make each child stretch to the full height of 100pts:
     .alignItems = CKFlexboxAlignItemsStretch,
   }
   children:{
     {
       // CKCompositeComponent is used just to verify that CKFlexboxComponent is actually
       // laying out each child at the correct size, not just setting CKComponentLayout.size.
       [CKCompositeComponent
        newWithComponent:
        [CKComponent
         newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}}
         size:{}]],
       .flexGrow = 1,
     },
     {
       [CKCompositeComponent
        newWithComponent:
        [CKComponent
         newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}}
         size:{}]],
       .flexGrow = 1,
     },
     {
       [CKCompositeComponent
        newWithComponent:
        [CKComponent
         newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}}
         size:{}]],
       .flexGrow = 1,
     },
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  static CKSizeRange kSize = {{400, 0}, {400, INFINITY}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

# pragma mark - UI Docs

/**
 * @uidocs CKFlexboxComponent
 * @uidocs_title Start alignment
 */
- (void)test_uidocs_alignedStart
{
  static CKSizeRange kSize = {{0,0}, {INFINITY, INFINITY}};
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKFlexboxDirectionColumn,
     .justifyContent = CKFlexboxJustifyContentCenter,
     .alignItems = CKFlexboxAlignItemsStart
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{25,25}], 0},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{75,25}], 10},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,25}], 10},
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  CKSnapshotVerifyComponent(c, kSize, nil);
}

/**
 * @uidocs CKFlexboxComponent
 * @uidocs_title Center alignment
 */
- (void)test_uidocs_alignedCenter
{
  static CKSizeRange kSize = {{0,0}, {INFINITY, INFINITY}};
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKFlexboxDirectionColumn,
     .justifyContent = CKFlexboxJustifyContentCenter,
     .alignItems = CKFlexboxAlignItemsCenter
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{25,25}], 0},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{75,25}], 10},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,25}], 10},
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  CKSnapshotVerifyComponent(c, kSize, nil);
}

/**
 * @uidocs CKFlexboxComponent
 * @uidocs_title End alignment
 */
- (void)test_uidocs_alignedEnd
{
  static CKSizeRange kSize = {{0,0}, {INFINITY, INFINITY}};
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKFlexboxDirectionColumn,
     .justifyContent = CKFlexboxJustifyContentCenter,
     .alignItems = CKFlexboxAlignItemsEnd
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{25,25}], 0},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{75,25}], 10},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,25}], 10},
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testAspectRatioOneToOne {
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kSize = {{75, 75}, {75, 75}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testAspectRatioTwoToOne {
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kSize = {{75, 50}, {75, 50}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testAspectRatioOneToTwo {
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kSize = {{75, 100}, {75, 100}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testNegativeAspectRatioOneToOne {
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kSize = {{75, 75}, {75, 75}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testMinAspectRatio {
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kSize = {{75, 75}, {75, 75}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testDifferentAspectRatioPerChild {
  CKFlexboxComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow
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
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];

  static CKSizeRange kSize = {{75, 75}, {75, 75}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

static CKFlexboxComponentChild flexChild(CKComponent *c, CGFloat flexFactor)
{
  return {c, .flexGrow = flexFactor, .flexShrink = flexFactor};
}

- (CKFlexboxComponent *)_layoutWithJustify:(CKFlexboxJustifyContent)justify flexFactor:(NSInteger)flexFactor
{
  return
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .justifyContent = justify,
   }
   children:{
     flexChild([CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}], flexFactor),
     flexChild([CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}], flexFactor),
     flexChild([CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}], flexFactor),
   }
   usesDeepYogaTrees:_usesDeepYogaTrees];
}

@end

@interface CKFlexboxComponentWithDeepYogaTreeSnapshotTests : CKFlexboxComponentSnapshotTests
@end

@implementation CKFlexboxComponentWithDeepYogaTreeSnapshotTests

- (void)setUp
{
  [super setUp];
  self.usesDeepYogaTrees = YES;
}

@end
