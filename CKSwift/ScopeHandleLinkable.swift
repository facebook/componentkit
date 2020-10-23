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

/// Marker protocol for views indicating that a scope handle is necessary.
public protocol ScopeHandleProvider { }

protocol ScopeHandleLinkable {
  func link(with scopeHandle: CKComponentScopeHandle, at index: Int)
}
