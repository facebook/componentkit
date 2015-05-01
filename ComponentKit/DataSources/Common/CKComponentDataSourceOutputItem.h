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

#import <ComponentKit/CKComponentLifecycleManager.h>

@interface CKComponentDataSourceOutputItem : NSObject

- (instancetype)initWithLifecycleManager:(CKComponentLifecycleManager *)lifecycleManager
                   lifecycleManagerState:(const CKComponentLifecycleManagerState &)lifecycleManagerState
                                 oldSize:(CGSize)oldSize
                                   model:(id<NSObject>)model
                                    UUID:(NSString *)UUID;

@property (readonly, nonatomic, strong) CKComponentLifecycleManager *lifecycleManager;

- (const CKComponentLifecycleManagerState &)lifecycleManagerState;

@property (readonly, nonatomic, strong) id<NSObject> model;

@property (readonly, nonatomic, copy) NSString *UUID;

// In case of a update, this will contain the previous size
@property (readonly, nonatomic, assign) CGSize oldSize;

@end
