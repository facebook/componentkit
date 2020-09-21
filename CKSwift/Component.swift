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
