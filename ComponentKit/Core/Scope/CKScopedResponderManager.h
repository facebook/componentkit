// Copyright 2004-present Facebook. All Rights Reserved.

#import <ComponentKit/CKComponentScopeTypes.h>

typedef std::unordered_map<CKComponentScopeHandleIdentifier, __weak id> CKHandleToResponderMap;

@interface CKScopedResponderManager : NSObject

- (id)responderForIdentifier:(CKComponentScopeHandleIdentifier)handleIdentifier;
- (void)setResponderMap:(const CKHandleToResponderMap &)responderMap;

@end

