/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKArrayControllerChangeType.h>

#import <ComponentKit/CKComponentDataSource.h>
#import <ComponentKit/CKComponentDataSourceDelegate.h>
#import <ComponentKit/CKComponentDataSourceOutputItem.h>

@interface CKComponentDataSourceTestDelegate : NSObject <CKComponentDataSourceDelegate>

@property (nonatomic, readonly) NSUInteger changeCount;
@property (nonatomic, readonly) NSArray *changes;

@property (nonatomic, copy) void (^onChange)(NSUInteger changeCount);

- (void)reset;

@end

@interface CKComponentDataSourceTestDelegateChange : NSObject

@property (nonatomic, strong) CKComponentDataSourceOutputItem *dataSourcePair;
@property (nonatomic, strong) CKComponentDataSourceOutputItem *oldDataSourcePair;
@property (nonatomic, assign) CKArrayControllerChangeType changeType;
@property (nonatomic, strong) NSIndexPath *sourceIndexPath;
@property (nonatomic, strong) NSIndexPath *destinationIndexPath;

@end
