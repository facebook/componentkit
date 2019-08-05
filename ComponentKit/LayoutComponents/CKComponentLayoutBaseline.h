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

/**
 Set a key value pair using this in CKComponentLayout.extra for a custom baseline. The component which uses this property should also override @{usesCustomBaseline} to return YES.
 e.g. @{kCKComponentLayoutExtraBaselineKey : 20}
 */

__BEGIN_DECLS

extern NSString *const kCKComponentLayoutExtraBaselineKey;

__END_DECLS
