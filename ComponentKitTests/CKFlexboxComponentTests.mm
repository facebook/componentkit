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

#import <ComponentKit/CKFlexboxComponent.h>
#import <ComponentKit/CKCompositeComponent.h>
#import <ComponentKit/CKComponentLayout.h>

#import "yoga/Yoga.h"

@interface CKFlexboxComponent (Test)

- (YGNodeRef)ygNode:(CKSizeRange)constrainedSize;
- (CKComponentLayout)layoutThatFits:(CKSizeRange)constrainedSize parentSize:(CGSize)parentSize;

@end

@interface CKFlexboxComponentTests : XCTestCase
@end

@implementation CKFlexboxComponentTests

- (void)testSizeTranslation
{
  CKFlexboxComponent *component = CK::FlexboxComponentBuilder()
                                      .alignItems(CKFlexboxAlignItemsStart)
                                      .child(CK::ComponentBuilder()
           .viewClass([UIView class])
           .width(50)
           .height(50)
           .build())
                                      .child(CK::ComponentBuilder()
           .viewClass([UIView class])
           .width(50)
           .build())
                                      .child(CK::ComponentBuilder()
           .viewClass([UIView class])
           .height(50)
           .build())
                                      .child(CK::ComponentBuilder()
           .viewClass([UIView class])
           .build())
                                      .build();

  YGNodeRef node = [component ygNode:{{300, 0}, {300, 300}}];
  XCTAssertEqual(YGNodeStyleGetWidth(node).value, 300);
  XCTAssertEqual(YGNodeStyleGetMinHeight(node).value, 0);
  XCTAssertEqual(YGNodeStyleGetMaxHeight(node).value, 300);

  YGNodeRef childNode = YGNodeGetChild(node, 0);
  XCTAssertEqual(YGNodeStyleGetWidth(childNode).value, 50);
  XCTAssertEqual(YGNodeStyleGetHeight(childNode).value, 50);

  childNode = YGNodeGetChild(node, 1);
  XCTAssertEqual(YGNodeStyleGetWidth(childNode).value, 50);
  XCTAssertTrue(YGFloatIsUndefined(YGNodeStyleGetHeight(childNode).value));

  childNode = YGNodeGetChild(node, 2);
  XCTAssertTrue(YGFloatIsUndefined(YGNodeStyleGetWidth(childNode).value));
  XCTAssertEqual(YGNodeStyleGetHeight(childNode).value, 50);

  childNode = YGNodeGetChild(node, 3);
  XCTAssertTrue(YGFloatIsUndefined(YGNodeStyleGetWidth(childNode).value));
  XCTAssertTrue(YGFloatIsUndefined(YGNodeStyleGetHeight(childNode).value));
}

- (void)testDirectionTranslation
{
  CKFlexboxComponent *component = CK::FlexboxComponentBuilder()
                                      .alignItems(CKFlexboxAlignItemsStart)
                                      .build();
  YGNodeRef node = [component ygNode:{{0, 0}, {0, 0}}];
  XCTAssertEqual(YGNodeStyleGetFlexDirection(node), YGFlexDirectionColumn);

  component = CK::FlexboxComponentBuilder()
                  .alignItems(CKFlexboxAlignItemsStart)
                  .direction(CKFlexboxDirectionColumn)
                  .build();
  node = [component ygNode:{{0, 0}, {0, 0}}];
  XCTAssertEqual(YGNodeStyleGetFlexDirection(node), YGFlexDirectionColumn);

  component = CK::FlexboxComponentBuilder()
                  .alignItems(CKFlexboxAlignItemsStart)
                  .direction(CKFlexboxDirectionRow)
                  .build();
  node = [component ygNode:{{0, 0}, {0, 0}}];
  XCTAssertEqual(YGNodeStyleGetFlexDirection(node), YGFlexDirectionRow);
}

