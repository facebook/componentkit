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
