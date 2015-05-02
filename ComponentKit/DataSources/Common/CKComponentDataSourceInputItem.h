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

#import <ComponentKit/CKDimension.h>

@class CKComponentLifecycleManager;

@interface CKComponentDataSourceInputItem : NSObject

- (instancetype)initWithLifecycleManager:(CKComponentLifecycleManager *)lifecycleManager
                                   model:(id<NSObject>)model
                         constrainedSize:(CKSizeRange)constrainedSize
                                    UUID:(NSString *)UUID;

@property (readonly, nonatomic, strong) CKComponentLifecycleManager *lifecycleManager;

@property (readonly, nonatomic, strong) id<NSObject> model;

- (CKSizeRange)constrainedSize;

@property (readonly, nonatomic, copy) NSString *UUID;

@end
