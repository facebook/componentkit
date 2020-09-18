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
#import <ComponentKit/CKVariant.h>

NS_ASSUME_NONNULL_BEGIN

namespace CK {
namespace AnalyticsListenerSpy {
struct DidReceiveStateUpdate {
  CKComponentScopeHandle *handle;
  CKComponentScopeRootIdentifier rootID;
};

using Event = Variant<DidReceiveStateUpdate>;
}
}

@interface CKAnalyticsListenerSpy: NSObject <CKAnalyticsListener>

@property(atomic, readonly) NSInteger willBuildComponentTreeHitCount;
@property(atomic, readonly) NSInteger didBuildComponentTreeHitCount;
@property(atomic, readonly) NSInteger willLayoutComponentTreeHitCount;
@property(atomic, readonly) NSInteger didLayoutComponentTreeHitCount;
@property(atomic, readonly) NSInteger willCollectAnimationsHitCount;
@property(atomic, readonly) NSInteger didCollectAnimationsHitCount;
@property(atomic, readonly) NSInteger willMountComponentHitCount;
@property(atomic, readonly) NSInteger didMountComponentHitCount;
@property(atomic, readonly) NSInteger viewAllocationsCount;
@property(atomic, readonly) std::vector<CK::AnalyticsListenerSpy::Event> events;

@end

NS_ASSUME_NONNULL_END
