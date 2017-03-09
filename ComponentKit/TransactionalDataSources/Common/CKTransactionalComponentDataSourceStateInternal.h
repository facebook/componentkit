/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKTransactionalComponentDataSourceState.h>

/** Internal interface since this class is usually only created internally. */
@interface CKTransactionalComponentDataSourceState ()

/**
 @param configuration The configuration used to generate this state object.
 @param sections An NSArray of NSArrays of CKTransactionalComponentDataSourceItem.
 */
- (instancetype)initWithConfiguration:(CKTransactionalComponentDataSourceConfiguration *)configuration
                             sections:(NSArray *)sections;

@property (nonatomic, copy, readonly) NSArray *sections;

@end
