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
import CKSwift
import UIKit

public extension LabelComponent {

  #if swift(>=5.1)
  convenience init(
    text: String,
    truncationString: String? = nil,
    font: UIFont? = nil,
    color: UIColor? = nil,
    lineBreakMode: NSLineBreakMode = .byWordWrapping,
    maximumNumberOfLines: UInt = 0,
    shadowOffset: CGSize = .zero,
    shadowColor: UIColor? = nil,
    shadowOpacity: CGFloat = 0,
    shadowRadius: CGFloat = 0,
    alignment: NSTextAlignment = .natural,
    firstLineHeadIndent: CGFloat = 0,
    headIndent: CGFloat = 0,
    tailIndent: CGFloat = 0,
    lineHeightMultiple: CGFloat = 0,
    maximumLineHeight: CGFloat = 0,
    minimumLineHeight: CGFloat = 0,
    lineSpacing: CGFloat = 0,
    paragraphSpacing: CGFloat = 0,
    paragraphSpacingBefore: CGFloat = 0,
    size: ComponentSize? = nil,
    @ViewConfigurationAttributeBuilder<UIView> attributes: () -> [ComponentViewAttributeSwiftBridge] = {[]}) {
    self.init(__text: text,
              truncationString: truncationString,
              font: font,
              color: color,
              lineBreakMode: lineBreakMode,
              maximumNumberOfLines: maximumNumberOfLines,
              shadowOffset: shadowOffset,
              shadowColor: shadowColor,
              shadowOpacity: shadowOpacity,
              shadowRadius: shadowRadius,
              alignment: alignment,
              firstLineHeadIndent: firstLineHeadIndent,
              headIndent: headIndent,
              tailIndent: tailIndent,
              lineHeightMultiple: lineHeightMultiple,
              maximumLineHeight: maximumLineHeight,
              minimumLineHeight: minimumLineHeight,
              lineSpacing: lineSpacing,
              paragraphSpacing: paragraphSpacing,
              paragraphSpacingBefore: paragraphSpacingBefore,
              swiftSize: size?.componentSize,
              swiftAttributes: attributes())
  }
#endif
}
