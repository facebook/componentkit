/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#pragma once

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>

#else

#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>

#import <ComponentKit/NSView+CKSupport.h>
#import <ComponentKit/NSIndexPath+CKSupport.h>
#import <ComponentKit/NSResponder+CKSupport.h>
#import <ComponentKit/NSLayoutManager+CKPlatform.h>
#import <ComponentKit/NSTextContainer+CKSupport.h>
#import <ComponentKit/NSValue+CKSupport.h>
/*
 * These are defined here as the UIKit equivalents instead of using something like CKViewClass / CKControlClass etc so that it will be easier to merge with upstream ComponentKit.
 */

#define UIView NSView
#define UIControl NSControl
#define UIColor NSColor
#define UIFont NSFont
#define UIEdgeInsets NSEdgeInsets
#define UIEdgeInsetsZero ((NSEdgeInsets){})
#define UIEvent NSEvent
#define UIGestureRecognizer NSGestureRecognizer

static inline CGRect UIEdgeInsetsInsetRect(CGRect r, UIEdgeInsets insets) {
  r.origin.x    += insets.left;
  r.origin.y    += insets.top;
  r.size.width  -= insets.left +insets.right;
  r.size.height -= insets.top +insets.bottom;
  return r;
};

#define UIEdgeInsetsMake NSEdgeInsetsMake

#define NSStringFromCGSize NSStringFromSize
#define NSStringFromCGPoint NSStringFromPoint

static inline bool UIAccessibilityIsVoiceOverRunning() {
  // via http://stackoverflow.com/a/485314/113455
  return CFPreferencesCopyAppValue(CFSTR("voiceOverOnOffKey"), CFSTR("com.apple.universalaccess")) == kCFBooleanTrue;
}

#endif //TARGET_OS_IPHONE

