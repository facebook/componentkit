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

- (RCLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
{
  RCLayout parentLayout = [super computeLayoutThatFits:constrainedSize];
  NSMutableDictionary *extra = parentLayout.extra ? [parentLayout.extra mutableCopy]: [NSMutableDictionary dictionary];
  extra[kCKComponentLayoutExtraBaselineKey] = @(_baseline);
  parentLayout.extra = extra;
  return parentLayout;
}

- (BOOL)usesCustomBaseline
{
  return YES;
}

@end

static CKComponentViewConfiguration kWhiteBackgroundView = {
  [UIView class], {{@selector(setBackgroundColor:), [UIColor whiteColor]}}
};

static CKComponentViewConfiguration kLightGrayBackgroundView = {
  [UIView class], {{@selector(setBackgroundColor:), [UIColor lightGrayColor]}}
};

@interface CKFlexboxComponentSnapshotTests : CKComponentSnapshotTestCase

@property (nonatomic, assign) BOOL useDeepYogaTrees;

@end

@implementation CKFlexboxComponentSnapshotTests

- (void)setUp
{
  [super setUp];
  self.recordMode = NO;
  _useDeepYogaTrees = NO;
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
  auto const c = CK::FlexboxComponentBuilder()
  .width(500)
  .height(500)
  .direction(CKFlexboxDirectionRow)
  .alignItems(CKFlexboxAlignItemsStart)
  .useDeepYogaTrees(_useDeepYogaTrees)
  .child(CK::ComponentBuilder()
          .viewClass([UIView class])
          .backgroundColor([UIColor greenColor])
          .width(500)
          .height(500)
          .build())
          .flexGrow(0)
          .flexShrink(1)
  .child(CK::ComponentBuilder()
          .viewClass([UIView class])
          .backgroundColor([UIColor redColor])
          .width(500)
          .height(500)
          .build())
          .flexGrow(1)
          .flexShrink(1)
  .build();

  static CKSizeRange kSize = {{500, 500}, {500, 500}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testCorrectnessOfDeeplyNestedFlexboxHierarchies
{
  CKComponent *(^component)(UIColor *, const CKComponentSize &) = ^CKComponent *(UIColor *color, const CKComponentSize &size) {
    return CK::ComponentBuilder()
            .viewClass([UIView class])
            .backgroundColor(color)
            .size(size)
            .build();
  };
  CKFlexboxComponentChild(^leaf)(UIColor *, const CKComponentSize &) = ^CKFlexboxComponentChild (UIColor *color, const CKComponentSize &size) {
    return {
      .component = component(color, size),
      .position = {
        .type = CKFlexboxPositionTypeRelative,
      },
    };
  };
  BOOL useDeepYogaTrees = _useDeepYogaTrees;

  CKComponent *c =
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
     .useDeepYogaTrees = useDeepYogaTrees,
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
           .useDeepYogaTrees = useDeepYogaTrees,
         }
         children:{
           {
             .component =
             [CKFlexboxComponent
              newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor brownColor]}}}
              size:{100,NAN}
              style:{
                .border = {
                  .top = 5,
                  .start = 5,
                  .end = 5,
                  .bottom = 5,
                },
                .useDeepYogaTrees = useDeepYogaTrees,
              }
              children:{
                leaf([UIColor redColor], {100,100}),
                leaf([UIColor greenColor], {100,100}),
                leaf([UIColor blueColor], {100,100}),
                leaf([UIColor redColor], {100,100}),
              }]
           },
           leaf([UIColor grayColor], {100,NAN}),
         }]],
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
          .useDeepYogaTrees = useDeepYogaTrees,
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
               .useDeepYogaTrees = useDeepYogaTrees,
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
             }]
          },
          leaf([UIColor yellowColor], {NAN,50}),
          leaf([UIColor magentaColor], {NAN,50}),
          leaf([UIColor redColor], {NAN,50}),
          leaf([UIColor blueColor], {NAN,50}),
          leaf([UIColor greenColor], {NAN,50}),
        }],
       .flexGrow = 1.0f,
       .flexShrink = 1.0f,
       .alignSelf = CKFlexboxAlignSelfStretch,
     },
     leaf([UIColor grayColor], {100,100}),
   }];

  static CKSizeRange kSize = {{500, 500}, {500, 500}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testOverflowBehaviorsWhenAllFlexShrinkComponentsHaveBeenClampedToZeroButViolationStillExists
{
  auto const c = CK::FlexboxComponentBuilder()
  .viewClass([UIView class])
  .backgroundColor([UIColor whiteColor])
  .alignItems(CKFlexboxAlignItemsStart)
  .direction(CKFlexboxDirectionRow)
  .useDeepYogaTrees(_useDeepYogaTrees)
  .child(CK::ComponentBuilder()
          .viewClass([UIView class])
          .backgroundColor([UIColor redColor])
          .width(50)
          .height(50)
          .build())
          .flexShrink(0)
  .child(CK::ComponentBuilder()
          .viewClass([UIView class])
          .backgroundColor([UIColor blueColor])
          .width(50)
          .height(50)
          .build())
          .flexShrink(1)
  .child(CK::ComponentBuilder()
          .viewClass([UIView class])
          .backgroundColor([UIColor greenColor])
          .width(50)
          .height(50)
          .build())
          .flexShrink(0)
  .build();

  // Width is 75px--that's less than the sum of the widths of the child components, which is 100px.
  static CKSizeRange kSize = {{75, 0}, {75, 150}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testFlexWithUnequalIntrinsicSizes
{
  auto const c = CK::FlexboxComponentBuilder()
  .viewClass([UIView class])
  .backgroundColor([UIColor whiteColor])
  .alignItems(CKFlexboxAlignItemsStart)
  .direction(CKFlexboxDirectionRow)
  .useDeepYogaTrees(_useDeepYogaTrees)
  .child(CK::ComponentBuilder()
          .viewClass([UIView class])
          .backgroundColor([UIColor redColor])
          .width(50)
          .height(50)
          .build())
          .flexShrink(1)
          .flexGrow(1)
  .child(CK::ComponentBuilder()
          .viewClass([UIView class])
          .backgroundColor([UIColor blueColor])
          .width(150)
          .height(150)
          .build())
          .flexShrink(1)
          .flexGrow(1)
  .child(CK::ComponentBuilder()
          .viewClass([UIView class])
          .backgroundColor([UIColor greenColor])
          .width(50)
          .height(50)
          .build())
          .flexShrink(1)
          .flexGrow(1)
  .build();

  // width 300px; height 0-150px.
  static CKSizeRange kUnderflowSize = {{300, 0}, {300, 150}};
  CKSnapshotVerifyComponent(c, kUnderflowSize, @"underflow");

  // width 200px; height 0-150px.
  static CKSizeRange kOverflowSize = {{200, 0}, {200, 150}};
  CKSnapshotVerifyComponent(c, kOverflowSize, @"overflow");
}

- (void)testCrossAxisSizeBehaviors
{
  auto const c = CK::FlexboxComponentBuilder()
  .viewClass([UIView class])
  .backgroundColor([UIColor whiteColor])
  .alignItems(CKFlexboxAlignItemsStart)
  .direction(CKFlexboxDirectionColumn)
  .useDeepYogaTrees(_useDeepYogaTrees)
  .child(CK::ComponentBuilder()
          .viewClass([UIView class])
          .backgroundColor([UIColor redColor])
          .width(50)
          .height(50)
          .build())
  .child(CK::ComponentBuilder()
          .viewClass([UIView class])
          .backgroundColor([UIColor blueColor])
          .width(100)
          .height(50)
          .build())
  .child(CK::ComponentBuilder()
          .viewClass([UIView class])
          .backgroundColor([UIColor greenColor])
          .width(150)
          .height(50)
          .build())
  .build();

  // width 0-300px; height 300px
  static CKSizeRange kVariableHeight = {{0, 300}, {300, 300}};
  CKSnapshotVerifyComponent(c, kVariableHeight, @"variableHeight");

  // width 300px; height 300px
  static CKSizeRange kFixedHeight = {{300, 300}, {300, 300}};
  CKSnapshotVerifyComponent(c, kFixedHeight, @"fixedHeight");
}

- (void)testSpacing
{
  auto const c = CK::FlexboxComponentBuilder()
  .viewClass([UIView class])
  .backgroundColor([UIColor whiteColor])
  .alignItems(CKFlexboxAlignItemsStart)
  .direction(CKFlexboxDirectionColumn)
  .spacing(10)
  .useDeepYogaTrees(_useDeepYogaTrees)
  .child(CK::ComponentBuilder()
          .viewClass([UIView class])
          .backgroundColor([UIColor redColor])
          .width(50)
          .height(50)
          .build())
  .child(CK::ComponentBuilder()
          .viewClass([UIView class])
          .backgroundColor([UIColor blueColor])
          .width(100)
          .height(50)
          .build())
  .child(CK::ComponentBuilder()
          .viewClass([UIView class])
          .backgroundColor([UIColor greenColor])
          .width(150)
          .height(50)
          .build())
  .build();

  // width 0-300px; height 300px
  static CKSizeRange kVariableHeight = {{0, 300}, {300, 300}};
  CKSnapshotVerifyComponent(c, kVariableHeight, @"variableHeight");
}

- (void)testNegativeSpacing
{
  auto const c = CK::FlexboxComponentBuilder()
  .viewClass([UIView class])
  .backgroundColor([UIColor whiteColor])
  .alignItems(CKFlexboxAlignItemsStart)
  .direction(CKFlexboxDirectionColumn)
  .spacing(-10)
  .useDeepYogaTrees(_useDeepYogaTrees)
  .child(CK::ComponentBuilder()
          .viewClass([UIView class])
          .backgroundColor([UIColor redColor])
          .width(50)
          .height(50)
          .build())
  .child(CK::ComponentBuilder()
          .viewClass([UIView class])
          .backgroundColor([UIColor blueColor])
          .width(100)
          .height(50)
          .build())
  .child(CK::ComponentBuilder()
          .viewClass([UIView class])
          .backgroundColor([UIColor greenColor])
          .width(150)
          .height(50)
          .build())
  .build();

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

  auto const c = CK::FlexboxComponentBuilder()
  .viewClass([UIView class])
  .attributes({{borderAttribute, nil}})
  .direction(CKFlexboxDirectionColumn)
  .spacing(10)
  .alignItems(CKFlexboxAlignItemsStretch)
  .useDeepYogaTrees(_useDeepYogaTrees)
  .child(nil)
  .child(nil)
  .build();

  // width 300px; height 0-300px
  static CKSizeRange kVariableHeight = {{300, 0}, {300, 300}};
  CKSnapshotVerifyComponentWithInsets(c, kVariableHeight, UIEdgeInsetsMake(10, 10, 10, 10), @"variableHeight");
}

- (void)testComponentSpacing
{
  // width 0-INF; height 0-INF
  static CKSizeRange kAnySize = {{0, 0}, {INFINITY, INFINITY}};

  CKComponent *spacingBefore =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
     .useDeepYogaTrees = _useDeepYogaTrees,
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

  CKComponent *spacingAfter =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
     .useDeepYogaTrees = _useDeepYogaTrees,
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

  CKComponent *spacingBalancedOut =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
     .spacing = 10,
     .useDeepYogaTrees = _useDeepYogaTrees,
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

- (void)testHorizontalReverseSpacing
{
  // width 0-INF; height 0-INF
  static CKSizeRange kAnySize = {{0, 0}, {INFINITY, INFINITY}};

  CKComponent *spacingBefore =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRowReverse,
     .useDeepYogaTrees = _useDeepYogaTrees,
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

  CKComponent *spacingAfter =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRowReverse,
     .useDeepYogaTrees = _useDeepYogaTrees,
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

  CKComponent *spacingBalancedOut =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRowReverse,
     .spacing = 10,
     .useDeepYogaTrees = _useDeepYogaTrees,
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

- (void)testVerticalReverseSpacing
{
  // width 0-INF; height 0-INF
  static CKSizeRange kAnySize = {{0, 0}, {INFINITY, INFINITY}};

  CKComponent *spacingBefore =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumnReverse,
     .useDeepYogaTrees = _useDeepYogaTrees,
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

  CKComponent *spacingAfter =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumnReverse,
     .useDeepYogaTrees = _useDeepYogaTrees,
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

  CKComponent *spacingBalancedOut =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumnReverse,
     .spacing = 10,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
     .justifyContent = CKFlexboxJustifyContentCenter,
     .useDeepYogaTrees = _useDeepYogaTrees,
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

- (void)testZOrderNoChangeLayoutOrder
{
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
     .spacing = -10,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKSnapshotVerifyComponent(c, kVariableHeight, @"variableHeight");
}

- (void)testZOrderPartialChangeLayoutOrder
{
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
     .spacing = -10,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKSnapshotVerifyComponent(c, kVariableHeight, @"variableHeight");
}

- (void)testZOrderChangeLayoutOrder
{
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
     .spacing = -10,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKSnapshotVerifyComponent(c, kVariableHeight, @"variableHeight");
}

/**
 The expected layout is [-------red------|---blue--], with no gray visible.
 The blue doesn't extend all the way.
 Fiddle: https://jsfiddle.net/g0kaahb7/1/
 */
- (void)testMinWidthIsRespected
{
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{.width=120}
   style:{
     .direction = CKFlexboxDirectionRow,
     .alignItems = CKFlexboxAlignItemsStretch,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKSnapshotVerifyComponent(c, kSize, nil);
}

/**
 This just crashes. It's supposed to look like the fiddle below, where the blue side is longer
 Fiddle: https://jsfiddle.net/62h401ce/1/
 */
- (void)testMinAndMaxWidthTakePriorityOverPreferredSize
{
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{.width=120}
   style:{
     .direction = CKFlexboxDirectionRow,
     .alignItems = CKFlexboxAlignItemsStretch,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testComponentThatChangesCrossSizeWhenMainSizeIsFlexed
{
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .useDeepYogaTrees = _useDeepYogaTrees,
   }
   children:{
     {
       CK::RatioLayoutComponentBuilder()
       .ratio(1.5)
       .component(
         CK::ComponentBuilder()
         .viewClass([UIView class])
         .backgroundColor([UIColor blueColor])
         .height(150)
         .build()
       )
       .build(),
       .flexBasis = CKRelativeDimension::Percent(1),
       .flexGrow = 1,
       .flexShrink = 1
     },
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}]},
   }];

  static CKSizeRange kFixedWidth = {{150, 0}, {150, INFINITY}};
  CKSnapshotVerifyComponent(c, kFixedWidth, nil);
}

- (void)testAlignContentStart
{
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .alignContent = CKFlexboxAlignContentStart,
     .wrap = CKFlexboxWrapWrap,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKSnapshotVerifyComponent(c, kFixedWidthAndHeight, nil);
}

- (void)testAlignContentEnd
{
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .alignContent = CKFlexboxAlignContentEnd,
     .wrap = CKFlexboxWrapWrap,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKSnapshotVerifyComponent(c, kFixedWidthAndHeight, nil);
}

- (void)testAlignContentCenter
{
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .alignContent = CKFlexboxAlignContentCenter,
     .wrap = CKFlexboxWrapWrap,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKSnapshotVerifyComponent(c, kFixedWidthAndHeight, nil);
}

- (void)testAlignContentSpaceBetween
{
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .alignContent = CKFlexboxAlignContentSpaceBetween,
     .wrap = CKFlexboxWrapWrap,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKSnapshotVerifyComponent(c, kFixedWidthAndHeight, nil);
}

- (void)testAlignContentSpaceAround
{
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .alignContent = CKFlexboxAlignContentSpaceAround,
     .wrap = CKFlexboxWrapWrap,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKSnapshotVerifyComponent(c, kFixedWidthAndHeight, nil);
}

- (void)testAlignContentStretch
{
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .alignContent = CKFlexboxAlignContentStretch,
     .wrap = CKFlexboxWrapWrap,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKSnapshotVerifyComponent(c, kFixedWidthAndHeight, nil);
}

- (void)testAlignBaseline
{
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:{
     [UIView class],
     {{@selector(setBackgroundColor:), [UIColor lightGrayColor]}},
   }
   size:{}
   style:{
     .direction = CKFlexboxDirectionRow,
     .alignItems = CKFlexboxAlignItemsBaseline,
     .useDeepYogaTrees = _useDeepYogaTrees,
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,100}],
       .flexShrink = 1,
       .useHeightAsBaseline = YES,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}],
       .flexShrink = 1,
       .useHeightAsBaseline = YES,
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,75}],
       .flexShrink = 1,
       .useHeightAsBaseline = YES,
     },
   }];

  static CKSizeRange kFixedWidthAndHeight = {{200, 200}, {200, 200}};
  CKSnapshotVerifyComponent(c, kFixedWidthAndHeight, nil);
}

