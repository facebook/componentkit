/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#if  ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "CKComponentPreparationQueueListenerAnnouncer.h"

#import <ComponentKit/CKComponentAnnouncerHelper.h>

@implementation CKComponentPreparationQueueListenerAnnouncer

- (void)addListener:(id<CKComponentPreparationQueueListener>)listener
{
  CK::Component::AnnouncerHelper::addListener(self, _cmd, listener);
}

- (void)removeListener:(id<CKComponentPreparationQueueListener>)listener
{
  CK::Component::AnnouncerHelper::removeListener(self, _cmd, listener);
}

- (void)componentPreparationQueue:(CKComponentPreparationQueue *)preparationQueue didStartPreparingBatchOfSize:(NSUInteger)batchSize batchID:(NSUInteger)batchID
{
  CK::Component::AnnouncerHelper::call(self, _cmd, preparationQueue, batchSize, batchID);
}

- (void)componentPreparationQueue:(CKComponentPreparationQueue *)preparationQueue didFinishPreparingBatchOfSize:(NSUInteger)batchSize batchID:(NSUInteger)batchID
{
  CK::Component::AnnouncerHelper::call(self, _cmd, preparationQueue, batchSize, batchID);
}

@end
