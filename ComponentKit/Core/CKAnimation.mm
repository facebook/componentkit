/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKAnimation.h"

using namespace CK;

auto Animation::functionToCA(Function f) -> CAMediaTimingFunction *
{
  switch (f) {
    case Function::easeOut:
      return [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    case Function::easeIn:
      return [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    case Function::linear:
      return [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
  }
}

auto Animation::alphaFrom(CGFloat from) -> InitialBuilder<CGFloat> { return {from, @"opacity"}; }
auto Animation::translationYFrom(CGFloat from) -> InitialBuilder<CGFloat> { return {from, @"transform.translation.y"}; }
auto Animation::backgroundColorFrom(UIColor *from) -> InitialBuilder<UIColor *> { return {from, @"backgroundColor"}; }
auto Animation::borderColorFrom(UIColor *from) -> InitialBuilder<UIColor *> { return {from, @"borderColor"}; }

auto Animation::alphaTo(CGFloat to) -> FinalBuilder<CGFloat> { return {to, @"opacity"}; }
auto Animation::translationYTo(CGFloat to) -> FinalBuilder<CGFloat> { return {to, @"transform.translation.y"}; }
auto Animation::backgroundColorTo(UIColor *to) -> FinalBuilder<UIColor *> { return {to, @"backgroundColor"}; }
auto Animation::borderColorTo(UIColor *to) -> FinalBuilder<UIColor *> { return {to, @"borderColor"}; }

auto Animation::alpha() -> ChangeBuilder { return {@"opacity"}; }
auto Animation::translationY() -> ChangeBuilder { return {@"transform.translation.y"}; }
auto Animation::position() -> ChangeBuilder { return {@"position"}; };
auto Animation::backgroundColor() -> ChangeBuilder { return {@"backgroundColor"}; }
auto Animation::borderColor() -> ChangeBuilder { return {@"borderColor"}; }
