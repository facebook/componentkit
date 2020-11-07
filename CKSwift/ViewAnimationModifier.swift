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

public struct ViewAnimationModifier<Inflatable : ComponentInflatable> : ComponentInflatable {
  enum Directive {
    case initialMount(CAAnimation?)
    case finalUnmount(CAAnimation?)

    fileprivate func update(model: inout SwiftComponentModel.Animations) {
      switch self {
      case let .initialMount(animation?):
        model.initialMount.append(animation)
      case let .finalUnmount(animation?):
        model.finalUnmount.append(animation)
      default:
        break
      }
    }
  }

  let inflatable: Inflatable
  let directive: Directive

  // MARK: ComponentInflatable

  public func inflateComponent(with model: SwiftComponentModel?) -> Component {
    var model = model ?? SwiftComponentModel()
    directive.update(model: &model.animations)
    return inflatable.inflateComponent(with: model)
  }
}

extension ComponentInflatable {
  public func onInitialMount(_ animation: CAAnimation?) -> ViewAnimationModifier<Self> {
    ViewAnimationModifier(inflatable: self, directive: .initialMount(animation))
  }

  public func onFinalUnmount(_ animation: CAAnimation?) -> ViewAnimationModifier<Self> {
    ViewAnimationModifier(inflatable: self, directive: .finalUnmount(animation))
  }
}

#endif
