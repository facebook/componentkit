// Copyright 2004-present Facebook. All Rights Reserved.

#import <mutex>

#import "CKAssert.h"
#import "CKScopedResponderManager.h"

@implementation CKScopedResponderManager
{
  std::shared_ptr<const CKHandleToResponderMap> _responderMap;
  std::mutex _accessMutex;
}

- (id)responderForIdentifier:(CKComponentScopeHandleIdentifier)handleIdentifier
{
  std::lock_guard<std::mutex> l(_accessMutex);
  
  if (_responderMap != nullptr) {
    auto result = _responderMap->find(handleIdentifier);
    if (result != _responderMap->end()) {
      return result->second;
    }
  }
  
  return nil;
}

- (void)setResponderMap:(const CKHandleToResponderMap &)responderMap
{
  std::lock_guard<std::mutex> l(_accessMutex);
  _responderMap = std::make_shared<CKHandleToResponderMap>(responderMap);
}

@end