- (void)testCustomBaselineComponent
{
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:{
     [UIView class],
     {{@selector(setBackgroundColor:), [UIColor lightGrayColor]}},
   }
   size:{}
   style:{
     .direction = CKFlexboxDirectionRow,
     .alignItems = CKFlexboxAlignItemsBaseline,
     .useDeepYogaTrees = _useDeepYogaTrees,
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,100}],
       .flexShrink = 1,
       .useHeightAsBaseline = YES,
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
       .useHeightAsBaseline = YES,
     },
   }];

  static CKSizeRange kFixedWidthAndHeight = {{200, 200}, {200, 200}};
  CKSnapshotVerifyComponent(c, kFixedWidthAndHeight, nil);
}

- (void)testVariableBaselines
{
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:{
     [UIView class],
     {{@selector(setBackgroundColor:), [UIColor lightGrayColor]}},
   }
   size:{}
   style:{
     .direction = CKFlexboxDirectionRow,
     .alignItems = CKFlexboxAlignItemsBaseline,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKSnapshotVerifyComponent(c, kFixedWidthAndHeight, nil);
}

- (void)testContainerPadding
{
  CKComponent *c =
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
    .useDeepYogaTrees = _useDeepYogaTrees,
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{75,75}],
       .flexShrink = 1,
     },
   }];

  static CKSizeRange kSize = {{0, 0}, {300, INFINITY}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testChildPadding
{
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testPercentagePadding
{
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testUnspecifiedPaddingIsSameAsZero
{
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testMarginOnFlexbox
{
  auto const c =
  CK::FlexboxComponentBuilder()
    .viewClass([UIView class])
    .backgroundColor([UIColor lightGrayColor])
    .direction(CKFlexboxDirectionColumn)
    .useDeepYogaTrees(_useDeepYogaTrees)
    .child(
      CK::FlexboxComponentBuilder()
        .viewClass([UIView class])
        .backgroundColor([UIColor blueColor])
        .direction(CKFlexboxDirectionRow)
        .useDeepYogaTrees(_useDeepYogaTrees)
        .child(
          CK::ComponentBuilder()
            .viewClass([UIView class])
            .backgroundColor([UIColor redColor])
            .width(50)
            .height(50)
            .build())
        .child(
          CK::ComponentBuilder()
            .viewClass([UIView class])
            .backgroundColor([UIColor greenColor])
            .width(50)
            .height(50)
            .build())
        .build())
  .build();

  static CKSizeRange kSize = {{0,0}, {INFINITY, INFINITY}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testStandardMargins
{
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testMultipleMargins
{
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testMarginOverridesSpacing
{
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .spacing = 20,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  @try {
    CKSnapshotVerifyComponent(c, kSize, nil);
  } @catch (NSException *exception) {
  }
}

- (void)testAlignSelfBaseline
{
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:{
     [UIView class],
     {{@selector(setBackgroundColor:), [UIColor lightGrayColor]}},
   }
   size:{}
   style:{
     .direction = CKFlexboxDirectionRow,
     .alignItems = CKFlexboxAlignItemsCenter,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKSnapshotVerifyComponent(c, kFixedWidthAndHeight, nil);
}

- (void)testAlignCenterWithFlexedMainDimension
{
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKFlexboxDirectionColumn,
     .alignItems = CKFlexboxAlignItemsCenter,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .useDeepYogaTrees = _useDeepYogaTrees,
   }
   children:{
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{100,100}]
     },
     {
       [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}],
       .alignSelf = CKFlexboxAlignSelfCenter,
     },
   }];

  static CKSizeRange kFixedWidth = {{150, 0}, {150, INFINITY}};
  CKSnapshotVerifyComponent(c, kFixedWidth, nil);
}

- (void)testBasicAbsolutePositioning
{
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
     .useDeepYogaTrees = _useDeepYogaTrees,
   }
   children:{
     {
       [CKFlexboxComponent
        newWithView:kWhiteBackgroundView
        size:{}
        style:{
          .alignItems = CKFlexboxAlignItemsStart,
          .direction = CKFlexboxDirectionColumn,
          .useDeepYogaTrees = _useDeepYogaTrees,
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
        }]
     },
   }];

  static CKSizeRange kFixedWidthHeight = {{150, 100}, {150, 100}};
  CKSnapshotVerifyComponent(c, kFixedWidthHeight, nil);
}

- (void)testPercentAbsolutePositioning
{
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
     .useDeepYogaTrees = _useDeepYogaTrees,
   }
   children:{
     {
       [CKFlexboxComponent
        newWithView:{}
        size:{150,100}
        style:{
          .alignItems = CKFlexboxAlignItemsStart,
          .direction = CKFlexboxDirectionColumn,
          .useDeepYogaTrees = _useDeepYogaTrees,
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
        }]
     },
   }];

  static CKSizeRange kFixedWidthHeight = {{150, 100}, {150, 100}};
  CKSnapshotVerifyComponent(c, kFixedWidthHeight, nil);
}

