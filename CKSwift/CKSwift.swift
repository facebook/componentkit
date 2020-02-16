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

public struct Dimension: Hashable {
  let dimension: ComponentKit.Dimension

  public init() {
    dimension = ComponentKit.Dimension()
  }

  public init(points: CGFloat) {
    dimension = ComponentKit.Dimension(points: points)
  }

  public init(percent: CGFloat) {
    dimension = ComponentKit.Dimension(percent: percent)
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

// Re-export the type to avoid importing ComponentKit directly and ambiguities in type lookup
public typealias SizeRange = ComponentKit.SizeRange

public struct ComponentSize: Hashable {
  private let componentSize: ComponentKit.ComponentSize

  public init(size: CGSize) {
    componentSize = ComponentKit.ComponentSize(size: size)
  }

  public init(width: Dimension = Dimension(),
              height: Dimension = Dimension()) {
    componentSize = ComponentKit.ComponentSize(width: width.dimension, height: height.dimension)
  }
}

extension ComponentSize: CustomStringConvertible {
  public var description: String { return componentSize.description }
}
