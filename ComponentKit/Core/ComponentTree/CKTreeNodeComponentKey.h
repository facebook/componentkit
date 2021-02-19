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

#import <ComponentKit/CKDefines.h>
#import <RenderCore/RCEqualityHelpers.h>

#if CK_NOT_SWIFT

#include <vector>

NS_ASSUME_NONNULL_BEGIN

struct CKTreeNodeComponentKey {
  const char *componentTypeName;
  NSUInteger counter;
  _Nullable id identifier;
  std::vector<id<NSObject>> keys;

  auto operator==(const CKTreeNodeComponentKey& other) const -> bool {
    return componentTypeName == other.componentTypeName &&
      counter == other.counter &&
      RCObjectIsEqual(identifier, other.identifier) &&
      RCKeyVectorsEqual(keys, other.keys);
  }
};

NS_ASSUME_NONNULL_END

#endif
