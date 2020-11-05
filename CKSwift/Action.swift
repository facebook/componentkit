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

/// Represents an action which can be invoked at a later date. An action will always
/// be invoked on the first non-null generation of a component.
public struct ActionWith<Param> {
  /// The type erased handler representing the action.
  private let handler: (Param) -> Void

  private init(handler: @escaping (Param) -> Void) {
    self.handler = handler
  }

  init<View: CKSwift.View>(handler: @escaping (View, Param) -> Void) {
    var responder: ScopedResponder?
    var key: ScopedResponderKey = -1

    guard CKSwiftInitializeAction(SwiftComponent<View>.self, &responder, &key),
          let scopedResponder = responder,
          key != -1 else {
      fatalError("Attempting to initialise action outside of the right body function")
    }

    self.handler = { param in
      guard let untypedComponent = scopedResponder.responder(forKey: key) as? Component else { return }
      guard let component = untypedComponent as? SwiftComponent<View> else {
        fatalError("Expecting \(SwiftComponent<View>.self) when invoking action but got \(untypedComponent) instead")
      }
      handler(component.view, param)
    }
  }

  init<View: CKSwift.View>(handler: @escaping (View) -> Void) {
    self.init() { view, _ in
      handler(view)
    }
  }

  init<View: CKSwift.View>(handler: @escaping (View) -> (Param) -> Void) {
    self.init() { view, param in
      handler(view)(param)
    }
  }

  init<View: CKSwift.View>(handler: @escaping (View) -> () -> Void) {
    self.init() { view, _ in
      handler(view)()
    }
  }
  
  /// Creates an action from a target + handler. Use this when the target of an action isn't a view/component.
  public init<Target: AnyObject>(target: Target, handler: @escaping (Target) -> (Param) -> Void) {
    self.handler = { [weak weakTarget = target] param in
      guard let strongTarget = weakTarget else { return }
      handler(strongTarget)(param)
    }
  }

  /// Invokes the action.
  /// - Parameter param: The parameter to pass to the action.
  public func invoke(_ param: Param) {
    handler(param)
  }

  /// The objective-c bridgeable representation of a parametrized action.
  public var swiftBridgeWithType: ActionWithId_SwiftBridge {
    return { aParam in
      guard let param = aParam as? Param else {
        fatalError("Expecting to find \(Param.self) but got \(type(of: aParam))")
      }
      self.invoke(param)
    }
  }

  /// Demotes an action with a parameter to a parameter less param.
  /// - Parameter param: The value to pass to the action handler.
  /// - Returns: The parameterless `Action`.
  public func demote(passing param: Param) -> Action {
    Action() { _ in
      handler(param)
    }
  }
}

public typealias Action = ActionWith<Void>

public extension Action where Param == Void {

  /// Invokes the action.
  func invoke() {
    invoke(())
  }

  /// The objective-c bridgeable representation of a parameter-less action.
  var swiftBridge: Action_SwiftBridge {
    return {
      self.invoke(())
    }
  }
}

/// Marker protocol to indicate that a view can supply actions.
public protocol Actionable : ScopeHandleProvider { }

extension View where Self: Actionable {
  public func onAction<Param>(_ handler: @escaping (Self, Param) -> Void) -> ActionWith<Param> {
    ActionWith(handler: handler)
  }

  public func onAction<Param>(_ handler: @escaping (Self) -> (Param) -> Void) -> ActionWith<Param> {
    ActionWith(handler: handler)
  }

  public func onAction(_ handler: @escaping (Self) -> Void) -> Action {
    ActionWith(handler: handler)
  }

  public func onAction(_ handler: @escaping (Self) -> () -> Void) -> Action {
    ActionWith(handler: handler)
  }

  /// Creates a `Action` which receives a param not specified by the caller but on creation.
  public func onAction<Param>(_ handler: @escaping (Self) -> (Param) -> Void, passing param: Param) -> Action {
    Action() { view in
      handler(view)(param)
    }
  }
}

#endif
