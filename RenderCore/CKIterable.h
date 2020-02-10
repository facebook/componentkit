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

NS_ASSUME_NONNULL_BEGIN

@protocol CKIterable <NSObject>

#if CK_NOT_SWIFT

/** Number of children; can be 0 for leaves */
- (unsigned int)numberOfChildren;

/** Get child at index */
- (id<CKIterable> _Nullable)childAtIndex:(unsigned int)index;

#endif

@end

NS_ASSUME_NONNULL_END
