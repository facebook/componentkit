/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <vector>

@interface CKComponentAnnouncerBase ()
{
@public
/**
 Shared pointer (reference counted) of a vector listeners.
 We make this public, so it can be accessed from CK::AnnouncerHelper.

 We need it to be a shared pointer, since we want to be
 able atomically grab it for enumeration, even if someone
 else is modifying it in a different thread at the same time.
 We use a vector instead of a hash mainly for 2 reasons:
 1) dealing with __weak id as a key in a hash is more complicated
 2) we assume that the number of listeners is relatively small, and
    add/remove is not a frequent event.
 n.b. using boost::shared_ptr might lead to faster code, since it's lockless
 */
  std::shared_ptr<const std::vector<__weak id>> _listenerVector;
}
@end
