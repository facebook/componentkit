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

#import <yoga/Yoga.h>

#import "CKComponentSubclass.h"
#import "CKComponentInternal.h"
#import "CKInternalHelpers.h"

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
@property (nonatomic) CKStackLayoutAlignSelf align;
@property (nonatomic) NSInteger zIndex;

@end

@implementation CKFlexboxChildCachedLayout

@end

@implementation CKStackLayoutComponent {
  CKStackLayoutComponentStyle _style;
  std::vector<CKStackLayoutComponentChild> _children;
}

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view
                       size:(const CKComponentSize &)size
                      style:(const CKStackLayoutComponentStyle &)style
                   children:(CKContainerWrapper<std::vector<CKStackLayoutComponentChild>> &&)children
{
  CKStackLayoutComponent *c = [super newWithView:view size:size];
  if (c) {
    c->_style = style;
    c->_children = children.take();
  }
  return component;
}

+ (YGConfigRef)ckYogaDefaultConfig
{
  static YGConfigRef defaultConfig;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    defaultConfig = YGConfigNew();
    YGConfigSetExperimentalFeatureEnabled(defaultConfig, YGExperimentalFeatureMinFlexFix, true);
  });
  return defaultConfig;
}

static YGSize measureCssComponent(YGNodeRef node,
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
  if (!YGNodeCanUseCachedMeasurement(widthMode, width, heightMode, height,
                                     cachedLayout.widthMode, cachedLayout.width, cachedLayout.heightMode, cachedLayout.height,
                                     cachedLayout.componentLayout.size.width, cachedLayout.componentLayout.size.height, 0, 0)) {
    CKComponent *component = cachedLayout.component;
    CKComponentLayout componentLayout = CKComputeComponentLayout(component, CKSizeRange(minSize, maxSize), cachedLayout.parentSize);
    cachedLayout.componentLayout = componentLayout;
    cachedLayout.width = width;
    cachedLayout.height = height;
    cachedLayout.widthMode = widthMode;
    cachedLayout.heightMode = heightMode;
  }
  return {static_cast<float>(cachedLayout.componentLayout.size.width), static_cast<float>(cachedLayout.componentLayout.size.height)};
}

static YGFlexDirection ygDirectionFromStackStyle(const CKStackLayoutComponentStyle &style)
{
  switch (style.direction) {
    case CKStackLayoutDirectionHorizontal:
      return YGFlexDirectionRow;
    case CKStackLayoutDirectionVertical:
      return YGFlexDirectionColumn;
    case CKStackLayoutDirectionHorizontalReverse:
      return YGFlexDirectionRowReverse;
    case CKStackLayoutDirectionVerticalReverse:
      return YGFlexDirectionColumnReverse;
  }
}

static YGJustify ygJustifyFromStackStyle(const CKStackLayoutComponentStyle &style)
{
  switch (style.justifyContent) {
    case CKStackLayoutJustifyContentCenter:
      return YGJustifyCenter;
    case CKStackLayoutJustifyContentEnd:
      return YGJustifyFlexEnd;
    case CKStackLayoutJustifyContentStart:
      return YGJustifyFlexStart;
    case CKStackLayoutJustifyContentSpaceBetween:
      return YGJustifySpaceBetween;
    case CKStackLayoutJustifyContentSpaceAround:
      return YGJustifySpaceAround;
  }
}

static YGAlign ygAlignFromStackStyle(const CKStackLayoutComponentStyle &style)
{
  switch (style.alignItems) {
    case CKStackLayoutAlignItemsEnd:
      return YGAlignFlexEnd;
    case CKStackLayoutAlignItemsCenter:
      return YGAlignCenter;
    case CKStackLayoutAlignItemsStretch:
      return YGAlignStretch;
    case CKStackLayoutAlignItemsStart:
      return YGAlignFlexStart;
  }
}

static YGAlign ygAlignFromChild(const CKStackLayoutComponentChild &child)
{
  switch (child.alignSelf) {
    case CKStackLayoutAlignSelfStart:
      return YGAlignFlexStart;
    case CKStackLayoutAlignSelfEnd:
      return YGAlignFlexEnd;
    case CKStackLayoutAlignSelfCenter:
      return YGAlignCenter;
    case CKStackLayoutAlignSelfStretch:
      return YGAlignStretch;
    case CKStackLayoutAlignSelfAuto:
      return YGAlignAuto;
  }
}

