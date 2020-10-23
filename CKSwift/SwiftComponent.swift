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

#if swift(>=5.3)

public struct SwiftComponentModel {
  struct LifecycleCallbacks {
    typealias Callback = @convention(block) () -> Void

    var didInit: [Callback] = []
    var willMount: [Callback] = []
    var didUnmount: [Callback] = []
    var willDispose: [Callback] = []

    var isEmpty: Bool {
      didUnmount.isEmpty && willMount.isEmpty && didUnmount.isEmpty && willDispose.isEmpty
    }
  }

  struct Animations {
    var animations: [CAAnimation] = []
    var initialMount: [CAAnimation] = []
    var finalUnmount: [CAAnimation] = []

    var isEmpty: Bool {
      animations.isEmpty && initialMount.isEmpty && finalUnmount.isEmpty
    }
  }

  func toSwiftBridge() -> SwiftComponentModelSwiftBridge? {
    guard isEmpty == false else { return nil }
    return SwiftComponentModelSwiftBridge(
      animation: animations.animations.groupAnimationOrNil(),
      initialMountAnimation: animations.initialMount.groupAnimationOrNil(),
      finalUnmountAnimation: animations.finalUnmount.groupAnimationOrNil(fillMode: .forwards),
      didInitCallbacks: lifecycleCallbacks.didInit.isEmpty ? nil : lifecycleCallbacks.didInit,
      willMountCallbacks: lifecycleCallbacks.willMount.isEmpty ? nil : lifecycleCallbacks.willMount,
      didUnmountCallbacks: lifecycleCallbacks.didUnmount.isEmpty ? nil : lifecycleCallbacks.didUnmount,
      willDisposeCallbacks: lifecycleCallbacks.willDispose.isEmpty ? nil : lifecycleCallbacks.willDispose
    )
  }

  var lifecycleCallbacks = LifecycleCallbacks()
  var animations = Animations()

  var isEmpty: Bool {
    lifecycleCallbacks.isEmpty && animations.isEmpty
  }
}

final public class SwiftComponent<View: CKSwift.View> : CKSwiftComponent {
  let view: View

  init(_ view: View, body: Component? = nil, viewConfiguration: ViewConfiguration? = nil, size: ComponentSize? = nil, model: SwiftComponentModel?) {
    self.view = view
    super.init(
      swiftView: viewConfiguration?.viewConfiguration,
      swiftSize: size?.componentSize,
      child: body,
      model: model?.toSwiftBridge())
  }
}

#endif