- (void)testRightBottomAbsolutePositioning
{
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
     .useDeepYogaTrees = _useDeepYogaTrees,
   }
   children:{
     {
       [CKFlexboxComponent
        newWithView:{}
        size:{150,100}
        style:{
          .alignItems = CKFlexboxAlignItemsStart,
          .direction = CKFlexboxDirectionColumn,
          .useDeepYogaTrees = _useDeepYogaTrees,
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
        }]
     },
   }];

  static CKSizeRange kFixedWidthHeight = {{150, 100}, {150, 100}};
  CKSnapshotVerifyComponent(c, kFixedWidthHeight, nil);
}

- (void)testAbsolutePositionsDontOverrideFixedDimensions
{
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kLightGrayBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
     .useDeepYogaTrees = _useDeepYogaTrees,
   }
   children:{
     {
       [CKFlexboxComponent
        newWithView:{}
        size:{150,100}
        style:{
          .alignItems = CKFlexboxAlignItemsStart,
          .direction = CKFlexboxDirectionColumn,
          .useDeepYogaTrees = _useDeepYogaTrees,
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
        }]
     },
   }];

  static CKSizeRange kFixedWidthHeight = {{150, 100}, {150, 100}};
  CKSnapshotVerifyComponent(c, kFixedWidthHeight, nil);
}

