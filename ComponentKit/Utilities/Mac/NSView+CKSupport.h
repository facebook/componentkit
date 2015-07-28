/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKPlatform.h>

@interface NSView (CKSupport)

@property (nonatomic, strong) NSColor *backgroundColor;

@property (nonatomic, assign) BOOL clipsToBounds;

- (void)setNeedsLayout;

// No-op
- (void)layoutSubviews;

- (void)exchangeSubviewAtIndex:(NSInteger)index1 withSubviewAtIndex:(NSInteger)index2;

@end


inline NSString *NSStringFromUIEdgeInsets(NSEdgeInsets insets) {
  return [NSString stringWithFormat:@"{%.2lf, %.2lf, %.2lf, %.2lf}", insets.top, insets.left, insets.bottom, insets.right];
};