/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <Foundation/Foundation.h>

@class CKTransactionalComponentDataSource;
@class CKTransactionalComponentDataSourceAppliedChanges;
@class CKTransactionalComponentDataSourceState;

@protocol CKTransactionalComponentDataSourceListener

/**
 Announced on the main thread when the data source has just updated its state.
 @param dataSource The sending data source; its state property now returns an updated object.
 @param previousState The state that the data source was previously exposing.
 @param changes The changes that were applied (which may correspond to multiple 
        CKTransactionalComponentDataSourceChangeset objects).
 */
- (void)transactionalComponentDataSource:(CKTransactionalComponentDataSource *)dataSource
                  didModifyPreviousState:(CKTransactionalComponentDataSourceState *)previousState
                       byApplyingChanges:(CKTransactionalComponentDataSourceAppliedChanges *)changes;

@end
