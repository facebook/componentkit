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

@class CKCollectionViewDataSource;
@class CKDataSourceAppliedChanges;
@class CKDataSourceState;

@protocol CKCollectionViewDataSourceListener

- (void)dataSourceWillBeginUpdates:(CKCollectionViewDataSource *)dataSource;

- (void)dataSourceDidEndUpdates:(CKCollectionViewDataSource *)dataSource
         didModifyPreviousState:(CKDataSourceState *)previousState
                      withState:(CKDataSourceState *)state
              byApplyingChanges:(CKDataSourceAppliedChanges *)changes;

- (void)dataSource:(CKCollectionViewDataSource *)dataSource
   willChangeState:(CKDataSourceState *)state;

- (void)dataSource:(CKCollectionViewDataSource *)dataSource
    didChangeState:(CKDataSourceState *)previousState
         withState:(CKDataSourceState *)state;

@end
