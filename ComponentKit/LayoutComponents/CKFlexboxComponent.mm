/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKFlexboxComponent.h"

#import <ComponentKit/CKComponentPerfScope.h>
#import <ComponentKit/CKGlobalConfig.h>
#import <ComponentKit/CKMacros.h>
#import <ComponentKit/CKInternalHelpers.h>
#import <ComponentKit/CKFunctionalHelpers.h>
#import <ComponentKit/CKSizeAssert.h>

#import "yoga/Yoga.h"

#import "CKComponent+Yoga.h"
#import "CKComponentInternal.h"
#import "CKComponentLayout.h"
#import "CKComponentLayoutBaseline.h"
#import "CKComponentSubclass.h"
#import "CKCompositeComponent.h"

const struct CKStackComponentLayoutExtraKeys CKStackComponentLayoutExtraKeys = {
  .hadOverflow = @"hadOverflow"
};

/*
 This class contains information about cached layout for FlexboxComponent child
 */
@interface CKFlexboxChildCachedLayout : NSObject

@property (nonatomic) CKComponent *component;
@property (nonatomic) CKComponentLayout componentLayout;
@property (nonatomic) float width;
@property (nonatomic) float height;
@property (nonatomic) YGMeasureMode widthMode;
@property (nonatomic) YGMeasureMode heightMode;
@property (nonatomic) CGSize parentSize;
@property (nonatomic) NSInteger zIndex;

@end

template class std::vector<CKFlexboxComponentChild>;

@implementation CKFlexboxChildCachedLayout

@end

@implementation CKFlexboxComponent {
  CKFlexboxComponentStyle _style;
  std::vector<CKFlexboxComponentChild> _children;
}

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view
                       size:(const CKComponentSize &)size
                      style:(const CKFlexboxComponentStyle &)style
                   children:(CKContainerWrapper<std::vector<CKFlexboxComponentChild>> &&)children
{
  CKComponentPerfScope perfScope(self);
  auto const component = [super newWithView:view size:size];
  if (component) {
    component->_style = style;
    component->_children = children.take();
  }
  return component;
}

static bool skipCompositeComponentSize(const CKFlexboxComponentStyle &style) {
  return style.skipCompositeComponentSize.valueOr([](){
    return CKReadGlobalConfig().skipCompositeComponentSize;
  });
}

static float convertFloatToYogaRepresentation(const float& value) {
  return isnan(value) || isinf(value) ? YGUndefined : value;
}

static float convertCGFloatToYogaRepresentation(const CGFloat& value) {
  return isnan(value) || isinf(value) ? YGUndefined : static_cast<float>(value);
}

static CGSize convertCGSizeToYogaRepresentation(const CGSize& size) {
  return {static_cast<CGFloat>(convertCGFloatToYogaRepresentation(size.width)), static_cast<CGFloat>(convertCGFloatToYogaRepresentation(size.height))};
}

static CKSizeRange convertCKSizeRangeToYogaRepresentation(const CKSizeRange& size) {
  auto range = CKSizeRange{};
  range.min = convertCGSizeToYogaRepresentation(size.min);
  range.max = convertCGSizeToYogaRepresentation(size.max);
  return range;
}

static float convertFloatToCKRepresentation(const float& value) {
  return YGFloatIsUndefined(value) ? INFINITY : value;
}

static CGFloat convertCGFloatToCKRepresentation(const CGFloat& value) {
  return YGFloatIsUndefined(static_cast<float>(value)) ? INFINITY : value;
}

static CGSize convertCGSizeToCKRepresentation(const CGSize& size) {
  return {convertCGFloatToCKRepresentation(size.width), convertCGFloatToCKRepresentation(size.height)};
}

static CKSizeRange convertCKSizeRangeToCKRepresentation(const CKSizeRange& size) {
  return CKSizeRange(convertCGSizeToCKRepresentation(size.min), convertCGSizeToCKRepresentation(size.max));
}

static bool CKYogaNodeCanUseCachedMeasurement(const YGMeasureMode widthMode,
                                   const float width,
                                   const YGMeasureMode heightMode,
                                   const float height,
                                   const YGMeasureMode lastWidthMode,
                                   const float lastWidth,
                                   const YGMeasureMode lastHeightMode,
                                   const float lastHeight,
                                   const float lastComputedWidth,
                                   const float lastComputedHeight,
                                   const float marginRow,
                                   const float marginColumn,
                                   const YGConfigRef config) {
  return YGNodeCanUseCachedMeasurement(widthMode, convertFloatToYogaRepresentation(width), heightMode, convertFloatToYogaRepresentation(height), lastWidthMode, convertFloatToYogaRepresentation(lastWidth), lastHeightMode, convertFloatToYogaRepresentation(lastHeight), convertFloatToYogaRepresentation(lastComputedWidth), convertFloatToYogaRepresentation(lastComputedHeight), convertFloatToYogaRepresentation(marginRow), convertFloatToYogaRepresentation(marginColumn), config);
}