static YGWrap ygWrapFromStackStyle(const CKStackLayoutComponentStyle &style)
{
  switch (style.wrap) {
    case CKStackLayoutWrapNoWrap:
      return YGWrapNoWrap;
    case CKStackLayoutWrapWrap:
      return YGWrapWrap;
    case CKStackLayoutWrapWrapReverse:
      return YGWrapWrapReverse;
  }
}

/*
 layoutCache is passed by reference so that we are able to allocate it in one thread
 and mutate it within that thread
 Layout cache shouldn't be exposed publicly
 */
- (YGNodeRef)cssStackLayoutNode:(CKSizeRange)constrainedSize cache:(NSArray<CKFlexboxChildCachedLayout *> **)layoutCache
{
  const YGNodeRef stackNode = YGNodeNewWithConfig([[self class] ckYogaDefaultConfig]);
  YGEdge spacingEdge = _style.direction == CKStackLayoutDirectionHorizontal ? YGEdgeStart : YGEdgeTop;
  CGFloat savedSpacing = 0;
  // We need this to resolve CKRelativeDimension with percentage bases
  CGFloat parentWidth = (constrainedSize.min.width == constrainedSize.max.width) ? constrainedSize.min.width : kCKComponentParentDimensionUndefined;
  CGFloat parentHeight = (constrainedSize.min.height == constrainedSize.max.height) ? constrainedSize.min.height : kCKComponentParentDimensionUndefined;
  CGFloat parentMainDimension = (_style.direction == CKStackLayoutDirectionHorizontal) ? parentWidth : parentHeight;
  CGSize parentSize = CGSizeMake(parentWidth, parentHeight);
  
  NSMutableArray *newLayoutCache = [NSMutableArray array];
  const auto children = CK::filter(_children, [](const CKStackLayoutComponentChild &child){
    return child.component != nil;
  });
  
  for (auto iterator = children.begin(); iterator != children.end(); iterator++) {
    const CKStackLayoutComponentChild child = *iterator;
    CKComponent *childComponent = child.component;
    const YGNodeRef childNode = YGNodeNewWithConfig([[self class] ckYogaDefaultConfig]);
    
    // We add object only if there is actual used element
    CKFlexboxChildCachedLayout *childLayout = [CKFlexboxChildCachedLayout new];
    childLayout.component = child.component;
    childLayout.widthMode = (YGMeasureMode) -1;
    childLayout.heightMode = (YGMeasureMode) -1;
    childLayout.parentSize = parentSize;
    childLayout.align = child.alignSelf;
    childLayout.zIndex = child.zIndex;
    
    [newLayoutCache addObject:childLayout];
    YGNodeSetContext(childNode, (__bridge void *)childLayout);
    YGNodeSetMeasureFunc(childNode, measureCssComponent);
    
    const CGSize childSize = {[childComponent size].width.resolve(YGUndefined, parentWidth),
      [childComponent size].height.resolve(YGUndefined, parentHeight)};
    YGNodeStyleSetWidth(childNode, childSize.width);
    YGNodeStyleSetHeight(childNode, childSize.height);
    YGNodeStyleSetFlexGrow(childNode, child.flexGrow);
    YGNodeStyleSetFlexShrink(childNode, child.flexShrink);
    YGNodeStyleSetAlignSelf(childNode, ygAlignFromChild(child));
    YGNodeStyleSetFlexBasis(childNode, child.flexBasis.resolve(YGUndefined, parentMainDimension));
    
    YGNodeStyleSetPosition(childNode, YGEdgeStart, child.position.start);
    YGNodeStyleSetPosition(childNode, YGEdgeTop, child.position.top);
    YGNodeStyleSetPositionType(childNode, (child.position.type == CKStackLayoutPositionTypeAbsolute) ? YGPositionTypeAbsolute : YGPositionTypeRelative);
    
    // Spacing emulation
    // Stack layout defines spacing in terms of parent Spacing (used only between children) and
    // spacingAfter / spacingBefore for every children
    // Yoga defines spacing in terms of Parent padding and Child margin
    // To avoid confusion for all children spacing is emulated with Start Margin
    // We only use End Margin for the last child to emulate space between it and parent
    if (iterator != children.begin()) {
      // Children in the middle have margin = spacingBefore + spacingAfter of previous + spacing of parent
      YGNodeStyleSetMargin(childNode, spacingEdge, child.spacingBefore + _style.spacing + savedSpacing);
    } else {
      // For the space between parent and first child we just use spacingBefore
      YGNodeStyleSetMargin(childNode, spacingEdge, child.spacingBefore);
    }
    YGNodeInsertChild(stackNode, childNode, YGNodeGetChildCount(stackNode));
    
    savedSpacing = child.spacingAfter;
    if (next(iterator) == children.end()) {
      // For the space between parent and last child we use only spacingAfter
      YGNodeStyleSetMargin(childNode, _style.direction == CKStackLayoutDirectionHorizontal ? YGEdgeEnd : YGEdgeBottom, savedSpacing);
    }
  }
  if (layoutCache) {
    *layoutCache = [newLayoutCache copy];
  }
  
  YGNodeStyleSetFlexDirection(stackNode, ygDirectionFromStackStyle(_style));
  YGNodeStyleSetJustifyContent(stackNode, ygJustifyFromStackStyle(_style));
  YGNodeStyleSetAlignItems(stackNode, ygAlignFromStackStyle(_style));
  YGNodeStyleSetFlexWrap(stackNode, ygWrapFromStackStyle(_style));
  
  // Parent can grow and shrink if children require so
  YGNodeStyleSetFlexGrow(stackNode, 1.0);
  YGNodeStyleSetFlexShrink(stackNode, 1.0);
  
  return stackNode;
}

- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
{
  // We create cache for the duration of single calculation, so it is used only on one thread
  // The cache is strictly internal and shouldn't be exposed in any way
  // The purpose of the cache is to save calculations done in measure() function in Yoga to reuse
  // for final layout
  NSArray<CKFlexboxChildCachedLayout *> *layoutCache = nil;
  YGNodeRef layoutNode = [self ygNode:constrainedSize cache:&layoutCache];
  
  YGNodeCalculateLayout(layoutNode, YGUndefined, YGUndefined, YGDirectionLTR);
  
  // Before we finalize layout we want to sort children according to their z-order
  // We want children with higher z-order to be closer to the end of list
  // They should be mounted later and thus shown on top of children with lower z-order  const NSInteger childCount = YGNodeGetChildCount(layoutNode);
  const NSInteger childCount = YGNodeGetChildCount(layoutNode);
  std::vector<YGNodeRef> sortedChildNodes(childCount);
  for (NSUInteger i = 0; i < childCount; i++) {
    sortedChildNodes[i] = YGNodeGetChild(layoutNode, i);
  }
  std::sort(sortedChildNodes.begin(), sortedChildNodes.end(),
            [] (YGNodeRef const& a, YGNodeRef const& b) {
              CKFlexboxChildCachedLayout *aCachedContext = (__bridge CKFlexboxChildCachedLayout *)YGNodeGetContext(a);
              CKFlexboxChildCachedLayout *bCachedContext = (__bridge CKFlexboxChildCachedLayout *)YGNodeGetContext(b);
              return aCachedContext.zIndex < bCachedContext.zIndex;
            });
  
  std::vector<CKComponentLayoutChild> childrenLayout(childCount);
  const float width = YGNodeLayoutGetWidth(layoutNode);
  const float height = YGNodeLayoutGetHeight(layoutNode);
  const CGSize size = {width, height};
  for (NSUInteger i = 0; i < childCount; i++) {
    // Get the layout for every child
    const YGNodeRef childNode = sortedChildNodes[i];
    const CGFloat childX = YGNodeLayoutGetLeft(childNode);
    const CGFloat childY = YGNodeLayoutGetTop(childNode);
    const CGFloat childWidth = YGNodeLayoutGetWidth(childNode);
    const CGFloat childHeight = YGNodeLayoutGetHeight(childNode);
    CKFlexboxChildCachedLayout *childCachedLayout = layoutCache[i];
    
    childrenLayout[i].position = CGPointMake(childX, childY);
    const CGSize childSize = CGSizeMake(childWidth, childHeight);
    // We cache measurements for the duration of single layout calculation of FlexboxComponent
    // ComponentKit and Yoga handle caching between calculations
    
    // We can reuse caching even if main dimension isn't exact, but we did AtMost measurement previously
    // However we might need to measure anew if child needs to be stretched
    YGMeasureMode verticalReusedMode = YGMeasureModeAtMost;
    YGMeasureMode horizontalReusedMode = YGMeasureModeAtMost;
    if (childCachedLayout.align == CKStackLayoutAlignSelfStretch ||
        (childCachedLayout.align == CKStackLayoutAlignSelfAuto && _style.alignItems == CKStackLayoutAlignItemsStretch)) {
      if (_style.direction == CKStackLayoutDirectionVertical) {
        horizontalReusedMode = YGMeasureModeExactly;
      } else {
        verticalReusedMode = YGMeasureModeExactly;
      }
    }
    
    if (YGNodeCanUseCachedMeasurement(verticalReusedMode, childWidth, horizontalReusedMode, childHeight,
                                      childCachedLayout.widthMode, childCachedLayout.width,
                                      childCachedLayout.heightMode, childCachedLayout.height,
                                      childCachedLayout.componentLayout.size.width,
                                      childCachedLayout.componentLayout.size.height, 0, 0) ||
        YGNodeCanUseCachedMeasurement(YGMeasureModeExactly, childWidth, YGMeasureModeExactly, childHeight,
                                      childCachedLayout.widthMode, childCachedLayout.width,
                                      childCachedLayout.heightMode, childCachedLayout.height,
                                      childCachedLayout.componentLayout.size.width, childCachedLayout.componentLayout.size.height, 0, 0) ||
        childSize.width == 0 ||
        childSize.height == 0) {
      childrenLayout[i].layout = childCachedLayout.componentLayout;
    } else {
      childrenLayout[i].layout = CKComputeComponentLayout(childCachedLayout.component, {childSize, childSize}, size);
    }
    childrenLayout[i].layout.size = childSize;
  }
  
  YGNodeFreeRecursive(layoutNode);
  
  // width/height should already be within constrainedSize, but we're just clamping to correct for roundoff error
  return {self, constrainedSize.clamp({width, height}), childrenLayout};
}

