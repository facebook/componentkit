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

protocol ScopeHandleAssignable : AnyObject {
  func assign(handle: CKComponentScopeHandle)
}

@propertyWrapper
public struct ViewModel<Value: AnyObject> : TreeNodeLinkable {
  private let store: TreeNodeValueStore<Value>

  public init(wrappedValue valueProvider: @escaping @autoclosure () -> Value) {
    self.store = TreeNodeValueStore(valueProvider: valueProvider)
  }

  /// Should only be called during component build or on the main thread thereafter
  public var wrappedValue: Value {
    store.get()
  }

  // MARK: ScopeHandleLinkable

  func link(with node: CKTreeNode, at index: Int) {
    if store.link(with: node, at: index) {
      Mirror(reflecting: wrappedValue)
        .children
        .compactMap {
          $0.value as? ScopeHandleAssignable
        }
        .forEach {
          $0.assign(handle: node.scopeHandle)
        }
    }
  }
}

extension ViewModel : Equatable {
  static public func ==(lhs: ViewModel, rhs: ViewModel) -> Bool {
    lhs.wrappedValue === rhs.wrappedValue
  }
}
