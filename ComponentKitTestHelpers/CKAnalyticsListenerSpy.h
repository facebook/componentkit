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

#import <ComponentKit/CKAnalyticsListener.h>

NS_ASSUME_NONNULL_BEGIN

@interface CKAnalyticsListenerSpy: NSObject <CKAnalyticsListener> {
  @package
  NSInteger _willLayoutComponentTreeHitCount;
  NSInteger _didLayoutComponentTreeHitCount;
  NSInteger _willCollectAnimationsHitCount;
  NSInteger _didCollectAnimationsHitCount;
  NSInteger _willMountComponentHitCount;
  NSInteger _didMountComponentHitCount;
  NSInteger _viewAllocationsCount;
}

@end

NS_ASSUME_NONNULL_END
