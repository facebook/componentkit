/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKTransactionalComponentDataSourceChangeset.h>

/** Internal interface since this class is usually only consumed internally. */
@interface CKTransactionalComponentDataSourceChangeset ()

@property (nonatomic, copy, readonly) NSDictionary *updatedItems;
@property (nonatomic, copy, readonly) NSSet *removedItems;
@property (nonatomic, copy, readonly) NSIndexSet *removedSections;
@property (nonatomic, copy, readonly) NSDictionary *movedItems;
@property (nonatomic, copy, readonly) NSIndexSet *insertedSections;
@property (nonatomic, copy, readonly) NSDictionary *insertedItems;
@property (nonatomic, copy, readonly) NSDictionary *userInfo;

@end
