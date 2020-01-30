/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKDefines.h>

#if CK_NOT_SWIFT

#import <UIKit/UIKit.h>

#import <algorithm>
#import <array>

#import <ComponentKit/CKOptional.h>

@class CAAnimation;
@class CKComponent;

namespace CK {
  namespace Animation {
    enum class Type {
      initial,
      change,
      final
    };

    /**
     Represents one segment of a function that defines the pacing of an animation as a timing curve.
     */
    struct TimingCurve {
      using ControlPoint = std::array<float, 2>;

      TimingCurve(ControlPoint p1, ControlPoint p2) :_p1(p1), _p2(p2) {}

      static auto fromCA(NSString *name) -> TimingCurve;
      static auto fromCA(CAMediaTimingFunction *f) -> TimingCurve;

      auto toCA() const -> CAMediaTimingFunction *;

    private:
      ControlPoint _p1;
      ControlPoint _p2;
    };

    /**
     Represents the timing information for types of animations which have their durations calculated automatically.
     */
    template <typename Derived>
    struct TimingBuilderWithoutDuration {
      /**
       Specifies the delay after which the animation will start.

       @param t delay (in seconds).
       */
      auto &withDelay(CFTimeInterval t) { delay = t; return static_cast<Derived &>(*this); }
      /// Sets ease-in pacing for the animation
      auto &easeIn() { curve = TimingCurve::fromCA(kCAMediaTimingFunctionEaseIn); return static_cast<Derived &>(*this); }
      /// Sets ease-out pacing for the animation
      auto &easeOut() { curve = TimingCurve::fromCA(kCAMediaTimingFunctionEaseOut); return static_cast<Derived &>(*this); }
      /// Sets custom curve for the pacing of the animation
      auto &timingCurve(TimingCurve c) { curve = c; return static_cast<Derived &>(*this); }

      auto &timingCurveWithControlPoints(TimingCurve::ControlPoint p1, TimingCurve::ControlPoint p2)
      {
        curve = TimingCurve{p1, p2};
        return static_cast<Derived &>(*this);
      };

    protected:
      auto applyTimingTo(CAAnimation *a) const
      {
        a.beginTime = delay;
        a.timingFunction = curve.toCA();
      }

    public:
      /// Delay after which the animation will start
      CFTimeInterval delay = 0;
      /// Curve that defines the pacing of the animation
      TimingCurve curve = TimingCurve::fromCA(kCAMediaTimingFunctionLinear);
    };

    /**
     Represents the timing information an animations.
     */
    template <typename Derived>
    struct TimingBuilder {
      /**
       Specifies the duration of the animation.

       @param t duration (in seconds).
       */
      auto &withDuration(CFTimeInterval t) { duration = t; return static_cast<Derived &>(*this); }

      /**
       Specifies the delay after which the animation will start.

       @param t delay (in seconds).
       */
      auto &withDelay(CFTimeInterval t) { delay = t; return static_cast<Derived &>(*this); }

      /**
       Sets ease-in pacing for the animation with an optional duration.

       @note  This is just a shorthand for easeIn().withDuration()

       @param t duration (in seconds). Default is none.
       */
      auto &easeIn(Optional<CFTimeInterval> t = none)
      {
        curve = TimingCurve::fromCA(kCAMediaTimingFunctionEaseIn);
        t.apply([this](CFTimeInterval _t){ duration = _t; });
        return static_cast<Derived &>(*this);
      }

      /**
       Sets ease-out pacing for the animation with an optional duration.

       @note  This is just a shorthand for easeOut().withDuration()

       @param t duration (in seconds). Default is none.
       */
      auto &easeOut(Optional<CFTimeInterval> t = none)
      {
        curve = TimingCurve::fromCA(kCAMediaTimingFunctionEaseOut);
        t.apply([this](CFTimeInterval _t){ duration = _t; });
        return static_cast<Derived &>(*this);
      }

      /// Sets custom curve for the pacing of the animation
      auto &timingCurve(TimingCurve c) { curve = c; return static_cast<Derived &>(*this); }

      auto &timingCurveWithControlPoints(TimingCurve::ControlPoint p1, TimingCurve::ControlPoint p2)
      {
        curve = TimingCurve{p1, p2};
        return static_cast<Derived &>(*this);
      };

