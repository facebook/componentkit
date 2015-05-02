/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

@class CKComponentPreparationQueue;

@protocol CKComponentPreparationQueueListener <NSObject>

- (void)componentPreparationQueue:(CKComponentPreparationQueue *)preparationQueue
     didStartPreparingBatchOfSize:(NSUInteger)batchSize
                          batchID:(NSUInteger)batchID;

- (void)componentPreparationQueue:(CKComponentPreparationQueue *)preparationQueue
    didFinishPreparingBatchOfSize:(NSUInteger)batchSize
                          batchID:(NSUInteger)batchID;

@end
