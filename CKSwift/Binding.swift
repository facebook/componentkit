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

@dynamicMemberLookup
@propertyWrapper
public struct Binding<Value> {
  private let get: () -> Value
  private let set: (Value) -> Void

  public init(get: @escaping () -> Value, set: @escaping (Value) -> Void) {
    self.get = get
    self.set = set
  }

  public var wrappedValue: Value {
    get {
      get()
    }
    nonmutating set {
      set(newValue)
    }
  }

  public var projectedValue: Binding<Value> {
    self
  }

  public subscript<T>(dynamicMember keyPath: WritableKeyPath<Value, T>) -> Binding<T> {
    Binding<T>(get: {
      self.wrappedValue[keyPath: keyPath]
    }, set: {
      self.wrappedValue[keyPath: keyPath] = $0
    })
  }
}

extension Binding : Equatable where Value : Equatable {
  static public func ==(lhs: Binding, rhs: Binding) -> Bool {
    // That will be enough for now, but should two bindings pointing to different state
    // of the same values be equal?
    lhs.wrappedValue == rhs.wrappedValue
  }
}
