/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <Foundation/Foundation.h>

/**
 A singleton controller which can be used to force a delay in stateful view relinquish for all stateful views.
 
 Stateful view component controllers may prefer to maintain ownership of their stateful views during insertion into
 the collection or table view above the viewport. In that case, the active cell can be recycled and the stateful view
 may choose to delay the relinquish of the stateful view for one runloop turn so that if the view is immediately re-
 rendered, it may render with the same stateful view as it just had.
 
 This controller allows us to avoid the delayed relinquish hack for normal scrolling, while still supporting it in
 stateful view component controllers in cases where active viewport jumping could trigger a remount on an active cell.
 */
@interface CKStatefulViewRelinquishController : NSObject

+ (CKStatefulViewRelinquishController *)sharedInstance;

/**
 By default, delayed relinquishing is enabled. To turn off delayed relinquish for all views, and manage delaying
 stateful view relinquishing manually, you may disable it here.
 
 If you disable this parameter, it takes effect for *all stateful views*.
 */
- (void)setDelayedRelinquishDefault:(BOOL)delayedRelinquishEnabled;

/**
 If the default has been set to NO, then calling this method will enable the delayed relinquish operation for one
 runloop turn. It's a good idea to call this before making updates to the collection view.
 */
- (void)delayRelinquishForRunloopTurn;

/**
 Called by the stateful view component controller to determine if it should delay relinquishing its view.
 */
@property (nonatomic, assign, readonly) BOOL delayedRelinquishEnabled;

@end
