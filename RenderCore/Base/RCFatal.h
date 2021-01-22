/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#if CK_NOT_SWIFT

static void RCCFatalWithCategory(NSExceptionName category, NSString *description, ...) {
  va_list args;
  va_start(args, description);
    [NSException
      raise:category
      format:description, args];
}

#endif