- (void)testJustifyTranslation
{
  CKFlexboxComponent *component = CK::FlexboxComponentBuilder()
                                      .alignItems(CKFlexboxAlignItemsStart)
                                      .build();
  YGNodeRef node = [component ygNode:{{0, 0}, {0, 0}}];
  XCTAssertEqual(YGNodeStyleGetJustifyContent(node), YGJustifyFlexStart);

  component = CK::FlexboxComponentBuilder()
                  .alignItems(CKFlexboxAlignItemsStart)
                  .justifyContent(CKFlexboxJustifyContentStart)
                  .build();
  node = [component ygNode:{{0, 0}, {0, 0}}];
  XCTAssertEqual(YGNodeStyleGetJustifyContent(node), YGJustifyFlexStart);

  component = CK::FlexboxComponentBuilder()
                  .alignItems(CKFlexboxAlignItemsStart)
                  .justifyContent(CKFlexboxJustifyContentCenter)
                  .build();
  node = [component ygNode:{{0, 0}, {0, 0}}];
  XCTAssertEqual(YGNodeStyleGetJustifyContent(node), YGJustifyCenter);

  component = CK::FlexboxComponentBuilder()
                  .alignItems(CKFlexboxAlignItemsStart)
                  .justifyContent(CKFlexboxJustifyContentEnd)
                  .build();
  node = [component ygNode:{{0, 0}, {0, 0}}];
  XCTAssertEqual(YGNodeStyleGetJustifyContent(node), YGJustifyFlexEnd);
}

- (void)testAlignItemsTranslation
{
  CKFlexboxComponent *component = CK::FlexboxComponentBuilder()
                                      .alignItems(CKFlexboxAlignItemsStart)
                                      .build();
  YGNodeRef node = [component ygNode:{{0, 0}, {0, 0}}];
  XCTAssertEqual(YGNodeStyleGetAlignItems(node), YGAlignFlexStart);

  component = CK::FlexboxComponentBuilder()
                  .alignItems(CKFlexboxAlignItemsStart)
                  .build();
  node = [component ygNode:{{0, 0}, {0, 0}}];
  XCTAssertEqual(YGNodeStyleGetAlignItems(node), YGAlignFlexStart);

  component = CK::FlexboxComponentBuilder()
                  .alignItems(CKFlexboxAlignItemsStretch)
                  .build();
  node = [component ygNode:{{0, 0}, {0, 0}}];
  XCTAssertEqual(YGNodeStyleGetAlignItems(node), YGAlignStretch);

  component = CK::FlexboxComponentBuilder()
                  .alignItems(CKFlexboxAlignItemsEnd)
                  .build();
  node = [component ygNode:{{0, 0}, {0, 0}}];
  XCTAssertEqual(YGNodeStyleGetAlignItems(node), YGAlignFlexEnd);

  component = CK::FlexboxComponentBuilder()
                  .alignItems(CKFlexboxAlignItemsCenter)
                  .build();
  node = [component ygNode:{{0, 0}, {0, 0}}];
  XCTAssertEqual(YGNodeStyleGetAlignItems(node), YGAlignCenter);
}

- (void)testAlignChildTranslation
{
  CKFlexboxComponent *component = CK::FlexboxComponentBuilder()
                                      .alignItems(CKFlexboxAlignItemsStart)
                                      .child(CK::ComponentBuilder()
            .viewClass([UIView class])
            .build())
                                      .child(CK::ComponentBuilder()
            .viewClass([UIView class])
            .build())
                                          .alignSelf(CKFlexboxAlignSelfAuto)
                                      .child(CK::ComponentBuilder()
            .viewClass([UIView class])
            .build())
                                          .alignSelf(CKFlexboxAlignSelfStart)
                                      .child(CK::ComponentBuilder()
            .viewClass([UIView class])
            .build())
                                          .alignSelf(CKFlexboxAlignSelfEnd)
                                      .child(CK::ComponentBuilder()
            .viewClass([UIView class])
            .build())
                                          .alignSelf(CKFlexboxAlignSelfStretch)
                                      .child(CK::ComponentBuilder()
            .viewClass([UIView class])
            .build())
                                          .alignSelf(CKFlexboxAlignSelfCenter)
                                      .build();
  YGNodeRef node = [component ygNode:{{0, 0}, {0, 0}}];

  YGNodeRef childNode = YGNodeGetChild(node, 0);
  XCTAssertEqual(YGNodeStyleGetAlignSelf(childNode), YGAlignAuto);
  childNode = YGNodeGetChild(node, 1);
  XCTAssertEqual(YGNodeStyleGetAlignSelf(childNode), YGAlignAuto);
  childNode = YGNodeGetChild(node, 2);
  XCTAssertEqual(YGNodeStyleGetAlignSelf(childNode), YGAlignFlexStart);
  childNode = YGNodeGetChild(node, 3);
  XCTAssertEqual(YGNodeStyleGetAlignSelf(childNode), YGAlignFlexEnd);
  childNode = YGNodeGetChild(node, 4);
  XCTAssertEqual(YGNodeStyleGetAlignSelf(childNode), YGAlignStretch);
  childNode = YGNodeGetChild(node, 5);
  XCTAssertEqual(YGNodeStyleGetAlignSelf(childNode), YGAlignCenter);
}

