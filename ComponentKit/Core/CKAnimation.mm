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

auto Animation::InitialBuilder::toCA() const -> CAAnimation *
{
  auto const a = [CABasicAnimation animationWithKeyPath:_keyPath];
  a.fromValue = _from;
  this->applyTimingTo(a);
  a.fillMode = kCAFillModeBackwards;
  return a;
}

auto Animation::FinalBuilder::toCA() const -> CAAnimation *
{
  auto const a = [CABasicAnimation animationWithKeyPath:_keyPath];
  a.toValue = _to;
  this->applyTimingTo(a);
  a.fillMode = kCAFillModeForwards;
  return a;
}

auto Animation::ChangeBuilder::toCA() const -> CAAnimation *
{
  auto const a = [CABasicAnimation animationWithKeyPath:_keyPath];
  this->applyTimingTo(a);
  if (delay > 0) {
    a.fillMode = kCAFillModeBackwards;
  }
  return a;
}

static auto animatedValueAsId(CGFloat f) -> id { return @(f); }
static auto animatedValueAsId(UIColor *c) -> id { return (id)c.CGColor; }

auto Animation::alphaFrom(CGFloat from) -> InitialBuilder { return {animatedValueAsId(from), @"opacity"}; }
auto Animation::translationXFrom(CGFloat from) -> InitialBuilder { return {animatedValueAsId(from), @"transform.translation.x"}; }
auto Animation::translationYFrom(CGFloat from) -> InitialBuilder { return {animatedValueAsId(from), @"transform.translation.y"}; }
auto Animation::backgroundColorFrom(UIColor *from) -> InitialBuilder { return {animatedValueAsId(from), @"backgroundColor"}; }
auto Animation::borderColorFrom(UIColor *from) -> InitialBuilder { return {animatedValueAsId(from), @"borderColor"}; }
auto Animation::scaleXFrom(CGFloat from) -> InitialBuilder { return {animatedValueAsId(from), @"transform.scale.x"}; }
auto Animation::scaleYFrom(CGFloat from) -> InitialBuilder { return {animatedValueAsId(from), @"transform.scale.y"}; }
auto Animation::scaleFrom(CGFloat from) -> InitialBuilder { return {animatedValueAsId(from), @"transform.scale"}; }
auto Animation::rotationFrom(CGFloat from) -> InitialBuilder { return {animatedValueAsId(from), @"transform.rotation"}; }

auto Animation::alphaTo(CGFloat to) -> FinalBuilder { return {animatedValueAsId(to), @"opacity"}; }
auto Animation::translationXTo(CGFloat to) -> FinalBuilder { return {animatedValueAsId(to), @"transform.translation.x"}; }
auto Animation::translationYTo(CGFloat to) -> FinalBuilder { return {animatedValueAsId(to), @"transform.translation.y"}; }
auto Animation::backgroundColorTo(UIColor *to) -> FinalBuilder { return {animatedValueAsId(to), @"backgroundColor"}; }
auto Animation::borderColorTo(UIColor *to) -> FinalBuilder { return {animatedValueAsId(to), @"borderColor"}; }
auto Animation::scaleXTo(CGFloat to) -> FinalBuilder { return {animatedValueAsId(to), @"transform.scale.x"}; }
auto Animation::scaleYTo(CGFloat to) -> FinalBuilder { return {animatedValueAsId(to), @"transform.scale.y"}; }
auto Animation::scaleTo(CGFloat to) -> FinalBuilder { return {animatedValueAsId(to), @"transform.scale"}; }
auto Animation::rotationTo(CGFloat to) -> FinalBuilder { return {animatedValueAsId(to), @"transform.rotation"}; }

auto Animation::alpha() -> ChangeBuilder { return {@"opacity"}; }
auto Animation::position() -> ChangeBuilder { return {@"position"}; };
auto Animation::backgroundColor() -> ChangeBuilder { return {@"backgroundColor"}; }
auto Animation::borderColor() -> ChangeBuilder { return {@"borderColor"}; }
