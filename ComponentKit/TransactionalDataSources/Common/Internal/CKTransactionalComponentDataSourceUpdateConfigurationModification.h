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

#import <ComponentKit/CKTransactionalComponentDataSourceStateModifying.h>

@class CKTransactionalComponentDataSourceConfiguration;

@interface CKTransactionalComponentDataSourceUpdateConfigurationModification : NSObject <CKTransactionalComponentDataSourceStateModifying>
- (instancetype)initWithConfiguration:(CKTransactionalComponentDataSourceConfiguration *)configuration
                             userInfo:(NSDictionary *)userInfo;
@end
