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

public struct Dimension: Hashable {
  let dimension: DimensionSwiftBridge

  public init() {
    dimension = DimensionSwiftBridge()
  }

  public init(points: CGFloat) {
    dimension = DimensionSwiftBridge(points: points)
  }

  public init(percent: CGFloat) {
    dimension = DimensionSwiftBridge(percent: percent)
  }
}

extension Dimension: CustomStringConvertible {
  public var description: String { return dimension.description }
}

extension Dimension: ExpressibleByFloatLiteral {
  public init(floatLiteral value: Double) {
    self.init(points: CGFloat(value))
  }
}

extension Dimension: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: Int) {
    self.init(points: CGFloat(value))
  }
}

// Re-export the type to avoid importing ComponentKit directly and ambiguities in type lookup
public typealias SizeRange = ComponentKit.SizeRange
public typealias Component = ComponentKit.Component
public typealias ComponentHostingView = ComponentKit.ComponentHostingView
public typealias ComponentHostingViewDelegate = ComponentKit.ComponentHostingViewDelegate

public struct ComponentSize: Hashable {
  let componentSize: ComponentSizeSwiftBridge

  public init(size: CGSize) {
    componentSize = ComponentSizeSwiftBridge(size: size)
  }

  public init(width: Dimension? = nil,
              height: Dimension? = nil,
              minWidth: Dimension? = nil,
              minHeight: Dimension? = nil,
              maxWidth: Dimension? = nil,
              maxHeight: Dimension? = nil) {
    componentSize = ComponentSizeSwiftBridge(width: width?.dimension,
                                             height: height?.dimension,
                                             minWidth: minWidth?.dimension,
                                             minHeight: minHeight?.dimension,
                                             maxWidth: maxWidth?.dimension,
                                             maxHeight: maxHeight?.dimension)
  }
}

extension ComponentSize: CustomStringConvertible {
  public var description: String { return componentSize.description }
}

private extension KeyPath where Root: NSObject {
  var asString: String {
    return NSExpression(forKeyPath: self).keyPath
  }
}

public struct LayerAttribute {
  let componentViewAttribute: ComponentViewAttributeSwiftBridge

  public init<Value>(_ keyPath: ReferenceWritableKeyPath<CALayer, Value>, _ value: Value) {
    componentViewAttribute = ComponentViewAttributeSwiftBridge(identifier: "layer" + keyPath.asString) { view in
      view.layer[keyPath: keyPath] = value
    }
  }
}

public struct ViewConfiguration {
  public struct Attribute<View: UIView> {
    let componentViewAttribute: ComponentViewAttributeSwiftBridge

    public init<Value>(_ keyPath: ReferenceWritableKeyPath<View, Value>, _ value: Value) {
      componentViewAttribute = ComponentViewAttributeSwiftBridge(identifier: keyPath.asString) { v in
        let view = v as! View
        view[keyPath: keyPath] = value
      }
    }
  }

  let viewConfiguration: ComponentViewConfigurationSwiftBridge

  public init<View: UIView>(viewClass: View.Type, attributes: [Attribute<View>], layerAttributes: [LayerAttribute] = []) {
    viewConfiguration = ComponentViewConfigurationSwiftBridge(viewClass: viewClass,
                                                              attributes: attributes.map { $0.componentViewAttribute } + layerAttributes.map { $0.componentViewAttribute })
  }
}

public extension Component {
  convenience init(view: ViewConfiguration, size: ComponentSize) {
    self.init(viewConfig: view.viewConfiguration, componentSize: size.componentSize)
  }
}