    protected:
      auto applyTimingTo(CAAnimation *a) const
      {
        duration.apply([a](const CFTimeInterval &t){ a.duration = t; });
        a.beginTime = delay;
        a.timingFunction = curve.toCA();
      }

    public:
      /**
       Duration of the animation.

       @note  If not set, the Core Animation default duration will be used (0.25s) when added directly to
              a layer or the duration of a parallel group will be used when added to such group.
       */
      Optional<CFTimeInterval> duration;
      /// Delay after which the animation will start
      CFTimeInterval delay = 0;
      /// Curve that defines the pacing of the animation
      TimingCurve curve = TimingCurve::fromCA(kCAMediaTimingFunctionLinear);
    };

    template <typename Derived>
    struct SpringParamBuilder {
      /**
       Defines how the spring’s motion should be damped due to the forces of friction.

       @discussion
       The default value of the damping property is 10. Reducing this value reduces the energy loss with each
       oscillation. Increasing the value increases the energy loss with each duration: there will be fewer and smaller
       oscillations.
       */
      auto &withDamping(CGFloat d) { _damping = d; return static_cast<Derived &>(*this); }

      /**
       The initial velocity of the object attached to the spring.

       @discussion
       Defaults to 0, which represents an unmoving object. Negative values represent the object moving away from the
       spring attachment point, positive values represent the object moving towards the spring attachment point.
       */
      auto &withInitialVelocity(CGFloat iv) { _initialVelocity = iv; return static_cast<Derived &>(*this); }

      /**
       The mass of the object attached to the end of the spring.

       @discussion
       The default mass is 1. Increasing this value will increase the spring effect: the attached object will be subject
       to more oscillations and greater overshoot. Decreasing the mass will reduce the spring effect: there will be
       fewer oscillations and a reduced overshoot.
       */
      auto &withMass(CGFloat m) { _mass = m; return static_cast<Derived &>(*this); }

      /**
       The spring stiffness coefficient.

       @discussion
       The default stiffness coefficient is 100. Increasing the stiffness reduces the number of oscillations and will
       reduce the duration. Decreasing the stiffness increases the the number of oscillations and will increase the
       duration.
       */
      auto &withStiffness(CGFloat s) { _stiffness = s; return static_cast<Derived &>(*this); }

    protected:
      auto applySpringTo(CASpringAnimation *a) const
      {
        _damping.apply([a](CGFloat d){ a.damping = d; });
        _initialVelocity.apply([a](CGFloat iv){ a.initialVelocity = iv; });
        _mass.apply([a](CGFloat m){ a.mass = m; });
        _stiffness.apply([a](CGFloat s){ a.stiffness = s; });
      }

      Optional<CGFloat> _damping;
      Optional<CGFloat> _initialVelocity;
      Optional<CGFloat> _mass;
      Optional<CGFloat> _stiffness;
    };

    /**
     A type that any initial animation can be implicitly converted to.
     */
    struct Initial {
      auto toCA() const { return _anim; }

    private:
      friend struct InitialBuilder;

      friend struct SpringInitialBuilder;

      template <typename A1, typename A2>
      friend struct SequenceBuilder;

      template <typename A1, typename A2>
      friend struct ParallelBuilder;

      explicit Initial(CAAnimation *anim) :_anim(anim) {}

      CAAnimation *_anim;
    };

    struct SpringInitialBuilder: TimingBuilderWithoutDuration<SpringInitialBuilder>, SpringParamBuilder<SpringInitialBuilder> {
      static constexpr auto type = Type::initial;

      SpringInitialBuilder(id from, __unsafe_unretained NSString *keyPath) : _from(from), _keyPath(keyPath) {}

      /// Returns a Core Animation animation corresponding to this animation.
      auto toCA() const -> CAAnimation *;

      operator CAAnimation *() const { return toCA(); }

      operator Initial() const { return Initial{toCA()}; }

    private:
      id _from;
      __unsafe_unretained NSString *_keyPath;
    };

    /**
     Represents an initial animation that animates from a specified `from` value to the current value of
     the property.
     */
    struct InitialBuilder: TimingBuilder<InitialBuilder> {
      static constexpr auto type = Type::initial;

