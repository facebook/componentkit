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
import UIKit

extension Array where Element: CAAnimation {
  func groupAnimationOrNil(fillMode: CAMediaTimingFillMode = .backwards) -> CAAnimation? {
    guard count > 1 else {
      return first
    }

    let animationGroup = CAAnimationGroup()
    animationGroup.animations = self
    animationGroup.fillMode = fillMode
    return animationGroup
  }
}
