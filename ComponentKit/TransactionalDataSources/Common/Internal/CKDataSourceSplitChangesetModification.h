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

#import <ComponentKit/CKDataSourceProtocol.h>
#import <ComponentKit/CKDataSourceStateModifying.h>

@class CKDataSourceChangeset;

@protocol CKComponentStateListener;

/**
 A changeset modification that is equivalent to `CKDataSourceChangesetModifcation`, with the addition of
 support for the experimental changeset splitting feature. When enabled, this automatically splits the changeset
 into two parts: one changeset for what's inside the viewport, and a deferred changeset for the part outside
 the viewport. This allows for parallelizing the mount of the components that are inside the viewport with the
 generation of components outside the viewport.
 */
@interface CKDataSourceSplitChangesetModification : NSObject <CKDataSourceStateModifying>

- (instancetype)initWithChangeset:(CKDataSourceChangeset *)changeset
                    stateListener:(id<CKComponentStateListener>)stateListener
                         userInfo:(NSDictionary *)userInfo
                         viewport:(CKDataSourceViewport)viewport
                              qos:(CKDataSourceQOS)qos;

@property (nonatomic, readonly, strong) CKDataSourceChangeset *changeset;

@end
