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

#import <Foundation/Foundation.h>

#import <ComponentKit/CKDataSource.h>
#import <ComponentKit/CKDataSourceQOS.h>

@class CKDataSourceChangeset;

NS_ASSUME_NONNULL_BEGIN

/**
 `CKDataSourceChangesetApplicator` gives you the ability to apply a changeset off main queue.
 Initialize changeset applicator with main queue is discouraged since this is not optimized for it.
 */
@interface CKDataSourceChangesetApplicator : NSObject

/**
 @param dataSource The dataSource that changesets will be applied to.
 @param queue A serial queue that will be used for processing changeset, which includes components generation.
 Main queue is discouraged to be used here because changeset applicator is not optimized for it.
 Undefined behavior if a concurrent queue is passed in.
 */
- (instancetype)initWithDataSource:(CKDataSource *)dataSource
                             queue:(dispatch_queue_t)queue;

/**
 Changeset will be applied asynchronously if the call site is not on the same queue used for
 initializing the changeset applicator.
 Changeset might not be applied immediately if the changeset applicator is in the middle of
 applying other changeset.
 */
- (void)applyChangeset:(CKDataSourceChangeset *)changeset
              userInfo:(NSDictionary *)userInfo
                   qos:(CKDataSourceQOS)qos;

/**
 Viewport metrics used for calculating items that are in the viewport, when changeset splitting is enabled.
 */
- (void)setViewPort:(CKDataSourceViewport)viewport;

@end

NS_ASSUME_NONNULL_END

#endif
