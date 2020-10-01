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
public struct Binding<Value> {
  private let state: State<Value>

  public init(state: State<Value>) {
    self.state = state
  }

  public var wrappedValue: Value {
    get { state.wrappedValue }
    nonmutating set { state.wrappedValue = newValue }
  }
}

extension Binding : Equatable where Value : Equatable {
  static public func ==(lhs: Binding, rhs: Binding) -> Bool {
    return lhs.state == rhs.state
  }
}

#endif
