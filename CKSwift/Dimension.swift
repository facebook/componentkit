/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

import ComponentKit

/// A dimension relative to constraints to be provided in the future.
public enum Dimension: Hashable {
  case points(CGFloat)
  case percent(CGFloat)
  case auto

  /// The Objective-C bridgeable type.
  public var dimension: DimensionSwiftBridge {
    switch self  {
    case let .points(points):
      return DimensionSwiftBridge(points: points)
    case let .percent(percent):
      return DimensionSwiftBridge(percent: percent)
    case .auto:
      return DimensionSwiftBridge.autoInstance()
    }
  }
}

extension Dimension: CustomStringConvertible {
  public var description: String { return dimension.description }
}

extension Dimension: ExpressibleByFloatLiteral {
  public init(floatLiteral value: Double) {
    self = .points(CGFloat(value))
  }
}

extension Dimension: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: Int) {
    self = .points(CGFloat(value))
  }
}

