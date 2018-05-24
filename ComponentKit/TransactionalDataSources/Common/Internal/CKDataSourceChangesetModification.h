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

#import <ComponentKit/CKDataSourceStateModifying.h>

@class CKDataSourceChangeset;

@protocol CKComponentStateListener;

@interface CKDataSourceChangesetModification : NSObject <CKDataSourceStateModifying>

- (instancetype)initWithChangeset:(CKDataSourceChangeset *)changeset
                    stateListener:(id<CKComponentStateListener>)stateListener
                         userInfo:(NSDictionary *)userInfo;

- (instancetype)initWithChangeset:(CKDataSourceChangeset *)changeset
                    stateListener:(id<CKComponentStateListener>)stateListener
                         userInfo:(NSDictionary *)userInfo
                            queue:(dispatch_queue_t)queue;

@property (nonatomic, readonly, strong) CKDataSourceChangeset *changeset;

@end

namespace CK {
  auto invalidIndexesForInsertionInArray(NSArray *const a, NSIndexSet *const is) -> NSIndexSet *;
  auto invalidIndexesForRemovalFromArray(NSArray *const a, NSIndexSet *const is) -> NSIndexSet *;
}