static YGSize measureYGComponent(YGNodeRef node,
                                  float width,
                                  YGMeasureMode widthMode,
                                  float height,
                                  YGMeasureMode heightMode)
{
  CKFlexboxChildCachedLayout *cachedLayout = (__bridge CKFlexboxChildCachedLayout *)YGNodeGetContext(node);
  const CGSize minSize = {
    .width = (widthMode == YGMeasureModeExactly) ? width : 0,
    .height = (heightMode == YGMeasureModeExactly) ? height : 0
  };
  const CGSize maxSize = {
    .width = (widthMode == YGMeasureModeExactly || widthMode == YGMeasureModeAtMost) ? width : INFINITY,
    .height = (heightMode == YGMeasureModeExactly || heightMode == YGMeasureModeAtMost) ? height : INFINITY
  };
  // We cache measurements for the duration of single layout calculation of FlexboxComponent
  // ComponentKit and Yoga handle caching between calculations
  // We don't have any guarantees about when and how this will be called,
  // so we just cache the results to try to reuse them during final layout
  if (!CKYogaNodeCanUseCachedMeasurement(widthMode, width, heightMode, height, cachedLayout.widthMode, cachedLayout.width, cachedLayout.heightMode, cachedLayout.height, static_cast<float>(cachedLayout.componentLayout.size.width), static_cast<float>(cachedLayout.componentLayout.size.height), 0, 0, ckYogaDefaultConfig())) {
    CKComponent *component = cachedLayout.component;
    cachedLayout.componentLayout = CKComputeComponentLayout(component, convertCKSizeRangeToCKRepresentation(CKSizeRange(minSize, maxSize)), convertCGSizeToCKRepresentation(cachedLayout.parentSize));
    cachedLayout.width = width;
    cachedLayout.height = height;
    cachedLayout.widthMode = widthMode;
    cachedLayout.heightMode = heightMode;
  }
  const float componentLayoutWidth = static_cast<float>(cachedLayout.componentLayout.size.width);
  const float componentLayoutHeight = static_cast<float>(cachedLayout.componentLayout.size.height);

  const float measuredWidth = convertFloatToYogaRepresentation(componentLayoutWidth);
  const float measuredHeight = convertFloatToYogaRepresentation(componentLayoutHeight);
  return {measuredWidth, measuredHeight};
}

static float computeBaseline(YGNodeRef node, const float width, const float height)
{
  CKFlexboxChildCachedLayout *const cachedLayout = getCKFlexboxChildCachedLayoutFromYogaNode(node, width, height);
  if ([cachedLayout.componentLayout.extra objectForKey:kCKComponentLayoutExtraBaselineKey]) {
    CKCAssert([[cachedLayout.componentLayout.extra objectForKey:kCKComponentLayoutExtraBaselineKey] isKindOfClass:[NSNumber class]], @"You must set a NSNumber for kCKComponentLayoutExtraBaselineKey");
    return [[cachedLayout.componentLayout.extra objectForKey:kCKComponentLayoutExtraBaselineKey] floatValue];
  }

  return height;
}

static float useHeightAsBaselineFunction(YGNodeRef node, const float width, const float height)
{
  return height;
}

static CKFlexboxChildCachedLayout* getCKFlexboxChildCachedLayoutFromYogaNode(YGNodeRef node, const float width, const float height)
{
  CKFlexboxChildCachedLayout *const cachedLayout = (__bridge CKFlexboxChildCachedLayout *)YGNodeGetContext(node);

  if (!CKYogaNodeCanUseCachedMeasurement(YGMeasureModeExactly, width, YGMeasureModeExactly, height, cachedLayout.widthMode, cachedLayout.width, cachedLayout.heightMode, cachedLayout.height, static_cast<float>(cachedLayout.componentLayout.size.width), static_cast<float>(cachedLayout.componentLayout.size.height), 0, 0, ckYogaDefaultConfig())) {
    const CGSize fixedSize = {width, height};
    const CKComponentLayout componentLayout = CKComputeComponentLayout(cachedLayout.component, convertCKSizeRangeToCKRepresentation(CKSizeRange(fixedSize, fixedSize)), convertCGSizeToCKRepresentation(cachedLayout.parentSize));
    cachedLayout.componentLayout = componentLayout;
    cachedLayout.width = width;
    cachedLayout.height = height;
    cachedLayout.widthMode = YGMeasureModeExactly;
    cachedLayout.heightMode = YGMeasureModeExactly;
  }

  return cachedLayout;
}

