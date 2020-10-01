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
// TODO: Change to struct and use read/write reflection mechanism
public class State<Value> : ScopeHandleLinkable {
  private let valueProvider: () -> Value
  private var link: (handle: CKComponentScopeHandle, index: Int)?

  public init(wrappedValue valueProvider: @escaping @autoclosure () -> Value) {
    self.valueProvider = valueProvider
  }

  /// Should only be called during component build or on the main thread thereafter
  public var wrappedValue: Value {
    get {
      guard let link = link else {
        fatalError("Attempting to read state before `-body`.")
      }
      let untypedValue = CKSwiftFetchState(link.handle, link.index)
      guard let value = untypedValue as? Value else {
        fatalError("Unexpected value \(String(describing: untypedValue))")
      }
      return value
    }

    /// Should only be called on the main thread
    set {
      guard let link = link else {
        fatalError("Attempting to write state before `-body`.")
      }

      CKSwiftUpdateState(link.handle, link.index, newValue)
    }
  }

  public var projectedValue: Binding<Value> {
    precondition(link != nil, "Attempting to get binding before `-body`")
    return Binding(state: self)
  }

  // MARK: ScopeHandleLinkable

  func link(with handle: CKComponentScopeHandle, at index: Int) {
    link = (handle, index)
    CKSwiftInitializeState(handle, index, valueProvider)
  }
}

extension State : Equatable where Value : Equatable {
  static public func ==(lhs: State, rhs: State) -> Bool {
    return lhs.wrappedValue == rhs.wrappedValue
  }
}

#endif
