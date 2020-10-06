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

#if swift(>=5.3)

public struct ViewLifecycleModifier<Inflatable : ComponentInflatable> : ComponentInflatable {
  enum Directive {
    case didInit(()  -> Void)
    case willMount(()  -> Void)
    case didUnmount(()  -> Void)
    case willDispose(()  -> Void)

    fileprivate func update(model: inout SwiftComponentModel.LifecycleCallbacks) {
      switch self {
      case let .didInit(callback):
        model.didInit.append(callback)
      case let .willMount(callback):
        model.willMount.append(callback)
      case let .didUnmount(callback):
        model.didUnmount.append(callback)
      case let .willDispose(callback):
        model.willDispose.append(callback)
      }
    }
  }

  let inflatable: Inflatable
  let directive: Directive

  // MARK: ComponentInflatable

  public func inflateComponent(with model: SwiftComponentModel?) -> Component {
    var model = model ?? SwiftComponentModel()
    directive.update(model: &model.lifecycleCallbacks)
    return inflatable.inflateComponent(with: model)
  }
}

extension ComponentInflatable {
  public func onDidInit(_ callback: @escaping () -> Void) -> ViewLifecycleModifier<Self> {
    ViewLifecycleModifier(inflatable: self, directive: .didInit(callback))
  }

  public func onWillMount(_ callback: @escaping () -> Void) -> ViewLifecycleModifier<Self> {
    ViewLifecycleModifier(inflatable: self, directive: .willMount(callback))
  }

  public func onDidUnmount(_ callback: @escaping () -> Void) -> ViewLifecycleModifier<Self> {
    ViewLifecycleModifier(inflatable: self, directive: .didUnmount(callback))
  }

  public func onWillDispose(_ callback: @escaping () -> Void) -> ViewLifecycleModifier<Self> {
    ViewLifecycleModifier(inflatable: self, directive: .willDispose(callback))
  }
}

#endif
