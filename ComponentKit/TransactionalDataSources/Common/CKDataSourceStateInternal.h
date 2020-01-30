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

#import <ComponentKit/CKDataSourceState.h>

/** Internal interface since this class is usually only created internally. */
@interface CKDataSourceState ()

/**
 @param configuration The configuration used to generate this state object.
 @param sections An NSArray of NSArrays of CKDataSourceItem.
 */
- (instancetype)initWithConfiguration:(CKDataSourceConfiguration *)configuration
                             sections:(NSArray *)sections;

@property (nonatomic, copy, readonly) NSArray *sections;

@end

#endif
