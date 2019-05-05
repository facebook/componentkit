/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant 
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKDataSource.h>
#import <ComponentKit/CKDataSourceProtocolInternal.h>

@interface CKDataSource () <CKDataSourceProtocolInternal>

/**
 The queue that the data source uses for its asynchronous operations.
 You may change the target queue of this queue to any queue that is not the main queue.
 You may dispatch_suspend this queue (but be sure to resume it later).
 */
@property (nonatomic, strong, readonly) dispatch_queue_t workQueue;

/**
 Pause work queue of `CKDataSource`.
 Further asynchronous modifications will not be processed immediately until it's resumed.
 */
- (void)pauseWorkQueue;

/**
 Resume work queue of `CKDataSource`.
 Start processing pending asynchronous modifications.
 */
- (void)resumeWorkQueue;

@end