static YGDirection ygApplicationDirection()
{
  static YGDirection applicationDirection;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    const NSWritingDirection direction = [NSParagraphStyle defaultWritingDirectionForLanguage:nil];
    applicationDirection = (direction == NSWritingDirectionRightToLeft) ? YGDirectionRTL : YGDirectionLTR;
  });
  return applicationDirection;
}

static YGDirection ygDirectionFromStackStyle(const CKFlexboxComponentStyle &style)
{
  switch (style.layoutDirection) {
    case CKLayoutDirectionApplicationDirection:
      return ygApplicationDirection();
    case CKLayoutDirectionLTR:
      return YGDirectionLTR;
    case CKLayoutDirectionRTL:
      return YGDirectionRTL;
  }
}

static YGFlexDirection ygFlexDirectionFromStackStyle(const CKFlexboxComponentStyle &style)
{
  switch (style.direction) {
    case CKFlexboxDirectionRow:
      return YGFlexDirectionRow;
    case CKFlexboxDirectionColumn:
      return YGFlexDirectionColumn;
    case CKFlexboxDirectionRowReverse:
      return YGFlexDirectionRowReverse;
    case CKFlexboxDirectionColumnReverse:
      return YGFlexDirectionColumnReverse;
  }
}

static YGJustify ygJustifyFromStackStyle(const CKFlexboxComponentStyle &style)
{
  switch (style.justifyContent) {
    case CKFlexboxJustifyContentCenter:
      return YGJustifyCenter;
    case CKFlexboxJustifyContentEnd:
      return YGJustifyFlexEnd;
    case CKFlexboxJustifyContentStart:
      return YGJustifyFlexStart;
    case CKFlexboxJustifyContentSpaceBetween:
      return YGJustifySpaceBetween;
    case CKFlexboxJustifyContentSpaceAround:
      return YGJustifySpaceAround;
    case CKFlexboxJustifyContentSpaceEvenly:
      return YGJustifySpaceEvenly;
  }
}

static YGAlign ygAlignItemsFromStackStyle(const CKFlexboxComponentStyle &style)
{
  switch (style.alignItems) {
    case CKFlexboxAlignItemsEnd:
      return YGAlignFlexEnd;
    case CKFlexboxAlignItemsCenter:
      return YGAlignCenter;
    case CKFlexboxAlignItemsStretch:
      return YGAlignStretch;
    case CKFlexboxAlignItemsBaseline:
      return YGAlignBaseline;
    case CKFlexboxAlignItemsStart:
      return YGAlignFlexStart;
  }
}

static YGAlign ygAlignContentFromStackStyle(const CKFlexboxComponentStyle &style)
{
  switch (style.alignContent) {
    case CKFlexboxAlignContentEnd:
      return YGAlignFlexEnd;
    case CKFlexboxAlignContentCenter:
      return YGAlignCenter;
    case CKFlexboxAlignContentStretch:
      return YGAlignStretch;
    case CKFlexboxAlignContentStart:
      return YGAlignFlexStart;
    case CKFlexboxAlignContentSpaceAround:
      return YGAlignSpaceAround;
    case CKFlexboxAlignContentSpaceBetween:
      return YGAlignSpaceBetween;
  }
}

static YGAlign ygAlignFromChild(const CKFlexboxComponentChild &child)
{
  switch (child.alignSelf) {
    case CKFlexboxAlignSelfStart:
      return YGAlignFlexStart;
    case CKFlexboxAlignSelfEnd:
      return YGAlignFlexEnd;
    case CKFlexboxAlignSelfCenter:
      return YGAlignCenter;
    case CKFlexboxAlignSelfBaseline:
      return YGAlignBaseline;
    case CKFlexboxAlignSelfStretch:
      return YGAlignStretch;
    case CKFlexboxAlignSelfAuto:
      return YGAlignAuto;
  }
}

static YGWrap ygWrapFromStackStyle(const CKFlexboxComponentStyle &style)
{
  switch (style.wrap) {
    case CKFlexboxWrapNoWrap:
      return YGWrapNoWrap;
    case CKFlexboxWrapWrap:
      return YGWrapWrap;
    case CKFlexboxWrapWrapReverse:
      return YGWrapWrapReverse;
  }
}

