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
  private var link: (handle: CKComponentScopeHandle, index: Int)?

  init(valueProvider: @escaping () -> Value) {
    self.valueProvider = valueProvider
  }

  @discardableResult
  func link(with handle: CKComponentScopeHandle, at index: Int) -> Bool {
    link = (handle, index)
    return CKSwiftInitializeState(handle, index, valueProvider)
  }

  func get() -> Value {
    guard let link = link else {
      preconditionFailure("Attempting to read state before scope handle location linked.")
    }
    let untypedValue = CKSwiftFetchState(link.handle, link.index)
    guard let value = untypedValue as? Value else {
      preconditionFailure("Unexpected value \(String(describing: untypedValue))")
    }
    return value
  }

  func set(_ value: Value) {
    guard let link = link else {
      preconditionFailure("Attempting to write state before `-body`.")
    }

    CKSwiftUpdateState(link.handle, link.index, value)
  }

  var isLinked: Bool {
    link != nil
  }
}
