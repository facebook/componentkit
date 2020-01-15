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

@class CKDataSourceConfiguration;
@class CKDataSourceItem;

/** Immutable state object */
@interface CKDataSourceState : NSObject

- (NSInteger)numberOfSections;

- (NSInteger)numberOfObjectsInSection:(NSInteger)section;

- (CKDataSourceItem *)objectAtIndexPath:(NSIndexPath *)indexPath;

typedef void(^CKDataSourceEnumerator)(CKDataSourceItem *, NSIndexPath *, BOOL *stop);

- (void)enumerateObjectsUsingBlock:(CKDataSourceEnumerator)block;

- (void)enumerateObjectsInSectionAtIndex:(NSInteger)section usingBlock:(CKDataSourceEnumerator)block;

/** The configuration used to generate this state object. */
@property (nonatomic, strong, readonly) CKDataSourceConfiguration *configuration;

/** A string somewhat uniquely identifying this state object contents. */
@property (nonatomic, strong, readonly) NSString *contentsFingerprint;

@end
