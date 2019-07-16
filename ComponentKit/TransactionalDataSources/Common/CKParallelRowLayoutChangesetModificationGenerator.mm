/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKParallelRowLayoutChangesetModificationGenerator.h"

#import "CKDataSourceAsyncLayoutItem.h"
#import "CKDataSourceChangesetModification.h"
#import "CKDataSourceItem.h"
#import "CKDataSourceModificationHelper.h"
#import "CKDataSourceQOSHelper.h"

@interface CKParallelRowLayoutChangesetModification : CKDataSourceChangesetModification <CKDataSourceChangesetModificationItemGenerator>

- (instancetype)initWithChangeset:(CKDataSourceChangeset *)changeset
                    stateListener:(id<CKComponentStateListener>)stateListener
                         userInfo:(NSDictionary *)userInfo
                              qos:(CKDataSourceQOS)qos
                        workQueue:(dispatch_queue_t)workQueue;

@end

@implementation CKParallelRowLayoutChangesetModification
{
  NSOperationQueue *_queue;
}

static NSOperationQualityOfService _operationQosFromDataSourceQOS(CKDataSourceQOS qos) {
  switch (qos) {
    case CKDataSourceQOSUserInteractive:
      return NSOperationQualityOfServiceUserInteractive;
    case CKDataSourceQOSUserInitiated:
      return NSOperationQualityOfServiceUserInitiated;
    case CKDataSourceQOSDefault:
      return NSOperationQualityOfServiceUtility;
  }
}

- (instancetype)initWithChangeset:(CKDataSourceChangeset *)changeset
                    stateListener:(id<CKComponentStateListener>)stateListener
                         userInfo:(NSDictionary *)userInfo
                              qos:(CKDataSourceQOS)qos
                        workQueue:(dispatch_queue_t)workQueue
{
  if (self = [super initWithChangeset:changeset stateListener:stateListener userInfo:userInfo qos:qos]) {
    _queue = [NSOperationQueue new];
    _queue.underlyingQueue = workQueue;
    _queue.qualityOfService = _operationQosFromDataSourceQOS(qos);
    NSUInteger maxConcurrentOperationCount = [NSProcessInfo processInfo].activeProcessorCount - 1;
    _queue.maxConcurrentOperationCount = maxConcurrentOperationCount > 0 ?: 1;
    [self setItemGenerator:self];
  }
  return self;
}

- (CKDataSourceItem *)buildDataSourceItemForPreviousRoot:(CKComponentScopeRoot *)previousRoot
                                            stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
                                               sizeRange:(const CKSizeRange &)sizeRange
                                           configuration:(CKDataSourceConfiguration *)configuration
                                                   model:(id)model
                                                 context:(id)context
                                                itemType:(CKDataSourceChangesetModificationItemType)itemType
{
  auto item = [[CKDataSourceAsyncLayoutItem alloc] initWithQueue:_queue
                                                    previousRoot:previousRoot
                                                    stateUpdates:stateUpdates
                                                       sizeRange:sizeRange
                                                   configuration:configuration
                                                           model:model
                                                         context:context];
  [item beginLayout];
  return item;
}

- (BOOL)shouldSortInsertedItems
{
  return YES;
}

- (BOOL)shouldSortUpdatedItems
{
  return YES;
}

@end

@implementation CKParallelRowLayoutChangesetModificationGenerator
{
  dispatch_queue_t _workQueue;
}

- (instancetype)init
{
  if (self = [super init]) {
    _workQueue = dispatch_queue_create("org.componentkit.CKParallelRowLayoutDataSourceComponentGen", DISPATCH_QUEUE_CONCURRENT);
  }
  return self;
}

- (id<CKDataSourceStateModifying>)changesetGenerationModificationForChangeset:(CKDataSourceChangeset *)changeset
                                                                     userInfo:(NSDictionary *)userInfo
                                                                          qos:(CKDataSourceQOS)qos
                                                                stateListener:(id<CKComponentStateListener>)stateListener
{
  return [[CKParallelRowLayoutChangesetModification alloc]
          initWithChangeset:changeset
          stateListener:stateListener
          userInfo:userInfo
          qos:qos
          workQueue:_workQueue];
}

@end
