/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKAnalyticsListenerHelpers.h"

#import <objc/runtime.h>

#if DEBUG
@implementation CKComponentReuseWrapper
{
  CKTreeNodeReuseMap _reusedNodesMaps;
}

- (instancetype)initWithReusedNodes:(const CKTreeNodeReuseMap &)reusedNodesMaps
{
  if (self = [super init]) {
    _reusedNodesMaps = reusedNodesMaps;
  }
  return self;
}

- (CKTreeNodeReuseMap &)reusedNodesMaps
{
  return _reusedNodesMaps;
}

- (NSUInteger)canBeReusedCounter:(CKTreeNodeIdentifier)nodeIdentifier
{
  auto it = _reusedNodesMaps.find(nodeIdentifier);
  if (it != _reusedNodesMaps.end()) {
    return it->second.reuseCounter;
  }
  return 0;
}
@end

static char const kReusedNodesKey = ' ';

namespace CKAnalyticsListenerHelpers {
  auto GetReusedNodes(NSObject *object) -> CKComponentReuseWrapper *
  {
    return objc_getAssociatedObject(object, &kReusedNodesKey);
  }
  auto SetReusedNodes(NSObject *object, CKComponentReuseWrapper *wrapper) -> void
  {
    objc_setAssociatedObject(object, &kReusedNodesKey, wrapper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
}
#endif