static YGEdge ygSpacingEdgeFromDirection(const CKFlexboxDirection &direction, BOOL reverse = NO)
{
  switch (direction) {
    case CKFlexboxDirectionColumn:
      return reverse ? YGEdgeBottom : YGEdgeTop;
    case CKFlexboxDirectionColumnReverse:
      return reverse ? YGEdgeTop : YGEdgeBottom;
    case CKFlexboxDirectionRow:
      return reverse ? YGEdgeEnd : YGEdgeStart;
    case CKFlexboxDirectionRowReverse:
      return reverse ? YGEdgeStart : YGEdgeEnd;
  }
}

static BOOL isHorizontalFlexboxDirection(const CKFlexboxDirection &direction)
{
  switch (direction) {
    case CKFlexboxDirectionColumn:
    case CKFlexboxDirectionColumnReverse:
      return NO;
    case CKFlexboxDirectionRow:
    case CKFlexboxDirectionRowReverse:
      return YES;
  }
}

static bool hasChildWithRelativePositioning(const CKFlexboxComponentChild &child) {
  return
  (child.component != nil
   && child.position.type == CKFlexboxPositionTypeRelative);
}

/*
 layoutCache is passed by reference so that we are able to allocate it in one thread
 and mutate it within that thread
 Layout cache shouldn't be exposed publicly
 */
