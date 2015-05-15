/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "NSView+CKSupport.h"

@implementation NSView (CKSupport)

@dynamic backgroundColor;

- (void)layoutSubviews
{
}

- (void)setNeedsLayout
{
  [self setNeedsLayout:YES];
}

- (void)exchangeSubviewAtIndex:(NSInteger)index1 withSubviewAtIndex:(NSInteger)index2
{
  // TODO: use a sort function instead of this hack
  NSMutableArray *subviews = [self.subviews mutableCopy];
  [subviews exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
  self.subviews = [subviews copy];
}

@end