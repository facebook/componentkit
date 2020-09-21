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
public struct Dimension: Hashable {
  /// The Objective-C bridgeable type.
  public let dimension: DimensionSwiftBridge

  /// Creates a default dimension.
  public init() {
    dimension = DimensionSwiftBridge()
  }

  /// Creates a new dimension.
  /// - Parameter points: The fixed number of points represented.
  public init(points: CGFloat) {
    dimension = DimensionSwiftBridge(points: points)
  }

  /// Creates a new dimension.
  /// - Parameter percent: The percentage of the parent dimension.
  public init(percent: CGFloat) {
    dimension = DimensionSwiftBridge(percent: percent)
  }
}

extension Dimension: CustomStringConvertible {
  public var description: String { return dimension.description }
}

extension Dimension: ExpressibleByFloatLiteral {
  public init(floatLiteral value: Double) {
    self.init(points: CGFloat(value))
  }
}

extension Dimension: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: Int) {
    self.init(points: CGFloat(value))
  }
}