/*
 layoutCache is passed by reference so that we are able to allocate it in one thread
 and mutate it within that thread
 Layout cache shouldn't be exposed publicly
 */
- (YGNodeRef)ygNode:(CKSizeRange)constrainedSize cache:(NSArray<CKFlexboxChildCachedLayout *> **)layoutCache
{
  const YGNodeRef node = [self cssStackLayoutNode:constrainedSize cache:layoutCache];
  
  // At the moment Yoga does not optimise minWidth == maxWidth, so we want to do it here
  // ComponentKit and Yoga use different constants for +Inf, so we need to make sure the don't interfere
  if (constrainedSize.min.width == constrainedSize.max.width) {
    YGNodeStyleSetWidth(node, constrainedSize.min.width);
  } else {
    YGNodeStyleSetMinWidth(node, constrainedSize.min.width);
    if (constrainedSize.max.width == INFINITY) {
      YGNodeStyleSetMaxWidth(node, YGUndefined);
    } else {
      YGNodeStyleSetMaxWidth(node, constrainedSize.max.width);
    }
  }
  
  if (constrainedSize.min.height == constrainedSize.max.height) {
    YGNodeStyleSetHeight(node, constrainedSize.min.height);
  } else {
    YGNodeStyleSetMinHeight(node, constrainedSize.min.height);
    if (constrainedSize.max.height == INFINITY) {
      YGNodeStyleSetMaxHeight(node, YGUndefined);
    } else {
      YGNodeStyleSetMaxHeight(node, constrainedSize.max.height);
    }
  }
  return node;
}

@end
