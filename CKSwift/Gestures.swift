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
import ComponentKit

#if swift(>=5.3)

extension ViewConfiguration.Attribute {
  /// Creates a view configuration attribute linked to tap gesture recognizer.
  /// - Parameter tapAction: Action to invoke when the gesture fires..
  init(gesture: ComponentViewAttributeSwiftBridge.Gesture, action: ActionWith<UIGestureRecognizer>) {
    self.init(componentViewAttribute: ComponentViewAttributeSwiftBridge(gesture: gesture, swiftAction: action.swiftBridgeWithType))
  }
}

public struct TapAction {
  let action: ActionWith<UIGestureRecognizer>
}

public struct PanAction {
  let action: ActionWith<UIGestureRecognizer>
}

public struct LongPressAction {
  let action: ActionWith<UIGestureRecognizer>
}

extension View where Self: Actionable {
  public func onTap(_ handler: @escaping (Self, UIGestureRecognizer) -> Void) -> TapAction {
    TapAction(action: onAction(handler))
  }

  public func onTap(_ handler: @escaping (Self) -> (UIGestureRecognizer) -> Void) -> TapAction {
    TapAction(action: onAction(handler))
  }

  public func onPan(_ handler: @escaping (Self, UIGestureRecognizer) -> Void) -> PanAction {
    PanAction(action: onAction(handler))
  }

  public func onPan(_ handler: @escaping (Self) -> (UIGestureRecognizer) -> Void) -> PanAction {
    PanAction(action: onAction(handler))
  }

  public func onLongPress(_ handler: @escaping (Self, UIGestureRecognizer) -> Void) -> LongPressAction {
    LongPressAction(action: onAction(handler))
  }

  public func onLongPress(_ handler: @escaping (Self) -> (UIGestureRecognizer) -> Void) -> LongPressAction {
    LongPressAction(action: onAction(handler))
  }
}

public extension ViewConfigurationAttributeBuilder {
  static func buildExpression(_ tapAction: TapAction) -> Directive {
    buildExpression(ViewConfiguration.Attribute<View>(gesture: .tap, action: tapAction.action))
  }

  static func buildExpression(_ panAction: PanAction) -> Directive {
    buildExpression(ViewConfiguration.Attribute<View>(gesture: .pan, action: panAction.action))
  }

  static func buildExpression(_ longPressAction: LongPressAction) -> Directive {
    buildExpression(ViewConfiguration.Attribute<View>(gesture: .longPress, action: longPressAction.action))
  }
}

extension ViewAttributeAssignable where Self: ComponentInflatable {

  public func action(_ tapAction: TapAction) -> Self {
    var copy = self
    copy.attributes.append(ViewConfiguration.Attribute(gesture: .tap, action: tapAction.action))
    return copy
  }

  public func action(_ panAction: PanAction) -> Self {
    var copy = self
    copy.attributes.append(ViewConfiguration.Attribute(gesture: .pan, action: panAction.action))
    return copy
  }

  public func action(_ longPressAction: LongPressAction) -> Self {
    var copy = self
    copy.attributes.append(ViewConfiguration.Attribute(gesture: .longPress, action: longPressAction.action))
    return copy
  }
}

#endif
