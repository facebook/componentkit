/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKDataSourceListenerAnnouncer.h"

#import <ComponentKit/CKComponentAnnouncerHelper.h>

@implementation CKDataSourceListenerAnnouncer

- (void)addListener:(id<CKDataSourceListener>)listener
{
  CK::Component::AnnouncerHelper::addListener(self, _cmd, listener);
}

- (void)removeListener:(id<CKDataSourceListener>)listener
{
  CK::Component::AnnouncerHelper::removeListener(self, _cmd, listener);
}

- (void)dataSource:(CKDataSource *)dataSource
     didModifyPreviousState:(CKDataSourceState *)previousState
                  withState:(CKDataSourceState *)state
          byApplyingChanges:(CKDataSourceAppliedChanges *)changes
{
  CK::Component::AnnouncerHelper::call(self, _cmd, dataSource, previousState, state, changes);
}

- (void)dataSource:(CKDataSource *)dataSource willSyncApplyModificationWithUserInfo:(NSDictionary *)userInfo
{
  CK::Component::AnnouncerHelper::callOptional(self, _cmd, dataSource, userInfo);
}

- (void)dataSource:(CKDataSource *)dataSource willGenerateNewStateWithUserInfo:(NSDictionary *)userInfo
{
  CK::Component::AnnouncerHelper::callOptional(self, _cmd, dataSource, userInfo);
}

- (void)dataSource:(CKDataSource *)dataSource
        didGenerateNewState:(CKDataSourceState *)newState
                    changes:(CKDataSourceAppliedChanges *)changes
{
  CK::Component::AnnouncerHelper::callOptional(self, _cmd, dataSource, newState, changes);
}

- (void)dataSource:(CKDataSource *)dataSource
 willApplyDeferredChangeset:(CKDataSourceChangeset *)deferredChangeset
{
  CK::Component::AnnouncerHelper::call(self, _cmd, dataSource, deferredChangeset);
}

@end
