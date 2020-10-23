/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKAction_SwiftBridge.h>
#import <ComponentKit/CKDefines.h>
#import <ComponentKit/CKAction.h>

NS_ASSUME_NONNULL_BEGIN

#if CK_NOT_SWIFT

template <typename T>
using CKActionWithT_SwiftBridge = void (^)(T);

// MARK: To Objective-C

template <typename T, typename = std::enable_if_t<std::is_convertible<T, id>::value>>
CKAction<T> CKSwiftActionUnsafeBridgeToObjectiveC(CKActionWithT_SwiftBridge<T> _Null_unspecified action) {
  return CKAction<T>::actionFromSenderlessBlock(action);
}

template <typename T, typename = std::enable_if_t<!std::is_convertible<T, id>::value>>
CKAction<T> CKSwiftActionUnsafeBridgeToObjectiveC(CKActionWithT_SwiftBridge<id> _Null_unspecified action) {
  return CKAction<T>::actionFromSenderlessBlock(^(T param){
    action(@(param));
  });
}

inline CKAction<> CKSwiftActionUnsafeBridgeToObjectiveC(CKAction_SwiftBridge action) {
  return CKAction<>::actionFromSenderlessBlock(action);
}

// MARK: From Objective-C

template <typename T, typename = std::enable_if_t<std::is_convertible<T, id>::value>>
CKActionWithT_SwiftBridge<T> _Nonnull CKSwiftActionUnsafeBridgeFromObjectiveC(CKAction<T> action) {
  return ^(T param) {
    action.send(nil, param);
  };
}

template <typename T, typename = std::enable_if_t<!std::is_convertible<T, id>::value>>
CKActionWithT_SwiftBridge<id> _Nonnull CKSwiftActionUnsafeBridgeFromObjectiveC(CKAction<T> action) {
  return ^(T param) {
    action.send(nil, @(param));
  };
}

inline CKAction_SwiftBridge CKSwiftActionUnsafeBridgeFromObjectiveC(CKAction<> action) {
  return ^(){
    action.send(nil);
  };
}

#endif

NS_ASSUME_NONNULL_END
