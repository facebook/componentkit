/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <UIKit/UIKit.h>

@class CKComponentLifecycleManager;

/**
 Protocol describing the behavior of an external object the CKComponentLifecycleManager can delegate asynchronous updates to.

 e.g: CKComponentDatasource currently implements this protocol and enqueue an asynchronous update for the corresponding item
 when notified by the CKComponentLifecycleManager.
 */
@protocol CKComponentLifecycleManagerAsynchronousUpdateHandler <NSObject>

- (void)handleAsynchronousUpdateForComponentLifecycleManager:(CKComponentLifecycleManager *)manager;

@end
