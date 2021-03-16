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

final class TreeNodeValueStore<Value> {
  private let valueProvider: () -> Value
  private var link: (node: CKTreeNode, index: Int, value: Value)?

  init(valueProvider: @escaping () -> Value) {
    self.valueProvider = valueProvider
  }

  @discardableResult
  func link(with node: CKTreeNode, at index: Int) -> Bool {
    let wasFirstInit = CKSwiftInitializeState(node.scopeHandle, index, valueProvider)
    let untypedValue = CKSwiftFetchState(node, index)
    guard let value = untypedValue as? Value else {
      preconditionFailure("Unexpected value \(String(describing: untypedValue))")
    }

    link = (node, index, value)
    return wasFirstInit
  }

  func get() -> Value {
    guard let link = link else {
      preconditionFailure("Attempting to read state before scope handle location linked.")
    }
    return link.value
  }

  func set(_ value: Value) {
    guard let nonNilLink = link else {
      preconditionFailure("Attempting to write state before `-body`.")
    }

    link!.value = value
    CKSwiftUpdateState(nonNilLink.node.scopeHandle, nonNilLink.index, value)
  }

  var isLinked: Bool {
    link != nil
  }
}
