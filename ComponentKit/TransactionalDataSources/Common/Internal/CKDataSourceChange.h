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
@class CKDataSourceState;

/** Immutable value object returned from objects adopting CKDataSourceStateModifying. */
@interface CKDataSourceChange : NSObject
- (instancetype)initWithState:(CKDataSourceState *)state
               appliedChanges:(CKDataSourceAppliedChanges *)appliedChanges;
@property (nonatomic, strong, readonly) CKDataSourceState *state;
@property (nonatomic, strong, readonly) CKDataSourceAppliedChanges *appliedChanges;
@end
