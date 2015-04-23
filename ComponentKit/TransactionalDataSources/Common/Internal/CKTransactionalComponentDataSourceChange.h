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

@class CKTransactionalComponentDataSourceAppliedChanges;
@class CKTransactionalComponentDataSourceState;

/** Immutable value object returned from objects adopting CKTransactionalComponentDataSourceStateModifying. */
@interface CKTransactionalComponentDataSourceChange : NSObject
- (instancetype)initWithState:(CKTransactionalComponentDataSourceState *)state
               appliedChanges:(CKTransactionalComponentDataSourceAppliedChanges *)appliedChanges;
@property (nonatomic, strong, readonly) CKTransactionalComponentDataSourceState *state;
@property (nonatomic, strong, readonly) CKTransactionalComponentDataSourceAppliedChanges *appliedChanges;
@end
