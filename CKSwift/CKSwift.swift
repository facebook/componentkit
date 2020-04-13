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
  let dimension: ComponentKit.Dimension

  public init() {
    dimension = ComponentKit.Dimension()
  }

  public init(points: CGFloat) {
    dimension = ComponentKit.Dimension(points: points)
  }

  public init(percent: CGFloat) {
    dimension = ComponentKit.Dimension(percent: percent)
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
  let componentSize: ComponentKit.ComponentSize

  public init(size: CGSize) {
    componentSize = ComponentKit.ComponentSize(size: size)
  }

  public init(width: Dimension = Dimension(),
              height: Dimension = Dimension(),
              minWidth: Dimension = Dimension(),
              minHeight: Dimension = Dimension(),
              maxWidth: Dimension = Dimension(),
              maxHeight: Dimension = Dimension()) {
    componentSize = ComponentKit.ComponentSize(width: width.dimension,
                                               height: height.dimension,
                                               minWidth: minWidth.dimension,
                                               minHeight: minHeight.dimension,
                                               maxWidth: maxWidth.dimension,
                                               maxHeight: maxHeight.dimension)
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
  let componentViewAttribute: ComponentViewAttribute

  public init<Value>(_ keyPath: ReferenceWritableKeyPath<CALayer, Value>, _ value: Value) {
    componentViewAttribute = ComponentViewAttribute(identifier: "layer" + keyPath.asString) { view in
      view.layer[keyPath: keyPath] = value
    }
  }
}

public struct ViewConfiguration<View: UIView> {
  public struct Attribute {
    let componentViewAttribute: ComponentViewAttribute

    public init<Value>(_ keyPath: ReferenceWritableKeyPath<View, Value>, _ value: Value) {
      componentViewAttribute = ComponentViewAttribute(identifier: keyPath.asString) { v in
        let view = v as! View
        view[keyPath: keyPath] = value
      }
    }
  }

  let viewConfiguration: ComponentKit.ComponentViewConfiguration

  public init(viewClass: View.Type, attributes: [Attribute], layerAttributes: [LayerAttribute] = []) {
    viewConfiguration = ComponentViewConfiguration(viewClass: viewClass,
                                                   attributes: attributes.map { $0.componentViewAttribute } + layerAttributes.map { $0.componentViewAttribute })
  }
}

public extension Component {
  convenience init<View: UIView>(view: ViewConfiguration<View>, size: ComponentSize) {
    self.init(viewConfig: view.viewConfiguration, componentSize: size.componentSize)
  }
}
