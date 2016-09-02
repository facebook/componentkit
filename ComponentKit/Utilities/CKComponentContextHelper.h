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

struct CKComponentContextPreviousState {
  id key;
  id originalValue;
  id newValue;
};

/** Internal helper class. Do not attempt to use this externally. */
class CKComponentContextHelper {
  static CKComponentContextPreviousState store(id key, id object);
  static void restore(const CKComponentContextPreviousState &storeResult);
  static id fetch(id key);

  template<typename T>
  friend class CKComponentContext;
};