      /**
       Specifies the initial value for the animated property.

       @param from the initial value
       */
      InitialBuilder(id from, __unsafe_unretained NSString *keyPath) :_from(from), _keyPath(keyPath) {}

      /// Makes this animation apply a spring-like force to the animated property.
      auto usingSpring() const -> SpringInitialBuilder;

      /// Returns a Core Animation animation corresponding to this animation.
      auto toCA() const -> CAAnimation *;

      operator CAAnimation *() const { return toCA(); }

      operator Initial() const { return Initial{toCA()}; }

    private:
      id _from;
      __unsafe_unretained NSString *_keyPath;
    };

    /**
     A type that any final animation can be implicitly converted to.
     */
    struct Final {
      auto toCA() const { return _anim; }

    private:
      friend struct FinalBuilder;

      template <typename A1, typename A2>
      friend struct SequenceBuilder;

      template <typename A1, typename A2>
      friend struct ParallelBuilder;

      explicit Final(CAAnimation *anim) :_anim(anim) {}

      CAAnimation *_anim;
    };

    /**
     Represents a final animation that animates from the current value of the property to the specified `to` value.
     */
    struct FinalBuilder: TimingBuilder<FinalBuilder> {
      static constexpr auto type = Type::final;

      /**
       Specifies the final value for the animated property.

       @param to the final value
       */
      FinalBuilder(id to, __unsafe_unretained NSString *keyPath) :_to(to), _keyPath(keyPath) {}

      /// Returns a Core Animation animation corresponding to this animation.
      auto toCA() const -> CAAnimation *;

      operator CAAnimation *() const { return toCA(); }

      operator Final() const { return Final{toCA()}; }

    private:
      id _to;
      __unsafe_unretained NSString *_keyPath;
    };

    /**
     A type that any change animation can be implicitly converted to.
     */
    struct Change {
      auto toCA() const { return _anim; }

    private:
      friend struct ChangeBuilder;

      friend struct SpringChangeBuilder;

      template <typename A1, typename A2>
      friend struct SequenceBuilder;

      template <typename A1, typename A2>
      friend struct ParallelBuilder;

      explicit Change(CAAnimation *anim) :_anim(anim) {}

      CAAnimation *_anim;
    };

    struct SpringChangeBuilder: TimingBuilderWithoutDuration<SpringChangeBuilder>, SpringParamBuilder<SpringChangeBuilder> {
      static constexpr auto type = Type::change;

      SpringChangeBuilder(__unsafe_unretained NSString *keyPath) :_keyPath(keyPath) {}

      /// Returns a Core Animation animation corresponding to this animation.
      auto toCA() const -> CAAnimation *;

      operator CAAnimation *() const { return toCA(); }

      operator Change() const { return Change{toCA()}; }

    private:
      __unsafe_unretained NSString *_keyPath;
    };

    /**
     Represents a change animation that animates between the previous and the current value of the property.
     */
    struct ChangeBuilder: TimingBuilder<ChangeBuilder> {
      static constexpr auto type = Type::change;

      ChangeBuilder(__unsafe_unretained NSString *keyPath) :_keyPath(keyPath) {}

      /// Makes this animation apply a spring-like force to the animated property.
      auto usingSpring() const -> SpringChangeBuilder;

      /// Returns a Core Animation animation corresponding to this animation.
      auto toCA() const -> CAAnimation *;

      operator CAAnimation *() const { return toCA(); }

      operator Change() const { return Change{toCA()}; }

    private:
      __unsafe_unretained NSString *_keyPath;
    };

    template <typename A1, typename A2, bool ShouldHaveDuration>
    struct ParallelBuilderBase {};

    template <typename A1, typename A2>
    struct ParallelBuilderBase<A1, A2, false> {
      template <typename Derived>
      using Type = TimingBuilderWithoutDuration<Derived>;
    };

    template <typename A1, typename A2>
    struct ParallelBuilderBase<A1, A2, true> {
      template <typename Derived>
      using Type = TimingBuilder<Derived>;
    };

    // If ParallelBuilder inherits from TimingBuilder (i.e. allows to set the duration explicitly), the duration from
    // TimingBuilder will be used.
    template <typename ParallelBuilder, std::enable_if_t<std::is_base_of<TimingBuilder<ParallelBuilder>, ParallelBuilder>::value, int> = 0>
    auto durationForParallelGroup(const ParallelBuilder &pb) -> CFTimeInterval
    {
      return pb.duration.valueOr(0);
    }

