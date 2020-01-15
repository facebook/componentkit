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

@class CKComponentController;
@class CKDataSourceAppliedChanges;
@class CKDataSourceChangeset;
@class CKDataSourceState;

/** Immutable value object returned from objects adopting CKDataSourceStateModifying. */
@interface CKDataSourceChange : NSObject
- (instancetype)initWithState:(CKDataSourceState *)state
                previousState:(CKDataSourceState *)previousState
               appliedChanges:(CKDataSourceAppliedChanges *)appliedChanges
             appliedChangeset:(CKDataSourceChangeset *)appliedChangeset
            deferredChangeset:(CKDataSourceChangeset *)deferredChangeset
    addedComponentControllers:(NSArray<CKComponentController *> *)addedComponentControllers
  invalidComponentControllers:(NSArray<CKComponentController *> *)invalidComponentControllers;
@property (nonatomic, strong, readonly) CKDataSourceState *state;
@property (nonatomic, strong, readonly) CKDataSourceState *previousState;
@property (nonatomic, strong, readonly) CKDataSourceAppliedChanges *appliedChanges;
@property (nonatomic, strong, readonly) CKDataSourceChangeset *appliedChangeset;
/**
 * A changeset that should be applied immediately afterward.
 *
 * This is used to support split changesets, where a single changeset is split into multiple
 * changesets for the purpose of optimizing the performance of the initial render.
 */
@property (nonatomic, strong, readonly) CKDataSourceChangeset *deferredChangeset;
/**
 Component controllers that are only present in the new state.
 */
@property (nonatomic, strong, readonly) NSArray<CKComponentController *> *addedComponentControllers;
/**
 Component controllers that are not presented in the new state.
 */
@property (nonatomic, strong, readonly) NSArray<CKComponentController *> *invalidComponentControllers;

@end
