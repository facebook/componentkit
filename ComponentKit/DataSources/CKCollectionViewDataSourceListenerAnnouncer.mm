/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKCollectionViewDataSourceListenerAnnouncer.h"

#import <ComponentKit/CKComponentAnnouncerHelper.h>

@implementation CKCollectionViewDataSourceListenerAnnouncer

- (void)addListener:(id<CKCollectionViewDataSourceListener>)listener
{
  CK::Component::AnnouncerHelper::addListener(self, _cmd, listener);
}

- (void)removeListener:(id<CKCollectionViewDataSourceListener>)listener
{
  CK::Component::AnnouncerHelper::removeListener(self, _cmd, listener);
}

- (void)dataSourceWillBeginUpdates:(CKCollectionViewDataSource *)dataSource
{
  CK::Component::AnnouncerHelper::call(self, _cmd, dataSource);
}

- (void)dataSourceDidEndUpdates:(CKCollectionViewDataSource *)dataSource
         didModifyPreviousState:(CKDataSourceState *)previousState
                      withState:(CKDataSourceState *)state
              byApplyingChanges:(CKDataSourceAppliedChanges *)changes
{
  CK::Component::AnnouncerHelper::call(self, _cmd, dataSource, previousState, state, changes);
}

- (void)dataSource:(CKCollectionViewDataSource *)dataSource
   willChangeState:(CKDataSourceState *)state
{
  CK::Component::AnnouncerHelper::call(self, _cmd, dataSource, state);
}

- (void)dataSource:(CKCollectionViewDataSource *)dataSource
    didChangeState:(CKDataSourceState *)previousState
         withState:(CKDataSourceState *)state
{
  CK::Component::AnnouncerHelper::call(self, _cmd, dataSource, previousState, state);
}

@end
