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
import UIKit

#if swift(>=5.3)

public extension ViewConfiguration.Attribute {

  /// Creates a view configuration attribute linked to tap gesture recognizer.
  /// - Parameter tapHandler: The closure to execute when the gesture fires.
  init(tapHandler: @escaping (UIGestureRecognizer) -> Void) {
    self.init(componentViewAttribute: .init(gesture: .tap, handler: tapHandler))
  }

  /// Creates a view configuration attribute linked to pan gesture recognizer.
  /// - Parameter panHandler: The closure to execute when the gesture fires.
  init(panHandler: @escaping (UIGestureRecognizer) -> Void) {
    self.init(componentViewAttribute: .init(gesture: .pan, handler: panHandler))
  }

  /// Creates a view configuration attribute linked to long press gesture recognizer.
  /// - Parameter longPressHandler: The closure to execute when the gesture fires.
  init(longPressHandler: @escaping (UIGestureRecognizer) -> Void) {
    self.init(componentViewAttribute: .init(gesture: .longPress, handler: longPressHandler))
  }
}

extension ViewAttributeAssignable where Self: ComponentInflatable {

  public func tapHandler(_ value: @escaping (UIGestureRecognizer) -> Void) -> Self {
    var copy = self
    copy.attributes.append(ViewConfiguration.Attribute(tapHandler: value))
    return copy
  }

  public func panHandler(_ value: @escaping (UIGestureRecognizer) -> Void) -> Self {
    var copy = self
    copy.attributes.append(ViewConfiguration.Attribute(panHandler: value))
    return copy
  }

  public func longPressHandler(_ value: @escaping (UIGestureRecognizer) -> Void) -> Self {
    var copy = self
    copy.attributes.append(ViewConfiguration.Attribute(longPressHandler: value))
    return copy
  }
}

#endif
