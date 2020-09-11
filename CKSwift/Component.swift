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

// MARK: - CKComponent

public extension Component {
  /// Creates a new component.
  /// - Parameters:
  ///   - view: The view configuration to be used by the component.
  ///   - size: The size to be used by the component.
  convenience init(view: ViewConfiguration? = nil, size: ComponentSize? = nil) {
    self.init(__swiftView: view?.viewConfiguration, swiftSize: size?.componentSize)
  }
}

// MARK: - CKCompositeComponent

public extension CompositeComponent {
  /// Create a new composite component.
  /// - Parameters:
  ///   - view: The view configuration to be used by the component.
  ///   - component: The component to wrap.
  convenience init(view: ViewConfiguration? = nil, component: Mountable) {
    self.init(__swiftView: view?.viewConfiguration, component: component)
  }

  /// Creates a new composite component, conditionally.
  /// - Parameters:
  ///   - view: The view configuration to be used by the component.
  ///   - component: The optional component to wrap.
  convenience init?(view: ViewConfiguration? = nil, component: Mountable?) {
    guard let component = component else { return nil }
    self.init(__swiftView: view?.viewConfiguration, component: component)
  }
}

// MARK: InsetComponent

public extension InsetComponent {
  /// Creates a new inset component.
  /// - Parameters:
  ///   - insets: The inset to use for `component`
  ///   - view: The view configuration to be used by the component.
  ///   - component: The component to inset.
  convenience init(
    insets: UIEdgeInsets,
    view: ViewConfiguration? = nil,
    component: Component) {
    self.init(
      __swiftView: view?.viewConfiguration,
      insets: insets,
      component: component
    )
  }

  /// Creates a new inset component, conditionally.
  /// - Parameters:
  ///   - insets: The inset to use for `component`
  ///   - view: The view configuration to be used by the component.
  ///   - component: The optional component to inset.
  convenience init?(
    insets: UIEdgeInsets,
    view: ViewConfiguration? = nil,
    component: Component?) {
    guard let component = component else { return nil }
    self.init(
      __swiftView: view?.viewConfiguration,
      insets: insets,
      component: component
    )
  }
}

// MARK: CenterLayoutComponent

public extension CenterLayoutComponent {
  /// Creates a new center layout component.
  /// - Parameters:
  ///   - centeringOptions: The centering options to use.
  ///   - sizingOptions: The sizing options to use.
  ///   - size: The size to use.
  ///   - component: The component to centre.
  convenience init(
    centeringOptions: CenteringOptions = [],
    sizingOptions: SizingOptions = [],
    size: ComponentSize? = nil,
    component: Component) {
    self.init(
      __centeringOptions: centeringOptions,
      sizingOptions: sizingOptions,
      child: component,
      swiftSize: size?.componentSize
    )
  }

  /// Creates a new center layout component, conditionally.
  /// - Parameters:
  ///   - centeringOptions: The centering options to use.
  ///   - sizingOptions: The sizing options to use.
  ///   - size: The size to use.
  ///   - component: The optional component to centre.
  convenience init?(
    centeringOptions: CenteringOptions = [],
    sizingOptions: SizingOptions = [],
    size: ComponentSize? = nil,
    component: Component?) {
    guard let component = component else { return nil }
    self.init(
      __centeringOptions: centeringOptions,
      sizingOptions: sizingOptions,
      child: component,
      swiftSize: size?.componentSize
    )
  }
}

// MARK: CKRatioLayoutComponent

public extension RatioLayoutComponent {
  /// Creates a new ratio layout component.
  /// - Parameters:
  ///   - ratio: The ratio to use. If smaller or equal to 0, 1 will be used instead.
  ///   - size: The size to use.
  ///   - component: The component to layout.
  convenience init(
    ratio: CGFloat,
    size: ComponentSize? = nil,
    component: Component) {
    self.init(
      __ratio: ratio,
      swiftSize: size?.componentSize,
      component: component)
  }

  /// Creates a new ratio layout component, conditionally.
  /// - Parameters:
  ///   - ratio: The ratio to use. If smaller or equal to 0, 1 will be used instead.
  ///   - size: The size to use.
  ///   - component: The optional component to layout.
  convenience init?(
    ratio: CGFloat,
    size: ComponentSize? = nil,
    component: Component?) {
    guard let component = component else { return nil }
    self.init(
      __ratio: ratio,
      swiftSize: size?.componentSize,
      component: component)
  }
}


// MARK: FlexboxComponent

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

  public static func buildExpression(_ component: Component?) -> FlexboxComponent.Child? {
    component.flatMap {
      FlexboxComponent.Child(component: $0)
    }
  }

  public static func buildExpression(_ component: FlexboxComponent.Child?) -> FlexboxComponent.Child? {
    component
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
    @FlexboxChildBuilder children: () -> Component
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
      swiftChildren: [FlexboxComponent.Child(component: children())]
    )
  }
#endif
}
