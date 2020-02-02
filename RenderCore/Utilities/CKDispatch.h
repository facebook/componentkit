/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <RenderCore/CKDefines.h>

#if CK_NOT_SWIFT

#import <UIKit/UIKit.h>

/**
 * This method dispatches a block on the main thread only when the
 * user is not interacting with the UI (i.e. scrolling, panning etc.).
 *
 * Implementation Details:
 * The user is not interacting with the app when the main run loop has a run
 * mode that is NOT UITrackingRunLoopMode. This is implemented by dispatching
 * the block when the run mode of the main run loop is kCFRunLoopDefaultMode.
 */
void CKDispatchMainDefaultMode(dispatch_block_t block) noexcept;

#endif
