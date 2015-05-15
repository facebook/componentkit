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

#if TARGET_OS_IPHONE
#error Mac Only
#endif


@interface NSIndexPath (CKSupport)

+ (NSIndexPath *)indexPathForItem:(NSInteger)item inSection:(NSInteger)section;

@property (nonatomic, readonly) NSInteger section;
@property (nonatomic, readonly) NSInteger row;
@property (nonatomic, readonly) NSInteger item;

@end
