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

@class CKDataSourceAppliedChanges;
@class CKDataSourceChangeset;
@class CKDataSourceState;

/** Immutable value object returned from objects adopting CKDataSourceStateModifying. */
@interface CKDataSourceChange : NSObject
- (instancetype)initWithState:(CKDataSourceState *)state
               appliedChanges:(CKDataSourceAppliedChanges *)appliedChanges
            deferredChangeset:(CKDataSourceChangeset *)deferredChangeset;
@property (nonatomic, strong, readonly) CKDataSourceState *state;
@property (nonatomic, strong, readonly) CKDataSourceAppliedChanges *appliedChanges;
/**
 * A changeset that should be applied immediately afterward.
 *
 * This is used to support split changesets, where a single changeset is split into multiple
 * changesets for the purpose of optimizing the performance of the initial render.
 */
@property (nonatomic, strong, readonly) CKDataSourceChangeset *deferredChangeset;
@end
