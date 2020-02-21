/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKDefines.h>

#if CK_NOT_SWIFT

#import <UIKit/UIKit.h>

#import <ComponentKit/CKComponentLayout.h>

/** Adopted by views that may contain mounted CKComponentLayouts. May be used by debug tools. */
@protocol CKInspectableView
/** Call this only on the main thread. */
- (CKComponentLayout)mountedLayout;

/** Unique identifier for the component hierarchy hosted in this view */
- (id<NSObject>)uniqueIdentifier;
@end

#endif