- (void)testAlignedStart
{
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKFlexboxDirectionColumn,
     .justifyContent = CKFlexboxJustifyContentCenter,
     .alignItems = CKFlexboxAlignItemsStart,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKFlexboxDirectionColumn,
     .justifyContent = CKFlexboxJustifyContentCenter,
     .alignItems = CKFlexboxAlignItemsEnd,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKFlexboxDirectionColumn,
     .justifyContent = CKFlexboxJustifyContentCenter,
     .alignItems = CKFlexboxAlignItemsCenter,
     .useDeepYogaTrees = _useDeepYogaTrees,
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}], 0},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,70}], 20},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,90}], 30},
   }];
  static CKSizeRange kExactSize = {{300, 300}, {300, 300}};
  CKSnapshotVerifyComponent(c, kExactSize, nil);
}

- (void)testAlignedStretchCrossSizing
{
  // Althought this test looks odd with deep yoga trees on, this
  // will actually never happen in real life, because the top yoga
  // node is always restricted to the size of the container
  // (UITableViewCell or UIScreen) so the width for the topmost node will
  // always be exact. To see the real world test case, refer to the
  // `testAlignedStretchCrossSizingWithFixedParentWidth`
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKFlexboxDirectionColumn,
     .alignItems = CKFlexboxAlignItemsStretch,
     .useDeepYogaTrees = _useDeepYogaTrees,
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}}
                          size:{.width = CKRelativeDimension::Percent(1.0), .height = 50}]},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150, 150}], 20},
   }];
  static CKSizeRange kVariableSize = {{100, 100}, {200, 200}};

  // all children should be 150px wide
  CKSnapshotVerifyComponent(c, kVariableSize, nil);
}

