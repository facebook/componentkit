// Copyright 2004-present Facebook. All Rights Reserved.

#import "CKAnimationComponentPassthroughView.h"

@implementation CKAnimationComponentPassthroughView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
  auto const v = [super hitTest:point withEvent:event];
  return v == self ? nil : v;
}

@end
