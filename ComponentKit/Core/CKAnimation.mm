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

auto Animation::Initial::alpha() -> BasicInitial<CGFloat, _opacity> { return {}; }
auto Animation::Initial::translationY() -> BasicInitial<CGFloat, _transformTranslationY> { return {}; }
auto Animation::Initial::backgroundColor() -> BasicInitial<UIColor *, _backgroundColor> { return {}; }
auto Animation::Initial::borderColor() -> BasicInitial<UIColor *, _borderColor> { return {}; }

auto Animation::Final::alpha() -> BasicFinal<CGFloat, _opacity> { return {}; }
auto Animation::Final::translationY() -> BasicFinal<CGFloat, _transformTranslationY> { return {}; }
auto Animation::Final::backgroundColor() -> BasicFinal<UIColor *, _backgroundColor> { return {}; }
auto Animation::Final::borderColor() -> BasicFinal<UIColor *, _borderColor> { return {}; }

auto Animation::Change::alpha() -> BasicChange<CGFloat, _opacity> { return {}; }
auto Animation::Change::translationY() -> BasicChange<CGFloat, _transformTranslationY> { return {}; }
auto Animation::Change::position() -> BasicChange<CGPoint, _position> { return {}; };
auto Animation::Change::backgroundColor() -> BasicChange<UIColor *, _backgroundColor> { return {}; }
auto Animation::Change::borderColor() -> BasicChange<UIColor *, _borderColor> { return {}; }
