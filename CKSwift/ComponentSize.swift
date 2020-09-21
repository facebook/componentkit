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

/// Represents a component desired size relative to the size of its parent.
public struct ComponentSize: Hashable {
  /// The Objective-C bridgeable type.
  public let componentSize: ComponentSizeSwiftBridge

  /// Creates a new component size.
  /// - Parameter size: The CKSize to derive the size from.
  public init(size: CGSize) {
    componentSize = ComponentSizeSwiftBridge(size: size)
  }

  /// Creates a new component size.
  /// - Parameters:
  ///   - width: The component size's width.
  ///   - height: The component size's height.
  ///   - minWidth: The component size's min width.
  ///   - minHeight: The component size's min height.
  ///   - maxWidth: The component size's max width.
  ///   - maxHeight: The component size's max height.
  public init(width: Dimension? = nil,
              height: Dimension? = nil,
              minWidth: Dimension? = nil,
              minHeight: Dimension? = nil,
              maxWidth: Dimension? = nil,
              maxHeight: Dimension? = nil) {
    componentSize = ComponentSizeSwiftBridge(width: width?.dimension,
                                             height: height?.dimension,
                                             minWidth: minWidth?.dimension,
                                             minHeight: minHeight?.dimension,
                                             maxWidth: maxWidth?.dimension,
                                             maxHeight: maxHeight?.dimension)
  }
}

extension ComponentSize: CustomStringConvertible {
  public var description: String { return componentSize.description }
}

