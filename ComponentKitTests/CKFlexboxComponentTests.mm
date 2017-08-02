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

#import <yoga/Yoga.h>

@interface CKFlexboxComponent (Test)
- (YGNodeRef)ygNode:(CKSizeRange)constrainedSize;
@end

@interface CKFlexboxComponentTests : XCTestCase
@end

@implementation CKFlexboxComponentTests
{
}

- (void)testSizeTranslation
{
  CKFlexboxComponent *component = [CKFlexboxComponent newWithView:{} size:{} style:{}
   children:{
     { [CKComponent newWithView:{[UIView class]} size:{50,50}] },
     { [CKComponent newWithView:{[UIView class]} size:{.width = 50}] },
     { [CKComponent newWithView:{[UIView class]} size:{.height = 50}] },
     { [CKComponent newWithView:{[UIView class]} size:{}] },
   }];

  YGNodeRef node = [component ygNode:{{300, 0}, {300, 300}}];
  XCTAssertEqual(YGNodeStyleGetWidth(node).value, 300);
  XCTAssertEqual(YGNodeStyleGetMinHeight(node).value, 0);
  XCTAssertEqual(YGNodeStyleGetMaxHeight(node).value, 300);

  YGNodeRef childNode = YGNodeGetChild(node, 0);
  XCTAssertEqual(YGNodeStyleGetWidth(childNode).value, 50);
  XCTAssertEqual(YGNodeStyleGetHeight(childNode).value, 50);

  childNode = YGNodeGetChild(node, 1);
  XCTAssertEqual(YGNodeStyleGetWidth(childNode).value, 50);
  XCTAssertTrue(isnan(YGNodeStyleGetHeight(childNode).value));

  childNode = YGNodeGetChild(node, 2);
  XCTAssertTrue(isnan(YGNodeStyleGetWidth(childNode).value));
  XCTAssertEqual(YGNodeStyleGetHeight(childNode).value, 50);

  childNode = YGNodeGetChild(node, 3);
  XCTAssertTrue(isnan(YGNodeStyleGetWidth(childNode).value));
  XCTAssertTrue(isnan(YGNodeStyleGetHeight(childNode).value));
}

- (void)testDirectionTranslation
{
  CKFlexboxComponent *component = [CKFlexboxComponent newWithView:{} size:{} style:{} children:{}];
  YGNodeRef node = [component ygNode:{{0, 0}, {0, 0}}];
  XCTAssertEqual(YGNodeStyleGetFlexDirection(node), YGFlexDirectionColumn);

  component = [CKFlexboxComponent newWithView:{} size:{} style:{
    .direction = CKFlexboxDirectionVertical
  } children:{}];
  node = [component ygNode:{{0, 0}, {0, 0}}];
  XCTAssertEqual(YGNodeStyleGetFlexDirection(node), YGFlexDirectionColumn);

  component = [CKFlexboxComponent newWithView:{} size:{} style:{
    .direction = CKFlexboxDirectionHorizontal
  } children:{}];
  node = [component ygNode:{{0, 0}, {0, 0}}];
  XCTAssertEqual(YGNodeStyleGetFlexDirection(node), YGFlexDirectionRow);
}

- (void)testJustifyTranslation
{
  CKFlexboxComponent *component = [CKFlexboxComponent newWithView:{} size:{} style:{} children:{}];
  YGNodeRef node = [component ygNode:{{0, 0}, {0, 0}}];
  XCTAssertEqual(YGNodeStyleGetJustifyContent(node), YGJustifyFlexStart);

  component = [CKFlexboxComponent newWithView:{} size:{} style:{
    .justifyContent = CKFlexboxJustifyContentStart
  } children:{}];
  node = [component ygNode:{{0, 0}, {0, 0}}];
  XCTAssertEqual(YGNodeStyleGetJustifyContent(node), YGJustifyFlexStart);

  component = [CKFlexboxComponent newWithView:{} size:{} style:{
    .justifyContent = CKFlexboxJustifyContentCenter
  } children:{}];
  node = [component ygNode:{{0, 0}, {0, 0}}];
  XCTAssertEqual(YGNodeStyleGetJustifyContent(node), YGJustifyCenter);

  component = [CKFlexboxComponent newWithView:{} size:{} style:{
    .justifyContent = CKFlexboxJustifyContentEnd
  } children:{}];
  node = [component ygNode:{{0, 0}, {0, 0}}];
  XCTAssertEqual(YGNodeStyleGetJustifyContent(node), YGJustifyFlexEnd);
}

