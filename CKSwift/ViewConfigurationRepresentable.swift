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
import UIKit

#if swift(>=5.3)

// MARK: ViewConfigurationRepresentable

/// Can be represented with a `ViewConfiguration`.  By contract
/// the `ViewConfiguration` was built with attributes matching its view.
public protocol ViewConfigurationRepresentable {
  var viewConfiguration: ViewConfiguration { get }
}

/// Can be represented with `Attribute` / `LayerAttribute`.
public protocol ViewAttributeRepresentable : ViewConfigurationRepresentable {
  associatedtype UIViewType: UIView

  var attributes: [ViewConfiguration.Attribute<UIViewType>] { get }
  var layerAttributes: [ViewConfiguration.LayerAttribute] { get }
}

extension ViewAttributeRepresentable {
  public var viewConfiguration: ViewConfiguration {
    ViewConfiguration(
      viewClass: UIViewType.self,
      attributes: attributes,
      layerAttributes: layerAttributes
    )
  }
}

/// Can be represented and externally defined by `Attribute` / `LayerAttribute`. Use
/// for builder style extension below.
public protocol ViewAttributeAssignable : ViewAttributeRepresentable  {
  var attributes: [ViewConfiguration.Attribute<UIViewType>] { get set }
  var layerAttributes: [ViewConfiguration.LayerAttribute] { get set }
}

extension ViewAttributeAssignable where Self: ComponentInflatable {

  public func attributes<Value>(_ keyPath: ReferenceWritableKeyPath<UIViewType, Value>, _ value: Value) -> Self {
    var copy = self
    copy.attributes.append(ViewConfiguration.Attribute(keyPath, value))
    return copy
  }

  public func attribute<Value>(_ layerAttribute: ReferenceWritableKeyPath<CALayer, Value>, _ value: Value) -> Self {
    var copy = self
    copy.layerAttributes.append(ViewConfiguration.LayerAttribute(layerAttribute, value))
    return copy
  }

  // MARK: Attributes

  public func backgroundColor(_ value: UIColor?) -> Self {
    attributes(\.backgroundColor, value)
  }

  public func alpha(_ value: CGFloat) -> Self {
    attributes(\.alpha, value)
  }

  public func clipsToBounds(_ value: Bool) -> Self {
    attributes(\.clipsToBounds, value)
  }

  public func userInteractionEnabled(_ value: Bool) -> Self {
    attributes(\.isUserInteractionEnabled, value)
  }

  public func contentMode(_ value: UIView.ContentMode) -> Self {
    attributes(\.contentMode, value)
  }

  // MARK: Layer Attributes

  public func borderWidth(_ value: CGFloat) -> Self {
    attribute(\.borderWidth, value)
  }

  public func borderColor(_ value: CGColor?) -> Self {
    attribute(\.borderColor, value)
  }

  public func borderColor(_ value: UIColor?) -> Self {
    borderColor(value?.cgColor)
  }

  public func cornerRadius(_ value: CGFloat) -> Self {
    attribute(\.cornerRadius, value)
  }
}

#endif
