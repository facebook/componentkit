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

const char Animation::_opacity[] = "opacity";
const char Animation::_transformTranslationY[] = "transform.translation.y";
const char Animation::_position[] = "position";
const char Animation::_backgroundColor[] = "backgroundColor";
const char Animation::_borderColor[] = "borderColor";

auto Animation::alphaFrom(CGFloat from) -> InitialBuilder<CGFloat, _opacity> { return {from}; }
auto Animation::translationYFrom(CGFloat from) -> InitialBuilder<CGFloat, _transformTranslationY> { return {from}; }
auto Animation::backgroundColorFrom(UIColor *from) -> InitialBuilder<UIColor *, _backgroundColor> { return {from}; }
auto Animation::borderColorFrom(UIColor *from) -> InitialBuilder<UIColor *, _borderColor> { return {from}; }

auto Animation::alphaTo(CGFloat to) -> FinalBuilder<CGFloat, _opacity> { return {to}; }
auto Animation::translationYTo(CGFloat to) -> FinalBuilder<CGFloat, _transformTranslationY> { return {to}; }
auto Animation::backgroundColorTo(UIColor *to) -> FinalBuilder<UIColor *, _backgroundColor> { return {to}; }
auto Animation::borderColorTo(UIColor *to) -> FinalBuilder<UIColor *, _borderColor> { return {to}; }

auto Animation::alpha() -> ChangeBuilder<CGFloat, _opacity> { return {}; }
auto Animation::translationY() -> ChangeBuilder<CGFloat, _transformTranslationY> { return {}; }
auto Animation::position() -> ChangeBuilder<CGPoint, _position> { return {}; };
auto Animation::backgroundColor() -> ChangeBuilder<UIColor *, _backgroundColor> { return {}; }
auto Animation::borderColor() -> ChangeBuilder<UIColor *, _borderColor> { return {}; }
