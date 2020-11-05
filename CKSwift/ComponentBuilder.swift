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

/// Marker component for render-to-nil scenarios.
class EmptyComponent : Component {
  private init() {
    super.init(__swiftView: nil, swiftSize: nil)
  }

  static let shared = EmptyComponent()
}

// MARK: ComponentBuilder

@_functionBuilder
public struct ComponentBuilder {
  // TODO: buildDo

  public static func buildBlock(_ component: Component) -> Component {
    component
  }

  public static func buildExpression(_ inflatable: ComponentInflatable) -> Component {
    inflatable.inflateComponent(with: nil)
  }

  public static func buildEither(first: Component) -> Component {
    first
  }

  public static func buildEither(second: Component) -> Component {
    second
  }

  public static func buildOptional(_ component: Component?) -> Component {
    component ?? EmptyComponent.shared
  }
}

#endif
