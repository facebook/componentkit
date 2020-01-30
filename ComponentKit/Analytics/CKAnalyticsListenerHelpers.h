/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKDefines.h>

#if CK_NOT_SWIFT

#import <Foundation/Foundation.h>

#import <ComponentKit/CKAnalyticsListener.h>

#if DEBUG
// Wrapper class around the data that is coming from CKDebugAnalyticsListener
@interface CKComponentReuseWrapper : NSObject
- (instancetype)initWithReusedNodes:(const CKTreeNodeReuseMap &)reusedNodesMaps;
- (CKTreeNodeReuseMap &)reusedNodesMaps;
- (NSUInteger)canBeReusedCounter:(CKTreeNodeIdentifier)nodeIdentifier;
@end

namespace CKAnalyticsListenerHelpers {
  auto GetReusedNodes(NSObject *object) -> CKComponentReuseWrapper *;
  auto SetReusedNodes(NSObject *object, CKComponentReuseWrapper *wrapper) -> void;
}
#endif

#endif
