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

static CKWritingDirection sWritingDirection;

CKWritingDirection CKGetWritingDirection() {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    switch ([NSParagraphStyle defaultWritingDirectionForLanguage:nil]) {
      case NSWritingDirectionRightToLeft:
        sWritingDirection = CKWritingDirection::RightToLeft;
        break;
      case NSWritingDirectionLeftToRight:
        sWritingDirection = CKWritingDirection::LeftToRight;
        break;
      case NSWritingDirectionNatural:
        sWritingDirection = CKWritingDirection::Natural;
        break;
    }
  });
  return sWritingDirection;
}

void CKOverrideWritingDirection(CKWritingDirection writingDirection) {
  sWritingDirection = writingDirection;
}