- (void)testAlignItemsTranslation
{
  CKFlexboxComponent *component = [CKFlexboxComponent newWithView:{} size:{} style:{} children:{}];
  YGNodeRef node = [component ygNode:{{0, 0}, {0, 0}}];
  XCTAssertEqual(YGNodeStyleGetAlignItems(node), YGAlignFlexStart);

  component = [CKFlexboxComponent newWithView:{} size:{} style:{
    .alignItems = CKFlexboxAlignItemsStart
  } children:{}];
  node = [component ygNode:{{0, 0}, {0, 0}}];
  XCTAssertEqual(YGNodeStyleGetAlignItems(node), YGAlignFlexStart);

  component = [CKFlexboxComponent newWithView:{} size:{} style:{
    .alignItems = CKFlexboxAlignItemsStretch
  } children:{}];
  node = [component ygNode:{{0, 0}, {0, 0}}];
  XCTAssertEqual(YGNodeStyleGetAlignItems(node), YGAlignStretch);

  component = [CKFlexboxComponent newWithView:{} size:{} style:{
    .alignItems = CKFlexboxAlignItemsEnd
  } children:{}];
  node = [component ygNode:{{0, 0}, {0, 0}}];
  XCTAssertEqual(YGNodeStyleGetAlignItems(node), YGAlignFlexEnd);

  component = [CKFlexboxComponent newWithView:{} size:{} style:{
    .alignItems = CKFlexboxAlignItemsCenter
  } children:{}];
  node = [component ygNode:{{0, 0}, {0, 0}}];
  XCTAssertEqual(YGNodeStyleGetAlignItems(node), YGAlignCenter);
}

- (void)testAlignChildTranslation
{
  CKFlexboxComponent *component = [CKFlexboxComponent newWithView:{} size:{} style:{}
    children:{
      { [CKComponent newWithView:{[UIView class]} size:{}] },
      { [CKComponent newWithView:{[UIView class]} size:{}], .alignSelf = CKFlexboxAlignSelfAuto },
      { [CKComponent newWithView:{[UIView class]} size:{}], .alignSelf = CKFlexboxAlignSelfStart },
      { [CKComponent newWithView:{[UIView class]} size:{}], .alignSelf = CKFlexboxAlignSelfEnd },
      { [CKComponent newWithView:{[UIView class]} size:{}], .alignSelf = CKFlexboxAlignSelfStretch },
      { [CKComponent newWithView:{[UIView class]} size:{}], .alignSelf = CKFlexboxAlignSelfCenter },
    }];
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
  CKFlexboxComponent *component = [CKFlexboxComponent newWithView:{} size:{} style:{}
   children:{
     { [CKComponent newWithView:{[UIView class]} size:{}] },
     { [CKComponent newWithView:{[UIView class]} size:{}], .flexGrow = 1, .flexShrink = 0.5 },
     { [CKComponent newWithView:{[UIView class]} size:{}], .flexShrink = 1 },
     { [CKComponent newWithView:{[UIView class]} size:{}], .flexGrow = 0.5,},
   }];
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
  CKFlexboxComponent *component = [CKFlexboxComponent newWithView:{} size:{} style:{}
    children:{
      { [CKComponent newWithView:{[UIView class]} size:{}] },
      { [CKComponent newWithView:{[UIView class]} size:{}], .flexBasis = CKRelativeDimension::Auto(),},
      { [CKComponent newWithView:{[UIView class]} size:{}], .flexBasis = 100 },
      { [CKComponent newWithView:{[UIView class]} size:{}], .flexBasis = CKRelativeDimension::Percent(0.5)},
    }];
  YGNodeRef node = [component ygNode:{{0, 300}, {0, 300}}];

  YGNodeRef childNode = YGNodeGetChild(node, 0);
  XCTAssertTrue(isnan(YGNodeStyleGetFlexBasis(childNode).value));
  childNode = YGNodeGetChild(node, 1);
  XCTAssertTrue(isnan(YGNodeStyleGetFlexBasis(childNode).value));
  childNode = YGNodeGetChild(node, 2);
  XCTAssertEqual(YGNodeStyleGetFlexBasis(childNode).value, 100);
  childNode = YGNodeGetChild(node, 3);
  XCTAssertEqual(YGNodeStyleGetFlexBasis(childNode).value, 150);
}

- (void)testSpacingTranslation
{
  CKFlexboxComponent *component = [CKFlexboxComponent newWithView:{} size:{} style:{.spacing = 5}
    children:{
      { [CKComponent newWithView:{[UIView class]} size:{}], .spacingBefore = 15},
      { [CKComponent newWithView:{[UIView class]} size:{}], .spacingAfter = 5},
      { [CKComponent newWithView:{[UIView class]} size:{}], .spacingAfter = 5},
      { [CKComponent newWithView:{[UIView class]} size:{}], .spacingBefore =-10, .spacingAfter = 10},
    }];
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

@end
