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
  dispatch_queue_t _workQueue;
  CKDataSourceQOS _workQos;
}

- (instancetype)initWithChangeset:(CKDataSourceChangeset *)changeset
                    stateListener:(id<CKComponentStateListener>)stateListener
                         userInfo:(NSDictionary *)userInfo
                              qos:(CKDataSourceQOS)qos
                        workQueue:(dispatch_queue_t)workQueue
{
  if (self = [super initWithChangeset:changeset stateListener:stateListener userInfo:userInfo qos:qos]) {
    _workQueue = workQueue;
    _workQos = qos;
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
                                        layoutPredicates:(const std::unordered_set<CKComponentPredicate> &)layoutPredicates
                                                itemType:(CKDataSourceChangesetModificationItemType)itemType
{
  auto item = [[CKDataSourceAsyncLayoutItem alloc] initWithQueue:_workQueue
                                                             qos:_workQos
                                                    previousRoot:previousRoot
                                                    stateUpdates:stateUpdates
                                                       sizeRange:sizeRange
                                                   configuration:configuration
                                                           model:model
                                                         context:context
                                                layoutPredicates:layoutPredicates];
  [item beginLayout];
  return item;
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
