/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKDefines.h>

#if CK_NOT_SWIFT

#import <Foundation/Foundation.h>

@class CKDataSource;
@class CKDataSourceAppliedChanges;
@class CKDataSourceChangeset;
@class CKDataSourceState;

@protocol CKDataSourceListener

/**
 Announced on the main thread when the data source has just updated its state.
 @param dataSource The sending data source.
 @param previousState The state that the data source was previously exposing.
 @param state The state that the data source currently has. Always use this to get new state instead of relying on dataSource.state
 @param changes The changes that were applied (which may correspond to multiple
        CKDataSourceChangeset objects).
 */

- (void)dataSource:(CKDataSource *)dataSource didModifyPreviousState:(CKDataSourceState *)previousState withState:(CKDataSourceState *)state byApplyingChanges:(CKDataSourceAppliedChanges *)changes;

/**
 Announced when the data source is about to apply a deferred changeset -- this only occurs if changeset
 splitting is enabled and the changeset passed to -applyChangeset: was large enough to be split.
 @param dataSource The sending data source.
 @param deferredChangeset The deferred changeset that is about to be applied.
 */
- (void)dataSource:(CKDataSource *)dataSource willApplyDeferredChangeset:(CKDataSourceChangeset *)deferredChangeset;

@end

@protocol CKDataSourceAsyncListener <CKDataSourceListener>

/**
 Announced on the main thread when the data source will synchronously start modification application.
 If the modification was scheduled asynchronously and had already started processing on workQueue,
 you will receive *both* will/didGenerateNewState and willSyncApplyModificationWithUserInfo, however
 the work done on workQueue will be ignored
 @param dataSource The sending data source
 @param userInfo Additional information that was passed with modification
 */

- (void)dataSource:(CKDataSource *)dataSource willSyncApplyModificationWithUserInfo:(NSDictionary *)userInfo;

/**
 Announced on the background thread when the data source will generate new state.
 This event only announced is the modification was schedule asynchronously
 @param dataSource The sending data source
 @param userInfo Additional information that was passed with modification
 */
- (void)dataSource:(CKDataSource *)dataSource willGenerateNewStateWithUserInfo:(NSDictionary *)userInfo;

/**
 Announced on the background thread when the data source has just generated new state.
 This event only announced is the modification was schedule asynchronously
 @param dataSource The sending data source; its state property still contains old state
 @param newState The state that the data source has just generated and will schedule for applying.
 @param changes The changes that ar going to be applied.
 */
- (void)dataSource:(CKDataSource *)dataSource didGenerateNewState:(CKDataSourceState *)newState changes:(CKDataSourceAppliedChanges *)changes;

@end

#endif
