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

#import <ComponentKit/CKDataSource.h>

@class CKDataSourceChange;

@interface CKDataSource ()

/**
 The queue that the data source uses for its asynchronous operations.
 You may change the target queue of this queue to any queue that is not the main queue.
 You may dispatch_suspend this queue (but be sure to resume it later).
 */
@property (nonatomic, strong, readonly) dispatch_queue_t workQueue;

/**
 Current state of CKDataSource. This is main thread affined.
 */
@property (nonatomic, strong, readonly) CKDataSourceState *state;

/**
 State updates that are triggered after this flag is set to YES won't be processed until
 it's set to NO again. This is main thread affined.
 */
@property (nonatomic, assign) BOOL shouldPauseStateUpdates;

/**
 `CKDataSourceQoSDefault` will be mapped to a lower QoS class when this is set to `YES`.
 This means applying changeset with default QoS or processing state update is affected when this is set to `YES`.
 This is main thread affined.
 */
@property (nonatomic, assign) BOOL isBackgroundMode;

/**
 @param state initial state of dataSource, pass `nil` for an empty state.
 */
- (instancetype)initWithState:(CKDataSourceState *)state;

/**
 Apply a pre-computed `CKDataSourceChange` to the datasource.
 `NO` will be returned if the change is computed based on a outdated state.
 @param change pre-computed `CKDataSourceChange`
 @return YES if the applied change is legit.
 */
- (BOOL)applyChange:(CKDataSourceChange *)change;

/**
 Verify a pre-computed `CKDataSourceChange` without actually applying it to the datasource.
 `NO` will be returned if the change is computed based on a outdated state.
 @param change pre-computed `CKDataSourceChange`
 @return YES if the applied change is legit.
 */
- (BOOL)verifyChange:(CKDataSourceChange *)change;

@end

#endif
