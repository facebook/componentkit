/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <UIKit/UIKit.h>

#import <ComponentKit/CKTextKitAttributes.h>

enum {
  CKUIControlEventTextViewDidBeginHighlightingText  = 1 << 24,
  CKUIControlEventTextViewDidCancelHighlightingText = 1 << 25,
  CKUIControlEventTextViewDidEndHighlightingText    = 1 << 26,
  CKUIControlEventTextViewDidTapText                = CKUIControlEventTextViewDidEndHighlightingText,
};

@class CKTextKitRenderer;

@interface CKTextComponentView : UIControl

@property (nonatomic, strong) CKTextKitRenderer *renderer;

@end