    // If ParallelBuilder inherits from TimingBuilderWithoutDuration (i.e. doesn't allow to set the duration explicitly)
    // the maximum duration among the two composed animations will be used.
    template <typename ParallelBuilder, std::enable_if_t<std::is_base_of<TimingBuilderWithoutDuration<ParallelBuilder>, ParallelBuilder>::value, int> = 0>
    auto durationForParallelGroup(const ParallelBuilder &pb) -> CFTimeInterval
    {
      return std::max(pb._a1.toCA().duration, pb._a2.toCA().duration);
    }

    /**
     Represents group of animations that run in parallel.
     */
    template <typename A1, typename A2>
    struct ParallelBuilder: ParallelBuilderBase<A1, A2, std::is_base_of<TimingBuilder<A1>, A1>::value && std::is_base_of<TimingBuilder<A2>, A2>::value>:: template Type<ParallelBuilder<A1, A2>> {
      static_assert(A1::type == A2::type, "Grouped animations must have the same type");
      static constexpr auto type = A1::type;

      ParallelBuilder(A1 a1, A2 a2)
      : _a1(std::move(a1)), _a2(std::move(a2)) {}

      /// Returns a Core Animation animation corresponding to this animation.
      auto toCA() const -> CAAnimation *
      {
        auto const g = [CAAnimationGroup new];
        g.animations = @[_a1.toCA(), _a2.toCA()];
        this->applyTimingTo(g);
        if (type == Type::initial || type == Type::change) {
          g.fillMode = kCAFillModeBackwards;
        }
        g.duration = durationForParallelGroup(*this);
        return g;
      }

      operator CAAnimation *() const { return toCA(); }

      using Any = std::conditional_t<type == Type::initial, Initial, std::conditional_t<type == Type::final, Final, Change>>;
      operator Any() const { return Any{toCA()}; }

    private:
      template <typename ParallelBuilder, std::enable_if_t<std::is_base_of<TimingBuilderWithoutDuration<ParallelBuilder>, ParallelBuilder>::value, int>>
      friend auto durationForParallelGroup(const ParallelBuilder &) -> CFTimeInterval;

      A1 _a1;
      A2 _a2;
    };

    /**
     Represents group of animations that run one after the other.
     */
    template <typename A1, typename A2>
    struct SequenceBuilder: TimingBuilderWithoutDuration<SequenceBuilder<A1, A2>> {
      static_assert(A1::type == A2::type, "Grouped animations must have the same type");
      static constexpr auto type = A1::type;

      SequenceBuilder(A1 a1, A2 a2)
      : _a1(std::move(a1)), _a2(std::move(a2)) {}

      /// Returns a Core Animation animation corresponding to this animation.
      auto toCA() const -> CAAnimation *
      {
        auto const g = [CAAnimationGroup new];
        auto const a1 = _a1.toCA();
        auto const a2 = _a2.toCA();
        g.animations = @[a1, a2];
        a2.beginTime = _a1.duration.valueOr(0.25);
        this->applyTimingTo(g);
        g.duration = _a1.duration.valueOr(0.25) + _a2.duration.valueOr(0.25);
        if (type == Type::initial) {
          g.fillMode = kCAFillModeBackwards;
        }
        return g;
      }

      operator CAAnimation *() const { return toCA(); }

      using Any = std::conditional_t<type == Type::initial, Initial, std::conditional_t<type == Type::final, Final, Change>>;
      operator Any() const { return Any{toCA()}; }

    private:
      A1 _a1;
      A2 _a2;
    };

