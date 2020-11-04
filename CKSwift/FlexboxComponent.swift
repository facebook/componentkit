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

#if swift(>=5.3)

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
    @ComponentBuilder component: () -> Component?) {
    self.init(
      __component: component(),
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

@_functionBuilder
public struct FlexboxChildrenBuilder {
  public static func buildExpression(_ child: FlexboxComponent.Child) -> FlexboxComponent.Child {
    child
  }

  public static func buildExpression<C: Sequence>(_ collection: C) -> [FlexboxComponent.Child] where C.Element == FlexboxComponent.Child {
    Array(collection)
  }

  public static func buildExpression<C : Sequence, Inflatable: ComponentInflatable>(_ collection: C) -> [FlexboxComponent.Child] where C.Element == Inflatable {
    collection.map { inflatable in
      FlexboxComponent.Child {
        inflatable
      }
    }
  }

  public static func buildExpression<Inflatable : ComponentInflatable>(_ inflatable: Inflatable) -> FlexboxComponent.Child {
    FlexboxComponent.Child {
      inflatable
    }
  }

  public static func buildBlock<C: Sequence>(_ children: C...) -> [FlexboxComponent.Child] where C.Element == FlexboxComponent.Child {
    children.flatMap { $0 }
  }

  public static func buildBlock(_ children: FlexboxComponent.Child...) -> [FlexboxComponent.Child] {
    children
  }

  public static func buildOptional(_ children: [FlexboxComponent.Child]?) -> [FlexboxComponent.Child] {
    children.map {
      Array($0)
    } ?? []
  }

  public static func buildEither<C: Sequence>(first collection: C) -> [FlexboxComponent.Child] where C.Element == FlexboxComponent.Child {
    Array(collection)
  }

  public static func buildEither<C: Sequence>(second collection: C) -> [FlexboxComponent.Child] where C.Element == FlexboxComponent.Child {
    Array(collection)
  }

  public static func buildLimitedAvailability<C: Sequence>(_ collection: C) -> [FlexboxComponent.Child] where C.Element == FlexboxComponent.Child {
    Array(collection)
  }

  public static func buildDo<C: Sequence>(_ collection: C) -> [FlexboxComponent.Child] where C.Element == FlexboxComponent.Child {
    Array(collection)
  }
}

public extension FlexboxComponent {
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
    @FlexboxChildrenBuilder childrenBuilder: () -> [FlexboxComponent.Child]
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
      swiftChildren: childrenBuilder()
    )
  }
}

#endif
