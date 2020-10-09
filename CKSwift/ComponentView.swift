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

// MARK: ComponentView

/// `ComponentView` is the `View` based `Component` primitive. Will become a leaf component.
/// As opposed to `Component`, it has the benefit to being a value type.
public struct ComponentView<UIViewType: UIView> : View, ViewAttributeAssignable {
  public init() { }

  public typealias AttributeBuilder = ViewConfigurationAttributeBuilder<UIViewType>
  public init(@AttributeBuilder attributes: () -> [AttributeBuilder.Directive]) {
    consume(attributes)
  }

  // MARK: ViewAttributeAssignable

  public var attributes: [ViewConfiguration.Attribute<UIViewType>] = []
  public var layerAttributes: [ViewConfiguration.LayerAttribute] = []

  // MARK: ComponentInflatable

  public func inflateComponent(with model: SwiftComponentModel?) -> Component {
    if let model = model, model.isEmpty == false {
      return CKSwiftComponent(
        swiftView: viewConfiguration.viewConfiguration,
        swiftSize: nil,
        child: nil,
        model: model.toSwiftBridge()
      )
    } else {
      return Component(view: viewConfiguration)
    }
  }
}

/// `WrapperComponentView` is the `View` based `CompositeComponent` primitive.
/// As opposed to `CompositeComponent`, it has the benefit to being a value type.
public struct WrapperComponentView<UIViewType: UIView> : View, ViewAttributeAssignable {
  let component: () -> Component

  public typealias AttributeBuilder = ViewConfigurationAttributeBuilder<UIViewType>
  public init(
    @AttributeBuilder attributes: () -> [AttributeBuilder.Directive],
    @ComponentBuilder component: @escaping () -> Component) {
    self.component = component
    consume(attributes)
  }

  // MARK: ViewAttributeAssignable

  public var attributes: [ViewConfiguration.Attribute<UIViewType>] = []
  public var layerAttributes: [ViewConfiguration.LayerAttribute] = []

  // MARK: ComponentInflatable

  public func inflateComponent(with model: SwiftComponentModel?) -> Component {
    if let model = model, model.isEmpty == false {
      return CKSwiftComponent(
        swiftView: viewConfiguration.viewConfiguration,
        swiftSize: nil,
        child: self.component(),
        model: model.toSwiftBridge()
      )
    } else {
      return CompositeComponent(
        view: viewConfiguration,
        component: self.component())
    }
  }
}

fileprivate extension ViewAttributeAssignable {
  mutating func consume(_ attributes: () -> [ViewConfigurationAttributeBuilder<UIViewType>.Directive]) {
    attributes()
      .forEach {
        switch $0 {
        case let .attribute(attribute):
          self.attributes.append(attribute)
        case let .layerAttribute(attribute):
          self.layerAttributes.append(attribute)
        }
    }
  }
}

#endif
