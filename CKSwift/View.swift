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

#if swift(>=5.3)

// MARK: ComponentInflatable

/// Can be inflated to a `Component` given a `SwiftComponentModel`.
/// Anything that is `ComponentInflatable` can be added to a CKSwift view hierarchy.
public protocol ComponentInflatable {
  func inflateComponent(with model: SwiftComponentModel?) -> Component
}

#endif
