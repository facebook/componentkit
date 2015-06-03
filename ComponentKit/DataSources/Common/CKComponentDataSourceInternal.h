/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKComponentDataSource.h>

@interface CKComponentDataSource ()

/**
 The concurrent queue that the preparation queue uses for its asynchronous operations.
 You may change the target queue of this queue to any queue that is not the main queue.
 You may dispatch_suspend this queue (but be sure to resume it later).
 Exposed here to allow for CPU Reprioritization.
 */
@property (nonatomic, strong, readonly) dispatch_queue_t concurrentQueue;

@end
