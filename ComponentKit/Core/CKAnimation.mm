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

auto Animation::TimingCurve::fromCA(NSString *name) -> TimingCurve
{
  return fromCA([CAMediaTimingFunction functionWithName:name]);
}

auto Animation::TimingCurve::fromCA(CAMediaTimingFunction *f) -> TimingCurve
{
  auto p1 = ControlPoint{};
  auto p2 = ControlPoint{};
  [f getControlPointAtIndex:1 values:p1.data()];
  [f getControlPointAtIndex:2 values:p2.data()];

  return {p1, p2};
}

auto Animation::TimingCurve::toCA() const -> CAMediaTimingFunction *
{
  return [CAMediaTimingFunction functionWithControlPoints:_p1[0] :_p1[1] :_p2[0] :_p2[1]];
}

auto Animation::SpringInitialBuilder::toCA() const -> CAAnimation *
{
  auto const a = [CASpringAnimation animationWithKeyPath:_keyPath];
  a.fromValue = _from;
  this->applyTimingTo(a);
  a.fillMode = kCAFillModeBackwards;
  this->applySpringTo(a);
  a.duration = a.settlingDuration;
  return a;
}

auto Animation::InitialBuilder::usingSpring() const -> SpringInitialBuilder
{
  auto spring = SpringInitialBuilder{_from, _keyPath};
  spring.delay = delay;
  spring.curve = curve;
  return spring;
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

auto Animation::SpringChangeBuilder::toCA() const -> CAAnimation *
{
  auto const a = [CASpringAnimation animationWithKeyPath:_keyPath];
  this->applyTimingTo(a);
  if (delay > 0) {
    a.fillMode = kCAFillModeBackwards;
  }
  this->applySpringTo(a);
  a.duration = a.settlingDuration;
  return a;
}

auto Animation::ChangeBuilder::usingSpring() const -> SpringChangeBuilder
{
  auto spring = SpringChangeBuilder{_keyPath};
  spring.delay = delay;
  spring.curve = curve;
  return spring;
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
