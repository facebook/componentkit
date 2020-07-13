/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKWritingDirection.h"

CKWritingDirection CKGetWritingDirection() {
  static CKWritingDirection WritingDirection;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    switch ([NSParagraphStyle defaultWritingDirectionForLanguage:nil]) {
      case NSWritingDirectionRightToLeft:
        WritingDirection = CKWritingDirection::RightToLeft;
        break;
      case NSWritingDirectionLeftToRight:
        WritingDirection = CKWritingDirection::LeftToRight;
        break;
      case NSWritingDirectionNatural:
        WritingDirection = CKWritingDirection::Natural;
        break;
    }
  });
  return WritingDirection;
}
