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

@propertyWrapper
// TODO: Use read/write reflection mechanism
public struct State<Value> : TreeNodeLinkable {
  private let store: TreeNodeValueStore<Value>

  public init(wrappedValue valueProvider: @escaping @autoclosure () -> Value) {
    self.store = TreeNodeValueStore(valueProvider: valueProvider)
  }

  /// Should only be called during component build or on the main thread thereafter
  public var wrappedValue: Value {
    get {
      store.get()
    }

    /// Should only be called on the main thread
    nonmutating set {
      store.set(newValue)
    }
  }

  public var projectedValue: Binding<Value> {
    return Binding(get: { self.wrappedValue }, set: { self.wrappedValue = $0 })
  }

  // MARK: TreeNodeLinkable

  func link(with node: CKTreeNode, at index: Int) {
    store.link(with: node, at: index)
  }
}

extension State : Equatable where Value : Equatable {
  static public func ==(lhs: State, rhs: State) -> Bool {
    return lhs.wrappedValue == rhs.wrappedValue
  }
}
