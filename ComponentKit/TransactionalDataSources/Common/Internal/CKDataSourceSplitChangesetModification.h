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

#import <ComponentKit/CKDefines.h>
#import <ComponentKit/CKDataSource.h>
#import <ComponentKit/CKDataSourceStateModifying.h>

#if CK_NOT_SWIFT

@class CKDataSourceChangeset;

@protocol CKComponentStateListener;

@interface CKDataSourceSplitChangesetModification : NSObject <CKDataSourceStateModifying>

- (instancetype)initWithChangeset:(CKDataSourceChangeset *)changeset
                    stateListener:(id<CKComponentStateListener>)stateListener
                         userInfo:(NSDictionary *)userInfo
                         viewport:(CKDataSourceViewport)viewport
                              qos:(CKDataSourceQOS)qos;

@property (nonatomic, readonly, strong) CKDataSourceChangeset *changeset;

@end

#endif
