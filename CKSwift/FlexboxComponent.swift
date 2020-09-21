/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

import ComponentKit
import UIKit

public extension FlexboxComponent.Child {
  convenience init(
    spacingBefore: CGFloat = 0,
    spacingAfter: CGFloat = 0,
    flexGrow: CGFloat = 0,
    flexShrink: CGFloat = 0,
    alignSelf: AlignSelf = .auto,
    flexBasis: Dimension? = nil,
    zIndex: NSInteger = 0,
    sizeConstraints: ComponentSize? = nil,
    useTextRounding: Bool = false,
    useHeightAsBaseline: Bool = false,
    component: Component?) {
    self.init(
      __component: component,
      spacingBefore: spacingBefore,
      spacingAfter: spacingAfter,
      flexGrow: flexGrow,
      flexShrink: flexShrink,
      swiftFlexBasis: flexBasis?.dimension,
      alignSelf: alignSelf,
      zIndex: zIndex,
      sizeConstraints: sizeConstraints?.componentSize,
      useTextRounding: useTextRounding,
      useHeightAsBaseline: useHeightAsBaseline)
  }
}

public extension FlexboxComponent.Style {
  convenience init(
    direction: Direction = .column,
    spacing: CGFloat = 0,
    justifyContent: JustifyContent = .start,
    alignItems: AlignItems = .stretch,
    alignContent: AlignContent = .start,
    wrap: Wrap = .noWrap,
    layoutDirection: LayoutDirection = .applicationDirection,
    useDeepYogaTrees: Bool = false) {
    self.init(
      __direction: direction,
      spacing: spacing,
      justifyContent: justifyContent,
      alignItems: alignItems,
      alignContent: alignContent,
      wrap: wrap,
      layoutDirection: layoutDirection,
      useDeepYogaTrees: useDeepYogaTrees
    )
  }
}

#if swift(>=5.1)
@_functionBuilder
public struct FlexboxChildBuilder {
  public static func buildBlock(_ partialResults: FlexboxComponent.Child?...) -> [FlexboxComponent.Child] {
    return partialResults.compactMap { $0 }
  }

  public static func buildExpression(_ child: FlexboxComponent.Child) -> FlexboxComponent.Child {
    child
  }

  public static func buildEither(first: FlexboxComponent.Child) -> FlexboxComponent.Child {
    first
  }

  public static func buildEither(second: FlexboxComponent.Child) -> FlexboxComponent.Child {
    second
  }

  public static func buildOptional(_ child: FlexboxComponent.Child??) -> FlexboxComponent.Child? {
    child?.flatMap { $0 }
  }
}
#endif

public extension FlexboxComponent {
#if swift(>=5.1)
  convenience init(
    view: ViewConfiguration? = nil,
    direction: Style.Direction = .column,
    spacing: CGFloat = 0,
    justifyContent: Style.JustifyContent = .start,
    alignItems: Style.AlignItems = .stretch,
    alignContent: Style.AlignContent = .start,
    wrap: Style.Wrap = .noWrap,
    layoutDirection: Style.LayoutDirection = .applicationDirection,
    useDeepYogaTrees: Bool = false,
    size: ComponentSize? = nil,
    @FlexboxChildBuilder children: () -> [FlexboxComponent.Child]
  ) {
    self.init(
      __swiftView: view?.viewConfiguration,
      swiftStyle: Style(
        direction: direction,
        spacing: spacing,
        justifyContent: justifyContent,
        alignItems: alignItems,
        alignContent: alignContent,
        wrap: wrap,
        layoutDirection: layoutDirection,
        useDeepYogaTrees: useDeepYogaTrees),
      swiftSize: size?.componentSize,
      swiftChildren: children()
    )
  }

  // Overload for single value. Fixed in Xcode 12
  // https://twitter.com/dgregor79/status/1258412048934768641
  convenience init(
    view: ViewConfiguration? = nil,
    direction: Style.Direction = .column,
    spacing: CGFloat = 0,
    justifyContent: Style.JustifyContent = .start,
    alignItems: Style.AlignItems = .stretch,
    alignContent: Style.AlignContent = .start,
    wrap: Style.Wrap = .noWrap,
    layoutDirection: Style.LayoutDirection = .applicationDirection,
    useDeepYogaTrees: Bool = false,
    size: ComponentSize? = nil,
    @FlexboxChildBuilder children: () -> FlexboxComponent.Child
  ) {
    self.init(
      __swiftView: view?.viewConfiguration,
      swiftStyle: Style(
        direction: direction,
        spacing: spacing,
        justifyContent: justifyContent,
        alignItems: alignItems,
        alignContent: alignContent,
        wrap: wrap,
        layoutDirection: layoutDirection,
        useDeepYogaTrees: useDeepYogaTrees),
      swiftSize: size?.componentSize,
      swiftChildren: [children()]
    )
  }

  // Overload for single value. Fixed in Xcode 12
  // https://twitter.com/dgregor79/status/1258412048934768641
  convenience init(
    view: ViewConfiguration? = nil,
    direction: Style.Direction = .column,
    spacing: CGFloat = 0,
    justifyContent: Style.JustifyContent = .start,
    alignItems: Style.AlignItems = .stretch,
    alignContent: Style.AlignContent = .start,
    wrap: Style.Wrap = .noWrap,
    layoutDirection: Style.LayoutDirection = .applicationDirection,
    useDeepYogaTrees: Bool = false,
    size: ComponentSize? = nil,
    @FlexboxChildBuilder child: () -> Component
  ) {
    self.init(
      __swiftView: view?.viewConfiguration,
      swiftStyle: Style(
        direction: direction,
        spacing: spacing,
        justifyContent: justifyContent,
        alignItems: alignItems,
        alignContent: alignContent,
        wrap: wrap,
        layoutDirection: layoutDirection,
        useDeepYogaTrees: useDeepYogaTrees),
      swiftSize: size?.componentSize,
      swiftChildren: [FlexboxComponent.Child(component: child())]
    )
  }
#endif
}
