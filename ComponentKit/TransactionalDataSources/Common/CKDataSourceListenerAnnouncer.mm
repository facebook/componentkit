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

- (void)componentDataSource:(CKDataSource *)dataSource
     didModifyPreviousState:(CKDataSourceState *)previousState
          byApplyingChanges:(CKDataSourceAppliedChanges *)changes
{
  CK::Component::AnnouncerHelper::call(self, _cmd, dataSource, previousState, changes);
}

- (void)componentDataSource:(CKDataSource *)dataSource willSyncApplyModificationWithUserInfo:(NSDictionary *)userInfo
{
  CK::Component::AnnouncerHelper::callOptional(self, _cmd, dataSource, userInfo);
}

- (void)componentDataSourceWillGenerateNewState:(CKDataSource *)dataSource
                                       userInfo:(NSDictionary *)userInfo
{
  CK::Component::AnnouncerHelper::callOptional(self, _cmd, dataSource, userInfo);
}

- (void)componentDataSource:(CKDataSource *)dataSource
        didGenerateNewState:(CKDataSourceState *)newState
                    changes:(CKDataSourceAppliedChanges *)changes
{
  CK::Component::AnnouncerHelper::callOptional(self, _cmd, dataSource, newState, changes);
}

@end
