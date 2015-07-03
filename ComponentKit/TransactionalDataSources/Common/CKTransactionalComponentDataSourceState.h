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

@class CKTransactionalComponentDataSourceConfiguration;
@class CKTransactionalComponentDataSourceItem;

/** Immutable state object */
@interface CKTransactionalComponentDataSourceState : NSObject

- (NSInteger)numberOfSections;

- (NSInteger)numberOfObjectsInSection:(NSInteger)section;

- (CKTransactionalComponentDataSourceItem *)objectAtIndexPath:(NSIndexPath *)indexPath;

typedef void(^CKTransactionalComponentDataSourceEnumerator)(CKTransactionalComponentDataSourceItem *, NSIndexPath *, BOOL *stop);

- (void)enumerateObjectsUsingBlock:(CKTransactionalComponentDataSourceEnumerator)block;

- (void)enumerateObjectsInSectionAtIndex:(NSInteger)section usingBlock:(CKTransactionalComponentDataSourceEnumerator)block;

/** The configuration used to generate this state object. */
@property (nonatomic, strong, readonly) CKTransactionalComponentDataSourceConfiguration *configuration;

@end
