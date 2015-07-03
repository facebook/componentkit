/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKTestStatefulViewComponent.h"

#import <ComponentKit/CKComponentScope.h>
#import <ComponentKit/CKStatefulViewComponentController.h>

@interface CKTestStatefulViewComponent ()
@property (nonatomic, strong) UIColor *color;
@end

@implementation CKTestStatefulViewComponent
+ (instancetype)newWithColor:(UIColor *)color
{
  CKComponentScope scope(self);
  CKTestStatefulViewComponent *c = [super newWithSize:{} accessibility:{}];
  if (c) {
    c->_color = color;
  }
  return c;
}
@end

@implementation CKTestStatefulViewComponentController

+ (UIView *)newStatefulView:(id)context
{
  return [[CKTestStatefulView alloc] init];
}

+ (void)configureStatefulView:(UIView *)statefulView forComponent:(CKComponent *)component
{
  statefulView.backgroundColor = [(CKTestStatefulViewComponent *)component color];
}

@end

@implementation CKTestStatefulView
@end
