/*
*  Copyright (c) 2014-present, Facebook, Inc.
*  All rights reserved.
*
*  This source code is licensed under the BSD-style license found in the
*  LICENSE file in the root directory of this source tree. An additional grant
*  of patent rights can be found in the PATENTS file in the same directory.
*
*/

#import <ComponentKit/CKExceptionInfo.h>

#if CK_NOT_SWIFT

struct CKExceptionInfoScopedValue {
  CKExceptionInfoScopedValue() = delete;
  CKExceptionInfoScopedValue(const CKExceptionInfoScopedValue &) = delete;
  auto operator =(const CKExceptionInfoScopedValue &) -> CKExceptionInfoScopedValue & = delete;

  CKExceptionInfoScopedValue(NSString *key, NSString *value) : _key{key}
  {
    CKExceptionInfoSetValueForKeyTruncating(key, value);
  }

  ~CKExceptionInfoScopedValue()
  {
    CKExceptionInfoSetValueForKeyTruncating(_key, nil);
  }

private:
  /// CKExceptionInfoSetValueForKeyTruncating can potentially expand to nothing, making \c _key unused.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-private-field"
  NSString *_key;
#pragma clang diagnostic pop
};

#endif
