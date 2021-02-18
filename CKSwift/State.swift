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

@propertyWrapper
// TODO: Use read/write reflection mechanism
public struct State<Value> : ScopeHandleLinkable {
  private let scopeHandleLocation: ScopeHandleLocation

  public init(wrappedValue valueProvider: @escaping @autoclosure () -> Value) {
    self.scopeHandleLocation = ScopeHandleLocation(valueProvider: valueProvider)
  }

  /// Should only be called during component build or on the main thread thereafter
  public var wrappedValue: Value {
    get {
      scopeHandleLocation.get()
    }

    /// Should only be called on the main thread
    nonmutating set {
      scopeHandleLocation.set(newValue)
    }
  }

  public var projectedValue: Binding<Value> {
    precondition(scopeHandleLocation.isLinked, "Attempting to get binding before `-body`")
    return Binding(get: { self.wrappedValue }, set: { self.wrappedValue = $0 })
  }

  // MARK: ScopeHandleLinkable

  func link(with handle: CKComponentScopeHandle, at index: Int) {
    scopeHandleLocation.link(with: handle, at: index)
  }
}

extension State : Equatable where Value : Equatable {
  static public func ==(lhs: State, rhs: State) -> Bool {
    return lhs.wrappedValue == rhs.wrappedValue
  }
}

#endif
