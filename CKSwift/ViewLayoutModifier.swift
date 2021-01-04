/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

import Foundation
import ComponentKit

#if swift(>=5.3)

typealias ViewLayoutCenteringOptions = CenterLayoutComponent.CenteringOptions
typealias ViewLayoutCenteringSizingOptions = CenterLayoutComponent.SizingOptions

public struct ViewLayoutModifier<Inflatable: ComponentInflatable> : ComponentInflatable {
  enum Directive {
    case frame(ComponentSize)
    case padding(UIEdgeInsets)
    case ratio(CGFloat)
    case center(centeringOptions: ViewLayoutCenteringOptions, sizingOptions: ViewLayoutCenteringSizingOptions)
    case background(() -> Component)
    case overlay(() -> Component)

    fileprivate func build(_ content: Component) -> Component {
      switch self {
      case let .frame(size):
        return SizingComponent(swiftSize: size.componentSize, component: content)
      case let .padding(insets):
        return InsetComponent(swiftView: nil, insets: insets, component: content)
      case let .ratio(ratio):
        return RatioLayoutComponent(ratio: ratio, swiftSize: nil, component: content)
      case let .center(centeringOptions, sizingOptions):
        return CenterLayoutComponent(centeringOptions: centeringOptions,
                                     sizingOptions: sizingOptions,
                                     child: content,
                                     swiftSize: nil)
      case let .background(background):
        return BackgroundLayoutComponent(component: content, background: background())
      case let .overlay(overlay):
        return OverlayLayoutComponent(component: content, overlay: overlay())
      }
    }
  }

  let inflatable: Inflatable
  let directive: Directive

  // MARK: ComponentInflatable

  public func inflateComponent(with model: SwiftComponentModel?) -> Component {
    let inflatedTarget = inflatable.inflateComponent(with: nil)
    return directive.build(inflatedTarget)
      .inflateComponent(with: model)
  }
}

extension ComponentInflatable {

  public func frame(width: CGFloat? = nil,
                    height: CGFloat? = nil,
                    minWidth: CGFloat? = nil,
                    minHeight: CGFloat? = nil,
                    maxWidth: CGFloat? = nil,
                    maxHeight: CGFloat? = nil) -> ViewLayoutModifier<Self> {
    ViewLayoutModifier(
      inflatable: self,
      directive: .frame(
        ComponentSize(
          width: width.map { .points($0) },
          height: height.map { .points($0) },
          minWidth: minWidth.map { .points($0) },
          minHeight: minHeight.map { .points($0) },
          maxWidth: maxWidth.map { .points($0) },
          maxHeight: maxHeight.map { .points($0) })
      )
    )
  }

  public func relativeFrame(width: CGFloat? = nil,
                            height: CGFloat? = nil,
                            minWidth: CGFloat? = nil,
                            minHeight: CGFloat? = nil,
                            maxWidth: CGFloat? = nil,
                            maxHeight: CGFloat? = nil) -> ViewLayoutModifier<Self> {
    ViewLayoutModifier(
      inflatable: self,
      directive: .frame(
        ComponentSize(
          width: width.map { .percent($0) },
          height: height.map { .percent($0) },
          minWidth: minWidth.map { .percent($0) },
          minHeight: minHeight.map { .percent($0) },
          maxWidth: maxWidth.map { .percent($0) },
          maxHeight: maxHeight.map { .percent($0) })
      )
    )
  }

  public func overlay(@ComponentBuilder _ overlay: @escaping () -> Component) -> ViewLayoutModifier<Self> {
    ViewLayoutModifier(inflatable: self, directive: .overlay(overlay))
  }

  public func background(@ComponentBuilder _ background: @escaping () -> Component) -> ViewLayoutModifier<Self> {
    ViewLayoutModifier(inflatable: self, directive: .background(background))
  }

  // TODO: CenterLayoutComponent options shouldn't leak
  public func center(centeringOptions: CenterLayoutComponent.CenteringOptions = [],
                     sizingOptions: CenterLayoutComponent.SizingOptions = []) -> ViewLayoutModifier<Self> {
    ViewLayoutModifier(inflatable: self, directive: .center(centeringOptions: centeringOptions, sizingOptions: sizingOptions))
  }

  public func ratio(_ ratio: CGFloat) -> ViewLayoutModifier<Self> {
    ViewLayoutModifier(inflatable: self, directive: .ratio(ratio))
  }

  public func padding(top: CGFloat? = nil,
                      left: CGFloat? = nil,
                      bottom: CGFloat? = nil,
                      right: CGFloat? = nil) -> ViewLayoutModifier<Self> {
    // TODO: nil should represent `default` and be contextual instead of `0`
    ViewLayoutModifier(
      inflatable: self,
      directive: .padding(
        UIEdgeInsets(
          top: top ?? 0,
          left: left ?? 0,
          bottom: bottom ?? 0,
          right: right ?? 0)
      )
    )
  }

  // TODO: Padding with Edge set API

  public func padding(_ length: CGFloat?) -> ViewLayoutModifier<Self> {
    padding(top: length, left: length, bottom: length, right: length)
  }
}

#endif
