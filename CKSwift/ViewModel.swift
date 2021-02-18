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

protocol ScopeHandleAssignable : class {
  func assign(handle: CKComponentScopeHandle)
}

@propertyWrapper
public struct ViewModel<Value: AnyObject> : ScopeHandleLinkable {
  private let scopeHandleLocation: ScopeHandleLocation

  public init(wrappedValue valueProvider: @escaping @autoclosure () -> Value) {
    self.scopeHandleLocation = ScopeHandleLocation(valueProvider: valueProvider)
  }

  /// Should only be called during component build or on the main thread thereafter
  public var wrappedValue: Value {
    scopeHandleLocation.get()
  }

  // MARK: ScopeHandleLinkable

  func link(with handle: CKComponentScopeHandle, at index: Int) {
    if scopeHandleLocation.link(with: handle, at: index) {
      Mirror(reflecting: wrappedValue)
        .children
        .compactMap {
          $0.value as? ScopeHandleAssignable
        }
        .forEach {
          $0.assign(handle: handle)
        }
    }
  }
}

extension ViewModel : Equatable {
  static public func ==(lhs: ViewModel, rhs: ViewModel) -> Bool {
    return lhs.wrappedValue === rhs.wrappedValue
  }
}
