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

private extension KeyPath where Root: NSObject {
  var asString: String {
    return NSExpression(forKeyPath: self).keyPath
  }
}

/// Represents the class of a view and the attributes that should be applied to it.
public struct ViewConfiguration {
  /// Represents a view configuration attribute.
  public struct Attribute<View: UIView> {
    /// The Objective-C bridgeable type.
    let componentViewAttribute: ComponentViewAttributeSwiftBridge

    /// Creates a new attribute.
    /// - Parameters:
    ///   - keyPath: The keypath where the value should be stored.
    ///   - value: The value to store.
    public init<Value>(_ keyPath: ReferenceWritableKeyPath<View, Value>, _ value: Value) {
      componentViewAttribute = ComponentViewAttributeSwiftBridge(identifier: keyPath.asString) { v in
        let view = v as! View
        view[keyPath: keyPath] = value
      }
    }

    /// Creates a new attribute
    /// - Parameter componentViewAttribute: The bridged view attribute.
    init(componentViewAttribute: ComponentViewAttributeSwiftBridge) {
      self.componentViewAttribute = componentViewAttribute
    }
  }

  /// Represents a view configuration layer attribute.
  public struct LayerAttribute {
    /// The Objective-C bridgeable type.
    let componentViewAttribute: ComponentViewAttributeSwiftBridge

    /// Creates a new layer attribute.
    /// - Parameters:
    ///   - keyPath: The keypath where the value should be stored.
    ///   - value: The value to store.
    public init<Value>(_ keyPath: ReferenceWritableKeyPath<CALayer, Value>, _ value: Value) {
      componentViewAttribute = ComponentViewAttributeSwiftBridge(identifier: "layer" + keyPath.asString) { view in
        view.layer[keyPath: keyPath] = value
      }
    }
  }

  /// The Objective-C bridgeable type.
  let viewConfiguration: ComponentViewConfigurationSwiftBridge

  /// Creates a new configuration.
  /// - Parameters:
  ///   - viewClass: The view class to use.
  ///   - attributes: The view attributes.
  ///   - layerAttributes: The layer attribues.
  public init<View: UIView>(viewClass: View.Type, attributes: [Attribute<View>] = [], layerAttributes: [LayerAttribute] = []) {
    viewConfiguration = ComponentViewConfigurationSwiftBridge(viewClass: viewClass,
                                                              attributes: attributes.map { $0.componentViewAttribute } + layerAttributes.map { $0.componentViewAttribute })
  }

#if swift(>=5.1)
  /// Creates a new configuration.
  /// - Parameters:
  ///   - viewClass: The view class to use.
  ///   - attributes: The view/layer attributes.
  public init<View: UIView>(viewClass: View.Type, @ViewConfigurationAttributeBuilder<View> attributes: () -> [ComponentViewAttributeSwiftBridge]) {
    viewConfiguration = ComponentViewConfigurationSwiftBridge(viewClass: viewClass, attributes: attributes())
  }
#endif
}

#if swift(>=5.1)
@_functionBuilder
public struct ViewConfigurationAttributeBuilder<View: UIView> {
  public enum Directive {
    case attribute(ViewConfiguration.Attribute<View>)
    case layerAttribute(ViewConfiguration.LayerAttribute)

    fileprivate var swiftBridge: ComponentViewAttributeSwiftBridge {
      switch self {
      case let .attribute(attribute):
        return attribute.componentViewAttribute
      case let .layerAttribute(attribute):
        return attribute.componentViewAttribute
      }
    }
  }

  #if swift(<5.3)
  public static func buildBlock(_ parts: Directive...) -> [ComponentViewAttributeSwiftBridge] {
    parts.map { $0.swiftBridge }
  }
  #endif

  public static func buildBlock(_ parts: Directive...) -> [Directive] {
    parts
  }

  public static func buildFinalResult(_ parts: [Directive]) -> [Directive] {
    parts
  }

  public static func buildFinalResult(_ parts: [Directive]) -> [ComponentViewAttributeSwiftBridge] {
    parts.map { $0.swiftBridge }
  }

  public static func buildExpression(_ attr: ViewConfiguration.Attribute<View>) -> Directive {
    .attribute(attr)
  }

  public static func buildExpression(_ attr: ViewConfiguration.LayerAttribute) -> Directive {
    .layerAttribute(attr)
  }

  public static func buildExpression<Value>(_ attr: (key: ReferenceWritableKeyPath<View, Value>, value: Value)) -> Directive {
    .attribute(ViewConfiguration.Attribute<View>(attr.key, attr.value))
  }

  public static func buildExpression<Value>(_ attr: (key: ReferenceWritableKeyPath<CALayer, Value>, value: Value)) -> Directive {
    .layerAttribute(ViewConfiguration.LayerAttribute(attr.key, attr.value))
  }
}

#endif