- (YGNodeRef)ygStackLayoutNode:(CKSizeRange)constrainedSize
{
  const YGNodeRef stackNode = YGNodeNewWithConfig(ckYogaDefaultConfig());
  YGEdge spacingEdge = ygSpacingEdgeFromDirection(_style.direction);
  CGFloat savedSpacing = 0;
  // We need this to resolve CKRelativeDimension with percentage bases
  CGFloat parentWidth = (constrainedSize.min.width == constrainedSize.max.width) ? constrainedSize.min.width : kCKComponentParentDimensionUndefined;
  CGFloat parentHeight = (constrainedSize.min.height == constrainedSize.max.height) ? constrainedSize.min.height : kCKComponentParentDimensionUndefined;
  CGFloat parentMainDimension = isHorizontalFlexboxDirection(_style.direction) ? parentWidth : parentHeight;
  CGSize parentSize = CGSizeMake(parentWidth, parentHeight);

  // Find the first and last relatively-positioned children,
  // as we need to know them when we apply spacing as margin.
  const auto firstRelativeChild = std::find_if(_children.cbegin(), _children.cend(), hasChildWithRelativePositioning);
  const auto lastRelativeChild = ([&firstRelativeChild, children = &self->_children]() {
      if (firstRelativeChild == children->cend()) {
        return children->cend();
      }
      // We know we'll find a valid result here because we found firstRelativeChild.
      const auto rFirstRelativeChild = std::make_reverse_iterator(firstRelativeChild);
      const auto rLastRelativeChild = std::find_if(children->crbegin(), rFirstRelativeChild, hasChildWithRelativePositioning);
      // Convert back to forward iterator
      return rLastRelativeChild.base() - 1;
  })();

  for (auto iterator = _children.begin(); iterator != _children.end(); ++iterator) {
    const CKFlexboxComponentChild &child = *iterator;
    if (!child.component) {
      continue;
    }

    const YGNodeRef childNode = _style.useDeepYogaTrees ? [child.component ygNode:constrainedSize] : YGNodeNewWithConfig(ckYogaDefaultConfig());

    // We add object only if there is actual used element
    CKFlexboxChildCachedLayout *childLayout = [CKFlexboxChildCachedLayout new];
    childLayout.component = child.component;
    childLayout.componentLayout = {child.component, {0, 0}};
    childLayout.widthMode = (YGMeasureMode) -1;
    childLayout.heightMode = (YGMeasureMode) -1;
    childLayout.parentSize = parentSize;
    childLayout.zIndex = child.zIndex;
    if (child.aspectRatio.isDefined()) {
      YGNodeStyleSetAspectRatio(childNode, child.aspectRatio.aspectRatio());
    }

    // We pass the pointer ownership to context to release it later.
    // We want cachedLayout to be alive until we've finished calculations
    YGNodeSetContext(childNode, (__bridge_retained void *)childLayout);
    if (YGNodeGetChildCount(childNode) == 0) {
      YGNodeSetMeasureFunc(childNode, measureYGComponent);
    }

    if (_style.alignItems == CKFlexboxAlignItemsBaseline && [childLayout.component usesCustomBaseline]) {
      YGNodeSetBaselineFunc(childNode, computeBaseline);
    } else if (child.useHeightAsBaseline) {
      YGNodeSetBaselineFunc(childNode, useHeightAsBaselineFunction);
    }

    // If deep yoga trees are on, we need to make
    // sure we do not include CKCompositeSize as
    // node size, as it will always we equal to {}
    // and use it's child size instead
    const auto nodeSize = _style.useDeepYogaTrees || skipCompositeComponentSize(_style) ? [child.component nodeSize] : [child.component size];
    applySizeAttributes(childNode, child, nodeSize, parentWidth, parentHeight, _style.useDeepYogaTrees);

    YGNodeStyleSetFlexGrow(childNode, child.flexGrow);
    YGNodeStyleSetFlexShrink(childNode, child.flexShrink);
    YGNodeStyleSetAlignSelf(childNode, ygAlignFromChild(child));
    YGNodeStyleSetFlexBasis(childNode, child.flexBasis.resolve(YGUndefined, parentMainDimension));
    // TODO: t18095186 Remove explicit opt-out when Yoga is going to move to opt-in for text rounding
    YGNodeSetNodeType(childNode, child.useTextRounding ? YGNodeTypeText : YGNodeTypeDefault);

    applyPositionToEdge(childNode, YGEdgeStart, child.position.start);
    applyPositionToEdge(childNode, YGEdgeEnd, child.position.end);
    applyPositionToEdge(childNode, YGEdgeTop, child.position.top);
    applyPositionToEdge(childNode, YGEdgeBottom, child.position.bottom);
    applyPositionToEdge(childNode, YGEdgeLeft, child.position.left);
    applyPositionToEdge(childNode, YGEdgeRight, child.position.right);

    applyPaddingToEdge(childNode, YGEdgeTop, child.padding.top);
    applyPaddingToEdge(childNode, YGEdgeBottom, child.padding.bottom);
    applyPaddingToEdge(childNode, YGEdgeStart, child.padding.start);
    applyPaddingToEdge(childNode, YGEdgeEnd, child.padding.end);

    YGNodeStyleSetPositionType(childNode, (child.position.type == CKFlexboxPositionTypeAbsolute) ? YGPositionTypeAbsolute : YGPositionTypeRelative);

    // TODO: In odrer to keep the the logic consistent, we are resetting all
    // the margins that were potentially set from the child's style in
    // recursion. We will have to decide on the convention afterwards.
    if (_style.useDeepYogaTrees) {
      applyMarginToEdge(childNode, YGEdgeTop, convertFloatToYogaRepresentation(0));
      applyMarginToEdge(childNode, YGEdgeBottom, convertFloatToYogaRepresentation(0));
      applyMarginToEdge(childNode, YGEdgeStart, convertFloatToYogaRepresentation(0));
      applyMarginToEdge(childNode, YGEdgeEnd, convertFloatToYogaRepresentation(0));
    }

    // Spacing emulation
    // Stack layout defines spacing in terms of parent Spacing (used only between children) and
    // spacingAfter / spacingBefore for every children
    // Yoga defines spacing in terms of Parent padding and Child margin
    // To avoid confusion for all children spacing is emulated with Start Margin
    // We only use End Margin for the last child to emulate space between it and parent
    if (child.position.type == CKFlexboxPositionTypeRelative) {
      if (iterator != firstRelativeChild) {
        // Children in the middle have margin = spacingBefore + spacingAfter of previous + spacing of parent
        YGNodeStyleSetMargin(childNode, spacingEdge, convertFloatToYogaRepresentation(child.spacingBefore + _style.spacing + savedSpacing));
      } else {
        // For the space between parent and first child we just use spacingBefore
        YGNodeStyleSetMargin(childNode, spacingEdge, convertFloatToYogaRepresentation(child.spacingBefore));
      }
    }

    YGNodeInsertChild(stackNode, childNode, YGNodeGetChildCount(stackNode));

    if (child.position.type == CKFlexboxPositionTypeRelative) {
      savedSpacing = child.spacingAfter;
      if (iterator == lastRelativeChild) {
        // For the space between parent and last child we use only spacingAfter
        YGNodeStyleSetMargin(childNode, ygSpacingEdgeFromDirection(_style.direction, YES), convertFloatToYogaRepresentation(savedSpacing));
      }
    }

    /** The margins will override any spacing we applied earlier */
    applyMarginToEdge(childNode, YGEdgeTop, child.margin.top);
    applyMarginToEdge(childNode, YGEdgeBottom, child.margin.bottom);
    applyMarginToEdge(childNode, YGEdgeStart, child.margin.start);
    applyMarginToEdge(childNode, YGEdgeEnd, child.margin.end);
  }

  YGNodeStyleSetDirection(stackNode, ygDirectionFromStackStyle(_style));
  YGNodeStyleSetFlexDirection(stackNode, ygFlexDirectionFromStackStyle(_style));
  YGNodeStyleSetJustifyContent(stackNode, ygJustifyFromStackStyle(_style));
  YGNodeStyleSetAlignItems(stackNode, ygAlignItemsFromStackStyle(_style));
  YGNodeStyleSetAlignContent(stackNode, ygAlignContentFromStackStyle(_style));
  YGNodeStyleSetFlexWrap(stackNode, ygWrapFromStackStyle(_style));
  // TODO: t18095186 Remove explicit opt-out when Yoga is going to move to opt-in for text rounding
  YGNodeSetNodeType(stackNode, YGNodeTypeDefault);

  applyPaddingToEdge(stackNode, YGEdgeTop, _style.padding.top);
  applyPaddingToEdge(stackNode, YGEdgeBottom, _style.padding.bottom);
  applyPaddingToEdge(stackNode, YGEdgeStart, _style.padding.start);
  applyPaddingToEdge(stackNode, YGEdgeEnd, _style.padding.end);

  applyBorderToEdge(stackNode, YGEdgeTop, _style.border.top);
  applyBorderToEdge(stackNode, YGEdgeBottom, _style.border.bottom);
  applyBorderToEdge(stackNode, YGEdgeStart, _style.border.start);
  applyBorderToEdge(stackNode, YGEdgeEnd, _style.border.end);

  return stackNode;
}

