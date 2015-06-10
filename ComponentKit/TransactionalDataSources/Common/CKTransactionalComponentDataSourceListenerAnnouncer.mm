/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKTransactionalComponentDataSourceListenerAnnouncer.h"

#import <ComponentKit/CKComponentAnnouncerHelper.h>

@implementation CKTransactionalComponentDataSourceListenerAnnouncer

- (void)addListener:(id<CKTransactionalComponentDataSourceListener>)listener
{
  CK::Component::AnnouncerHelper::addListener(self, _cmd, listener);
}

- (void)removeListener:(id<CKTransactionalComponentDataSourceListener>)listener
{
  CK::Component::AnnouncerHelper::removeListener(self, _cmd, listener);
}

- (void)transactionalComponentDataSource:(CKTransactionalComponentDataSource *)dataSource
                  didModifyPreviousState:(CKTransactionalComponentDataSourceState *)previousState
                       byApplyingChanges:(CKTransactionalComponentDataSourceAppliedChanges *)changes
{
  CK::Component::AnnouncerHelper::call(self, _cmd, dataSource, previousState, changes);
}

@end