    /// Returns an object that can be used to configure an initial animation of the opacity.
    auto alphaFrom(CGFloat from) -> InitialBuilder;
    /// Returns an object that can be used to configure an initial animation of the relative translation along the X axis.
    auto translationXFrom(CGFloat from) -> InitialBuilder;
    /// Returns an object that can be used to configure an initial animation of the relative translation along the Y axis.
    auto translationYFrom(CGFloat from) -> InitialBuilder;
    /// Returns an object that can be used to configure an initial animation of the background color.
    auto backgroundColorFrom(UIColor *from) -> InitialBuilder;
    /// Returns an object that can be used to configure an initial animation of the border color.
    auto borderColorFrom(UIColor *from) -> InitialBuilder;
    /// Returns an object that can be used to configure an initial animation of the scale along the X axis.
    auto scaleXFrom(CGFloat from) -> InitialBuilder;
    /// Returns an object that can be used to configure an initial animation of the scale along the Y axis.
    auto scaleYFrom(CGFloat from) -> InitialBuilder;
    /// Returns an object that can be used to configure an initial animation of the scale along all 3 axes.
    auto scaleFrom(CGFloat from) -> InitialBuilder;
    /// Returns an object that can be used to configure an initial animation of the rotation around the Z axis.
    auto rotationFrom(CGFloat from) -> InitialBuilder;

    /// Returns an object that can be used to configure a final animation of the opacity.
    auto alphaTo(CGFloat to) -> FinalBuilder;
    /// Returns an object that can be used to configure a final animation of the relative translation along the X axis.
    auto translationXTo(CGFloat to) -> FinalBuilder;
    /// Returns an object that can be used to configure a final animation of the relative translation along the Y axis.
    auto translationYTo(CGFloat to) -> FinalBuilder;
    /// Returns an object that can be used to configure a final animation of the background color.
    auto backgroundColorTo(UIColor *to) -> FinalBuilder;
    /// Returns an object that can be used to configure a final animation of the border color.
    auto borderColorTo(UIColor *to) -> FinalBuilder;
    /// Returns an object that can be used to configure an final animation of the scale along the X axis.
    auto scaleXTo(CGFloat to) -> FinalBuilder;
    /// Returns an object that can be used to configure an final animation of the scale along the Y axis.
    auto scaleYTo(CGFloat to) -> FinalBuilder;
    /// Returns an object that can be used to configure an final animation of the scale along all 3 axes.
    auto scaleTo(CGFloat to) -> FinalBuilder;
    /// Returns an object that can be used to configure an final animation of the rotation around the Z axis.
    auto rotationTo(CGFloat to) -> FinalBuilder;

    /// Returns an object that can be used to configure a change animation of the opacity.
    auto alpha() -> ChangeBuilder;
    /// Returns an object that can be used to configure a change animation of the absolute position.
    auto position() -> ChangeBuilder;
    /// Returns an object that can be used to configure a change animation of the background color.
    auto backgroundColor() -> ChangeBuilder;
    /// Returns an object that can be used to configure a change animation of the border color.
    auto borderColor() -> ChangeBuilder;

    /**
     Returns an animation that runs given animations in parallel.

     @param a1  the first animation
     @param a2  the second animation

     @note  You don't have to specify durations for the individual animations if they all have the same duration.
     Instead, this duration can be specified once for the whole group.

     @note  If one of the composed animations has its duration calculated automatically (e.g. a sequence animation), the
     resulting animation will also have its duration calculated automatically and it cannot be set explicitly.

     @code
     parallel(alpha(), position()).withDuration(0.5) // OK
     parallel(alpha(), sequence(position(), backgroundColor())).withDuration(0.5) // Error, sequence animation determines the duration

     @note  Only animations of the same type can grouped, i.e.

     @code
     parallel(alphaFrom(0), translationYFrom(-40)) // OK
     parallel(alphaTo(0), translationYFrom(-40)) // Error, can't group final and initial animation
     */
    template <typename A1, typename A2>
    auto parallel(A1 a1, A2 a2) { return ParallelBuilder<A1, A2>{ a1, a2 }; }

    /**
     Returns an animation that runs given animations one after the other.

     @param a1  the first animation
     @param a2  the second animation

     @note  The duration of the sequence will be calculated automatically as a sum of individual animation durations.
     It cannot be set explicitly. If an individual animation does not have a duration set, the Core Animation
     default (0.25s) will be used.

     @note  Only animations of the same type can grouped, i.e.

     @code
     sequence(alphaFrom(0), translationYFrom(-40)) // OK
     sequence(alphaTo(0), translationYFrom(-40)) // Error, can't group final and initial animation
     */
    template <typename A1, typename A2>
    auto sequence(A1 a1, A2 a2) { return SequenceBuilder<A1, A2>{ a1, a2 }; }
  }
}

#endif