static void applySizeAttribute(YGNodeRef node,
                               void(*percentFunc)(YGNodeRef, float),
                               void(*pointFunc)(YGNodeRef, float),
                               const CKRelativeDimension &childAttribute,
                               const CKRelativeDimension &nodeAttribute,
                               CGFloat parentValue,
                               BOOL useDeepYogaTrees)
{
  switch (childAttribute.type()) {
    case CKRelativeDimension::Type::PERCENT:
      percentFunc(node, convertFloatToYogaRepresentation(childAttribute.value() * 100));
      break;
    case CKRelativeDimension::Type::POINTS:
      pointFunc(node, convertFloatToYogaRepresentation(childAttribute.value()));
      break;
    case CKRelativeDimension::Type::AUTO:
      if (useDeepYogaTrees) {
        switch (nodeAttribute.type()) {
          case CKRelativeDimension::Type::PERCENT:
            percentFunc(node, convertFloatToYogaRepresentation(nodeAttribute.value() * 100));
            break;
          case CKRelativeDimension::Type::POINTS:
            pointFunc(node, convertFloatToYogaRepresentation(nodeAttribute.value()));
            break;
          case CKRelativeDimension::Type::AUTO:
            // Fall back to the component's size
            const CGFloat value = nodeAttribute.resolve(YGUndefined, parentValue);
            pointFunc(node, convertFloatToYogaRepresentation(value));
            break;
        }
      } else {
        // Fall back to the component's size
        const CGFloat value = nodeAttribute.resolve(YGUndefined, parentValue);
        pointFunc(node, convertFloatToYogaRepresentation(value));
      }
      break;
  }
}

static void applySizeAttributes(YGNodeRef node,
                                const CKFlexboxComponentChild &child,
                                const CKComponentSize &nodeSize,
                                CGFloat parentWidth,
                                CGFloat parentHeight,
                                BOOL useDeepYogaTrees)
{
  const CKComponentSize childSize = child.sizeConstraints;

  applySizeAttribute(node, &YGNodeStyleSetWidthPercent, &YGNodeStyleSetWidth, childSize.width, nodeSize.width, parentWidth, useDeepYogaTrees);
  applySizeAttribute(node, &YGNodeStyleSetHeightPercent, &YGNodeStyleSetHeight, childSize.height, nodeSize.height, parentHeight, useDeepYogaTrees);
  applySizeAttribute(node, &YGNodeStyleSetMinWidthPercent, &YGNodeStyleSetMinWidth, childSize.minWidth, nodeSize.minWidth, parentWidth, useDeepYogaTrees);
  applySizeAttribute(node, &YGNodeStyleSetMaxWidthPercent, &YGNodeStyleSetMaxWidth, childSize.maxWidth, nodeSize.maxWidth, parentWidth, useDeepYogaTrees);
  applySizeAttribute(node, &YGNodeStyleSetMinHeightPercent, &YGNodeStyleSetMinHeight, childSize.minHeight, nodeSize.minHeight, parentHeight, useDeepYogaTrees);
  applySizeAttribute(node, &YGNodeStyleSetMaxHeightPercent, &YGNodeStyleSetMaxHeight, childSize.maxHeight, nodeSize.maxHeight, parentHeight, useDeepYogaTrees);
}