- (void)testFlexGrowShrinkTranslation
{
  CKFlexboxComponent *component = CK::FlexboxComponentBuilder()
                                      .alignItems(CKFlexboxAlignItemsStart)
                                      .child(CK::ComponentBuilder()
           .viewClass([UIView class])
           .build())
                                      .child(CK::ComponentBuilder()
           .viewClass([UIView class])
           .build())
                                          .flexGrow(1)
                                          .flexShrink(0.5)
                                      .child(CK::ComponentBuilder()
           .viewClass([UIView class])
           .build())
                                          .flexShrink(1)
                                      .child(CK::ComponentBuilder()
           .viewClass([UIView class])
           .build())
                                          .flexGrow(0.5)
                                      .build();
  YGNodeRef node = [component ygNode:{{0, 0}, {0, 0}}];

  YGNodeRef childNode = YGNodeGetChild(node, 0);
  XCTAssertEqual(YGNodeStyleGetFlexGrow(childNode), 0);
  XCTAssertEqual(YGNodeStyleGetFlexShrink(childNode), 0);
  childNode = YGNodeGetChild(node, 1);
  XCTAssertEqual(YGNodeStyleGetFlexGrow(childNode), 1);
  XCTAssertEqual(YGNodeStyleGetFlexShrink(childNode), 0.5);
  childNode = YGNodeGetChild(node, 2);
  XCTAssertEqual(YGNodeStyleGetFlexGrow(childNode), 0);
  XCTAssertEqual(YGNodeStyleGetFlexShrink(childNode), 1);
  childNode = YGNodeGetChild(node, 3);
  XCTAssertEqual(YGNodeStyleGetFlexGrow(childNode), 0.5);
  XCTAssertEqual(YGNodeStyleGetFlexShrink(childNode), 0);
}

- (void)testFlexBasisTranslation
{
  CKFlexboxComponent *component = CK::FlexboxComponentBuilder()
                                      .alignItems(CKFlexboxAlignItemsStart)
                                      .child(CK::ComponentBuilder()
            .viewClass([UIView class])
            .build())
                                      .child(CK::ComponentBuilder()
            .viewClass([UIView class])
            .build())
                                          .flexBasis(CKRelativeDimension::Auto())
                                      .child(CK::ComponentBuilder()
            .viewClass([UIView class])
            .build())
                                          .flexBasis(100)
                                      .child(CK::ComponentBuilder()
            .viewClass([UIView class])
            .build())
                                          .flexBasis(CKRelativeDimension::Percent(0.5))
                                      .build();
  YGNodeRef node = [component ygNode:{{0, 300}, {0, 300}}];

  YGNodeRef childNode = YGNodeGetChild(node, 0);
  XCTAssertTrue(YGFloatIsUndefined(YGNodeStyleGetFlexBasis(childNode).value));
  childNode = YGNodeGetChild(node, 1);
  XCTAssertTrue(YGFloatIsUndefined(YGNodeStyleGetFlexBasis(childNode).value));
  childNode = YGNodeGetChild(node, 2);
  XCTAssertEqual(YGNodeStyleGetFlexBasis(childNode).value, 100);
  childNode = YGNodeGetChild(node, 3);
  XCTAssertEqual(YGNodeStyleGetFlexBasis(childNode).value, 150);
}