- (void)testAlignedStretchCrossSizingWithFixedParentWidth
{
  const auto c =
  CK::FlexboxComponentBuilder()
    .viewClass([UIView class])
    .backgroundColor([UIColor grayColor])
    .direction(CKFlexboxDirectionColumn)
    .useDeepYogaTrees(_useDeepYogaTrees)
    .minWidth(100)
    .maxWidth(200)
    .child(CK::ComponentBuilder()
           .viewClass([UIView class])
           .backgroundColor([UIColor redColor])
           .width(CKRelativeDimension::Percent(1.0))
           .height(50)
           .build())
    .child(CK::ComponentBuilder()
           .viewClass([UIView class])
           .backgroundColor([UIColor greenColor])
           .width(150)
           .height(150)
           .build())
      .marginTop(20)
    .build();

  const CKSizeRange kSize = {{200, 0}, {200, INFINITY}};

  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testAlignedStretchNoChildExceedsMin
{
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKFlexboxDirectionColumn,
     .justifyContent = CKFlexboxJustifyContentCenter,
     .alignItems = CKFlexboxAlignItemsStretch,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKFlexboxDirectionColumn,
     .justifyContent = CKFlexboxJustifyContentCenter,
     .alignItems = CKFlexboxAlignItemsStretch,
     .useDeepYogaTrees = _useDeepYogaTrees,
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

- (void)testFixedFlexBasisAppliedWhenFlexingItems
{
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
   }];

  static CKSizeRange kSize = {{200, 0}, {200, INFINITY}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testFixedFlexBasisOverridesIntrinsicSizeForNonFlexingChildren
{
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
   }];

  static CKSizeRange kSize = {{300, 0}, {300, 150}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testCrossAxisStretchingOccursAfterMainAxisFlexing
{
  // If cross axis stretching occurred *before* flexing, then the blue child would be stretched to 3000 points tall.
  // Instead it should be stretched to 300 points tall, matching the red child and not overlapping the green inset.
  CKComponent *c =
  CK::InsetComponentBuilder()
  .viewClass(UIView.class)
  .backgroundColor(UIColor.greenColor)
  .insets({10, 10, 10, 10})
  .component(
   [CKFlexboxComponent
    newWithView:{}
    size:{}
    style:{
      .direction = CKFlexboxDirectionRow,
      .alignItems = CKFlexboxAlignItemsStretch,
      .useDeepYogaTrees = _useDeepYogaTrees,
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
    }]
  ).build();

  static CKSizeRange kSize = {{300, 0}, {300, INFINITY}};
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testPositiveViolationIsDistributedEqually
{
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionColumn,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .useDeepYogaTrees = _useDeepYogaTrees,
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

- (void)testNestedLayoutStretchDoesNotViolateWidth
{
  CKComponent *c =
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
     .alignItems = CKFlexboxAlignItemsStretch,
     .useDeepYogaTrees = _useDeepYogaTrees,
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

- (void)testSimultaneousFlexGrowAndAlignStretch
{
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{.height = 100}
   style:{
     .direction = CKFlexboxDirectionRow,
     // This should make each child stretch to the full height of 100pts:
     .alignItems = CKFlexboxAlignItemsStretch,
     .useDeepYogaTrees = _useDeepYogaTrees,
   }
   children:{
     {
       // CKCompositeComponent is used just to verify that CKFlexboxComponent is actually
       // laying out each child at the correct size, not just setting RCLayout.size.
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
   }];
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
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKFlexboxDirectionColumn,
     .justifyContent = CKFlexboxJustifyContentCenter,
     .alignItems = CKFlexboxAlignItemsStart,
     .useDeepYogaTrees = _useDeepYogaTrees,
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{25,25}], 0},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{75,25}], 10},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,25}], 10},
   }];
  CKSnapshotVerifyComponent(c, kSize, nil);
}