static void applyPositionToEdge(YGNodeRef node, YGEdge edge, CKFlexboxDimension value)
{
  CKRelativeDimension dimension = value.dimension();

  switch (dimension.type()) {
    case CKRelativeDimension::Type::PERCENT:
      YGNodeStyleSetPositionPercent(node, edge, convertFloatToYogaRepresentation(dimension.value() * 100));
      break;
    case CKRelativeDimension::Type::POINTS:
      YGNodeStyleSetPosition(node, edge, convertFloatToYogaRepresentation(dimension.value()));
      break;
    case CKRelativeDimension::Type::AUTO:
      // no-op
      break;
  }
}

static void applyPaddingToEdge(YGNodeRef node, YGEdge edge, CKFlexboxDimension value)
{
  if (value.isDefined() == false) {
    return;
  }

  CKRelativeDimension dimension = value.dimension();
  switch (dimension.type()) {
    case CKRelativeDimension::Type::PERCENT:
      YGNodeStyleSetPaddingPercent(node, edge, convertFloatToYogaRepresentation(dimension.value() * 100));
      break;
    case CKRelativeDimension::Type::POINTS:
      YGNodeStyleSetPadding(node, edge, convertFloatToYogaRepresentation(dimension.value()));
      break;
    case CKRelativeDimension::Type::AUTO:
      // no-op
      break;
  }
}

static void applyMarginToEdge(YGNodeRef node, YGEdge edge, CKFlexboxDimension value)
{
  if (value.isDefined() == false) {
    return;
  }

  CKRelativeDimension relativeDimension = value.dimension();
  switch (relativeDimension.type()) {
    case CKRelativeDimension::Type::PERCENT:
      YGNodeStyleSetMarginPercent(node, edge, convertFloatToYogaRepresentation(relativeDimension.value() * 100));
      break;
    case CKRelativeDimension::Type::POINTS:
      YGNodeStyleSetMargin(node, edge, convertFloatToYogaRepresentation(relativeDimension.value()));
      break;
    case CKRelativeDimension::Type::AUTO:
      YGNodeStyleSetMarginAuto(node, edge);
      break;
  }
}

static void applyBorderToEdge(YGNodeRef node, YGEdge edge, CKFlexboxBorderDimension value)
{
  if (value.isDefined() == false) {
    return;
  }
  YGNodeStyleSetBorder(node, edge, convertFloatToYogaRepresentation(value.value()));
}

- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
{
  const CKSizeRange sanitizedSizeRange = convertCKSizeRangeToYogaRepresentation(constrainedSize);
  // We create cache for the duration of single calculation, so it is used only on one thread
  // The cache is strictly internal and shouldn't be exposed in any way
  // The purpose of the cache is to save calculations done in measure() function in Yoga to reuse
  // for final layout
  YGNodeRef layoutNode = [self ygNode:sanitizedSizeRange];

  YGNodeCalculateLayout(layoutNode, YGUndefined, YGUndefined, YGDirectionLTR);

  return [self layoutFromYgNode:layoutNode thatFits:constrainedSize];
}