- (void)testSpacingTranslation
{
  CKFlexboxComponent *component = CK::FlexboxComponentBuilder()
                                      .alignItems(CKFlexboxAlignItemsStart)
                                      .spacing(5)
                                      .child(CK::ComponentBuilder()
            .viewClass([UIView class])
            .build())
                                          .spacingBefore(15)
                                      .child(CK::ComponentBuilder()
            .viewClass([UIView class])
            .build())
                                          .spacingAfter(5)
                                      .child(CK::ComponentBuilder()
            .viewClass([UIView class])
            .build())
                                          .spacingAfter(5)
                                      .child(CK::ComponentBuilder()
            .viewClass([UIView class])
            .build())
                                          .spacingBefore(-10)
                                          .spacingAfter(10)
                                      .build();
  YGNodeRef node = [component ygNode:{{0, 300}, {0, 300}}];

  YGNodeRef childNode = YGNodeGetChild(node, 0);
  XCTAssertEqual(YGNodeStyleGetMargin(childNode, YGEdgeTop).value, 15);
  childNode = YGNodeGetChild(node, 1);
  XCTAssertEqual(YGNodeStyleGetMargin(childNode, YGEdgeTop).value, 5);
  childNode = YGNodeGetChild(node, 2);
  XCTAssertEqual(YGNodeStyleGetMargin(childNode, YGEdgeTop).value, 10);
  childNode = YGNodeGetChild(node, 3);
  XCTAssertEqual(YGNodeStyleGetMargin(childNode, YGEdgeTop).value, 0);
  XCTAssertEqual(YGNodeStyleGetMargin(childNode, YGEdgeBottom).value, 10);
}

- (void)testCorrectnesOfDefaultStyleValues
{
  CKFlexboxComponentStyle style = {};
  XCTAssertEqual(style.alignItems, CKFlexboxAlignItemsStretch);
}

- (void)testSameLayoutIsCalculatedWithAndWithoutDeepYogaTrees
{
  CKComponentLayout(^buildComponentTreeAndComputeLayout)(BOOL) = ^CKComponentLayout(BOOL useDeepYogaTrees) {
    CKFlexboxComponent *component =
    [CKFlexboxComponent
     newWithView:{} size:{}
     style:{
       .alignItems = CKFlexboxAlignItemsStart,
       .spacing = 5,
       .useDeepYogaTrees = useDeepYogaTrees,
     }
     children:{
       {
         .component = [CKCompositeComponent
                       newWithComponent:
                       CK::FlexboxComponentBuilder()
                           .alignItems(CKFlexboxAlignItemsStart)
                           .spacing(5)
                           .useDeepYogaTrees(useDeepYogaTrees)
                           .child([CKCompositeComponent newWithComponent: CK::ComponentBuilder()
                                                                        .viewClass([UIView class])
                                                                        .build()])
                               .spacingBefore(15)
                           .child(CK::ComponentBuilder()
                                .viewClass([UIView class])
                                .build())
                               .spacingAfter(5)
                           .child(CK::ComponentBuilder()
                                .viewClass([UIView class])
                                .build())
                               .spacingAfter(5)
                           .child(CK::ComponentBuilder()
                                .viewClass([UIView class])
                                .build())
                               .spacingBefore(-10)
                               .spacingAfter(10)
                           .build()]
       },
       { CK::ComponentBuilder()
             .viewClass([UIView class])
             .build(), .spacingAfter = 5},
       { CK::ComponentBuilder()
             .viewClass([UIView class])
             .build(), .spacingAfter = 5},
       { CK::ComponentBuilder()
             .viewClass([UIView class])
             .build(), .spacingBefore =-10, .spacingAfter = 10},
     }];

    const CKSizeRange kSize = {{500, 500}, {500, 500}};
    return [component layoutThatFits:kSize parentSize:kSize.max];
  };

  XCTAssertTrue(areLayoutsEqual(buildComponentTreeAndComputeLayout(NO), buildComponentTreeAndComputeLayout(YES)));
}

static BOOL areLayoutsEqual(const CKComponentLayout &left, const CKComponentLayout &right) {
  if (left.component.class != right.component.class) {
    return NO;
  }

  if (CGSizeEqualToSize(left.size, right.size) == NO || left.children->size() != right.children->size()) {
    return NO;
  }

  for(std::vector<CKComponentLayoutChild>::size_type i = 0; i != left.children->size(); i++) {
    auto leftChild = left.children->at(i);
    auto rightChild = right.children->at(i);

    if (CGPointEqualToPoint(leftChild.position, rightChild.position) == NO) {
      return NO;
    }

    if (areLayoutsEqual(leftChild.layout, rightChild.layout) == NO) {
      return NO;
    }
  }

  return YES;
}

@end
