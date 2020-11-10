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

public class SwiftComponent<View: CKSwift.View> : CKSwiftComponent {
  let view: View

  init(_ view: View, body: Component? = nil, viewConfiguration: ViewConfiguration? = nil, size: ComponentSize? = nil, model: SwiftComponentModel?) {
    self.view = view
    super.init(
      swiftView: viewConfiguration?.viewConfiguration,
      swiftSize: size?.componentSize,
      child: body,
      model: model?.toSwiftBridge())
  }

  init(_ shellComponent: SwiftComponent<View>, body: Component? = nil) {
    self.view = shellComponent.view
    super.init(
      fromShellComponent: shellComponent,
      child: body
    )
  }
}

public typealias SwiftReusableComponentView = CKSwift.View & ViewIdentifiable & Equatable

public class SwiftReusableBaseComponent<View: SwiftReusableComponentView> : SwiftComponent<View>, ReusableComponentProtocol {
  public var componentIdentifier: Any? {
    view.id
  }

  public func didReuseComponent(_ component: ReusableComponentProtocol) {
    fatalError("Should never be called")
  }

  public func shouldComponentUpdate(_ untypedComponent: ReusableComponentProtocol) -> Bool {
    guard let component = untypedComponent as? SwiftReusableBaseComponent<View> else {
      fatalError("Attempting to reuse a component of a different type: \(type(of: untypedComponent))")
    }

    return view != component.view
  }

  public func clone() -> Self {
    fatalError("-clone should never be called on `SwiftReusableBaseComponent`.")
  }
}

public final class SwiftReusableComponent<View: SwiftReusableComponentView> : SwiftReusableBaseComponent<View> where View.Body == Component {
  override public func clone() -> Self {
    SwiftReusableComponent(self, body: view.body) as! Self
  }
}

public final class SwiftReusableLeafComponent<View: SwiftReusableComponentView> : SwiftReusableBaseComponent<View> where View.Body == Never {
  override public func clone() -> Self {
    SwiftReusableLeafComponent(self) as! Self
  }
}

#endif
