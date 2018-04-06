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

#import <ComponentKit/CKInvalidChangesetOperationType.h>

@class CKDataSourceChangeset;
@class CKDataSourceState;

@protocol CKDataSourceStateModifying;

struct CKInvalidChangesetInfo {
    CKInvalidChangesetOperationType operationType;
    NSInteger section;
    NSInteger item;
};

CKInvalidChangesetInfo CKIsValidChangesetForState(CKDataSourceChangeset *changeset,
                                                  CKDataSourceState *state,
                                                  NSArray<id<CKDataSourceStateModifying>> *pendingAsynchronousModifications);