- (CKComponentLayout)layoutFromYgNode:(YGNodeRef)layoutNode thatFits:(CKSizeRange)constrainedSize
{
  // Before we finalize layout we want to sort children according to their z-order
  // We want children with higher z-order to be closer to the end of list
  // They should be mounted later and thus shown on top of children with lower z-order  const NSInteger childCount = YGNodeGetChildCount(layoutNode);
  const NSInteger childCount = YGNodeGetChildCount(layoutNode);
  std::vector<YGNodeRef> sortedChildNodes(childCount);
  for (uint32_t i = 0; i < childCount; i++) {
    sortedChildNodes[i] = YGNodeGetChild(layoutNode, i);
  }
  std::sort(sortedChildNodes.begin(), sortedChildNodes.end(),
            [] (YGNodeRef const& a, YGNodeRef const& b) {
              CKFlexboxChildCachedLayout *aCachedContext = (__bridge CKFlexboxChildCachedLayout *)YGNodeGetContext(a);
              CKFlexboxChildCachedLayout *bCachedContext = (__bridge CKFlexboxChildCachedLayout *)YGNodeGetContext(b);
              return aCachedContext.zIndex < bCachedContext.zIndex;
            });

  std::vector<CKComponentLayoutChild> childrenLayout(childCount);
  const float width = convertFloatToCKRepresentation(YGNodeLayoutGetWidth(layoutNode));
  const float height = convertFloatToCKRepresentation(YGNodeLayoutGetHeight(layoutNode));
  const CGSize size = {width, height};
  for (NSUInteger i = 0; i < childCount; i++) {
    // Get the layout for every child
    const YGNodeRef childNode = sortedChildNodes[i];
    const CGFloat childX = convertFloatToCKRepresentation(YGNodeLayoutGetLeft(childNode));
    const CGFloat childY = convertFloatToCKRepresentation(YGNodeLayoutGetTop(childNode));
    const CGFloat childWidth = convertFloatToCKRepresentation(YGNodeLayoutGetWidth(childNode));
    const CGFloat childHeight = convertFloatToCKRepresentation(YGNodeLayoutGetHeight(childNode));
    // Now we take back pointer ownership to be released, as we won't need it anymore
    CKFlexboxChildCachedLayout *childCachedLayout = (__bridge_transfer CKFlexboxChildCachedLayout *)YGNodeGetContext(childNode);

    childrenLayout[i].position = CGPointMake(childX, childY);
    const CGSize childSize = CGSizeMake(childWidth, childHeight);
    // We cache measurements for the duration of single layout calculation of FlexboxComponent
    // ComponentKit and Yoga handle caching between calculations

    if (_style.useDeepYogaTrees && [childCachedLayout.component isYogaBasedLayout]) {
      // If the child component isYogaBasedLayout we don't call layoutThatFits:parentSize:
      // because it will create another Yoga tree. Instead, we call layoutFromYgNode:thatFits:
      // to reuse the already created yoga Node.
      const CKSizeRange childRange = {childSize, childSize};
      CKAssertSizeRange(childRange);
      const CKSizeRange resolvedSizeRange = childCachedLayout.component.size.resolve(size);
      CKAssertSizeRange(resolvedSizeRange);
      const CKSizeRange childConstraintSize = childRange.intersect(resolvedSizeRange);
      CKAssertSizeRange(childConstraintSize);

      childrenLayout[i].layout = [childCachedLayout.component layoutFromYgNode:childNode thatFits:childConstraintSize];
    } else if ([self canReuseCachedLayout:childCachedLayout forChildWithExactSize:childSize]) {
      childrenLayout[i].layout = childCachedLayout.componentLayout;
    } else {
      const CKSizeRange childRange = {childSize, childSize};
      CKAssertSizeRange(childRange);
      childrenLayout[i].layout = CKComputeComponentLayout(childCachedLayout.component, childRange, size);
    }
    childrenLayout[i].layout.size = childSize;
  }

  YGNodeFreeRecursive(layoutNode);

  // width/height should already be within constrainedSize, but we're just clamping to correct for roundoff error
  return {self, constrainedSize.clamp(size), childrenLayout};
}

- (BOOL)canReuseCachedLayout:(const CKFlexboxChildCachedLayout * const)childCachedLayout
       forChildWithExactSize:(const CGSize)childSize
{
  return CKYogaNodeCanUseCachedMeasurement(YGMeasureModeExactly, static_cast<float>(childSize.width), YGMeasureModeExactly, static_cast<float>(childSize.height), childCachedLayout.widthMode, childCachedLayout.width, childCachedLayout.heightMode, childCachedLayout.height, static_cast<float>(childCachedLayout.componentLayout.size.width), static_cast<float>(childCachedLayout.componentLayout.size.height), 0, 0, ckYogaDefaultConfig()) ||
    childSize.width == 0 ||
    childSize.height == 0;
}

- (BOOL)isYogaBasedLayout
{
  return YES;
}

- (YGNodeRef)ygNode:(CKSizeRange)constrainedSize
{
  const YGNodeRef node = [self ygStackLayoutNode:constrainedSize];

  // At the moment Yoga does not optimise minWidth == maxWidth, so we want to do it here
  // ComponentKit and Yoga use different constants for +Inf, so we need to make sure the don't interfere
  if (constrainedSize.min.width == constrainedSize.max.width) {
    YGNodeStyleSetWidth(node, constrainedSize.min.width);
  } else {
    YGNodeStyleSetMinWidth(node, constrainedSize.min.width);
    YGNodeStyleSetMaxWidth(node, constrainedSize.max.width);
  }

  if (constrainedSize.min.height == constrainedSize.max.height) {
    YGNodeStyleSetHeight(node, constrainedSize.min.height);
  } else {
    YGNodeStyleSetMinHeight(node, constrainedSize.min.height);
    YGNodeStyleSetMaxHeight(node, constrainedSize.max.height);
  }
  return node;
}

#pragma mark - CKMountable

- (unsigned int)numberOfChildren
{
  return (unsigned int)_children.size();
}

- (id<CKMountable>)childAtIndex:(unsigned int)index
{
  if (index < _children.size()) {
    return _children[index].component;
  }
  CKFailAssertWithCategory([self class], @"Index %u is out of bounds %lu", index, _children.size());
  return nil;
}

@end