/**
 * @uidocs CKFlexboxComponent
 * @uidocs_title Center alignment
 */
- (void)test_uidocs_alignedCenter
{
  static CKSizeRange kSize = {{0,0}, {INFINITY, INFINITY}};
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKFlexboxDirectionColumn,
     .justifyContent = CKFlexboxJustifyContentCenter,
     .alignItems = CKFlexboxAlignItemsCenter,
     .useDeepYogaTrees = _useDeepYogaTrees,
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{25,25}], 0},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{75,25}], 10},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,25}], 10},
   }];
  CKSnapshotVerifyComponent(c, kSize, nil);
}

/**
 * @uidocs CKFlexboxComponent
 * @uidocs_title End alignment
 */
- (void)test_uidocs_alignedEnd
{
  static CKSizeRange kSize = {{0,0}, {INFINITY, INFINITY}};
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .direction = CKFlexboxDirectionColumn,
     .justifyContent = CKFlexboxJustifyContentCenter,
     .alignItems = CKFlexboxAlignItemsEnd,
     .useDeepYogaTrees = _useDeepYogaTrees,
   }
   children:{
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{25,25}], 0},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{75,25}], 10},
     {[CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,25}], 10},
   }];
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testAspectRatioOneToOne {
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testAspectRatioTwoToOne {
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testAspectRatioOneToTwo {
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testNegativeAspectRatioOneToOne {
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testMinAspectRatio {
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testDifferentAspectRatioPerChild {
  CKComponent *c =
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .useDeepYogaTrees = _useDeepYogaTrees,
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
  CKSnapshotVerifyComponent(c, kSize, nil);
}

static CKFlexboxComponentChild flexChild(CKComponent *c, CGFloat flexFactor)
{
  return {c, .flexGrow = flexFactor, .flexShrink = flexFactor};
}

- (CKComponent *)_layoutWithJustify:(CKFlexboxJustifyContent)justify flexFactor:(NSInteger)flexFactor
{
  return
  [CKFlexboxComponent
   newWithView:kWhiteBackgroundView
   size:{}
   style:{
     .alignItems = CKFlexboxAlignItemsStart,
     .direction = CKFlexboxDirectionRow,
     .justifyContent = justify,
     .useDeepYogaTrees = _useDeepYogaTrees,
   }
   children:{
     flexChild([CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}], flexFactor),
     flexChild([CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}], flexFactor),
     flexChild([CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}], flexFactor),
   }];
}

@end

@interface CKFlexboxComponentWithDeepYogaTreeSnapshotTests : CKFlexboxComponentSnapshotTests
@end

@implementation CKFlexboxComponentWithDeepYogaTreeSnapshotTests

- (void)setUp
{
  [super setUp];
  self.useDeepYogaTrees = YES;
}

@end
