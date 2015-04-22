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

#import <ComponentKit/CKComponentScopeFrame.h>

class CKComponentLayout;
class CKComponentBoundsAnimation;

@interface CKTransactionalComponentDataSourceItem : NSObject

- (const CKComponentLayout &)layout;

/** The model used to compute the layout */
- (id)model;

/** Announces a given event to all controllers in the layout. */
- (void)announceEventToControllers:(CKComponentAnnouncedEvent)event;

/** Computes the requested bounds animation given a previous version of the same item. */
- (CKComponentBoundsAnimation)boundsAnimationFromPreviousItem:(CKTransactionalComponentDataSourceItem *)previousItem;

@end
