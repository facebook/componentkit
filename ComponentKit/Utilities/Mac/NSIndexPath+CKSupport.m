/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "NSIndexPath+CKSupport.h"


@implementation NSIndexPath (CKSupport)

+ (NSIndexPath *)indexPathForItem:(NSInteger)item inSection:(NSInteger)section
{
  return [NSIndexPath indexPathWithIndexes:(const NSUInteger []){section, item} length:2];
}

- (NSInteger)section
{
  return [self indexAtPosition:0];
}

- (NSInteger)row
{
  return [self indexAtPosition:1];
}

- (NSInteger)item
{
  return [self indexAtPosition:1];
}


@end
