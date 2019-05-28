/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <UIKit/UIKit.h>

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
    enum class Function {
      /// Linear pacing, which causes an animation to occur evenly over its duration.
      linear,
      /// Ease-in pacing, which causes an animation to begin slowly and then speed up as it progresses.
      easeIn,
      /// Ease-out pacing, which causes an animation to begin quickly and then slow down as it progresses.
      easeOut
    };

    auto functionToCA(Function f) -> CAMediaTimingFunction *;

    /**
     Represents the timing information for a sequence of two animations.
     */
    template <typename Derived>
    struct SequenceTiming {
      /**
       Specifies the delay after which the animation will start.

       @param t delay (in seconds).
       */
      auto &withDelay(CFTimeInterval t) { delay = t; return static_cast<Derived &>(*this); }
      /// Sets ease-in pacing for the animation
      auto &easeIn() { function = Function::easeIn; return static_cast<Derived &>(*this); }
      /// Sets ease-out pacing for the animation
      auto &easeOut() { function = Function::easeOut; return static_cast<Derived &>(*this); }

    protected:
      auto applyTimingTo(CAAnimation *a) const
      {
        a.beginTime = delay;
        a.timingFunction = functionToCA(function);
      }

    public:
      /// Delay after which the animation will start
      CFTimeInterval delay = 0;
      /// Function that defines the pacing of the animation
      Function function = Function::linear;
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
        function = Function::easeIn;
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
        function = Function::easeOut;
        t.apply([this](CFTimeInterval _t){ duration = _t; });
        return static_cast<Derived &>(*this);
      }

    protected:
      auto applyTimingTo(CAAnimation *a) const
      {
        duration.apply([a](const CFTimeInterval &t){ a.duration = t; });
        a.beginTime = delay;
        a.timingFunction = functionToCA(function);
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
      /// Function that defines the pacing of the animation
      Function function = Function::linear;
    };

    /**
     A type that any initial animation can be implicitly converted to.
     */
    struct Initial {
      auto toCA() const { return _anim; }

    private:
      friend struct InitialBuilder;

      template <typename A1, typename A2>
      friend struct SequenceBuilder;

      template <typename A1, typename A2>
      friend struct ParallelBuilder;

      explicit Initial(CAAnimation *anim) :_anim(anim) {}

      CAAnimation *_anim;
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

      /// Returns a Core Animation animation corresponding to this animation.
      auto toCA() const -> CAAnimation *
      {
        auto const a = [CABasicAnimation animationWithKeyPath:_keyPath];
        a.fromValue = _from;
        this->applyTimingTo(a);
        a.fillMode = kCAFillModeBackwards;
        return a;
      }

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
      auto toCA() const -> CAAnimation *
      {
        auto const a = [CABasicAnimation animationWithKeyPath:_keyPath];
        a.toValue = _to;
        this->applyTimingTo(a);
        a.fillMode = kCAFillModeForwards;
        return a;
      }

      operator CAAnimation *() const { return toCA(); }

      operator Final() const { return Final{toCA()}; }

    private:
      id _to;
      __unsafe_unretained NSString *_keyPath;
    };

    /**
     Represents a change animation that animates between the previous and the current value of the property.
     */
    struct ChangeBuilder: TimingBuilder<ChangeBuilder> {
      static constexpr auto type = Type::change;

      ChangeBuilder(__unsafe_unretained NSString *keyPath) :_keyPath(keyPath) {}

      /// Returns a Core Animation animation corresponding to this animation.
      auto toCA() const -> CAAnimation *
      {
        auto const a = [CABasicAnimation animationWithKeyPath:_keyPath];
        this->applyTimingTo(a);
        return a;
      }

      operator CAAnimation *() const { return toCA(); }

    private:
      __unsafe_unretained NSString *_keyPath;
    };

    /**
     Represents group of animations that run in parallel.
     */
    template <typename A1, typename A2>
    struct ParallelBuilder: TimingBuilder<ParallelBuilder<A1, A2>> {
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
        if (type == Type::initial) {
          g.fillMode = kCAFillModeBackwards;
        }
        return g;
      }

      operator CAAnimation *() const { return toCA(); }

      using Any = std::conditional_t<type == Type::initial, Initial, std::conditional_t<type == Type::final, Final, void>>;
      operator Any() const { return Any{toCA()}; }

    private:
      A1 _a1;
      A2 _a2;
    };

    /**
     Represents group of animations that run one after the other.
     */
    template <typename A1, typename A2>
    struct SequenceBuilder: SequenceTiming<SequenceBuilder<A1, A2>> {
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

      using Any = std::conditional_t<type == Type::initial, Initial, std::conditional_t<type == Type::final, Final, void>>;
      operator Any() const { return Any{toCA()}; }

    private:
      A1 _a1;
      A2 _a2;
    };

    /// Returns an object that can be used to configure an initial animation of the opacity.
    auto alphaFrom(CGFloat from) -> InitialBuilder;
    /// Returns an object that can be used to configure an initial animation of the relative translation along the Y axis.
    auto translationYFrom(CGFloat from) -> InitialBuilder;
    /// Returns an object that can be used to configure an initial animation of the background color.
    auto backgroundColorFrom(UIColor *from) -> InitialBuilder;
    /// Returns an object that can be used to configure an initial animation of the border color.
    auto borderColorFrom(UIColor *from) -> InitialBuilder;

    /// Returns an object that can be used to configure a final animation of the opacity.
    auto alphaTo(CGFloat to) -> FinalBuilder;
    /// Returns an object that can be used to configure a final animation of the relative translation along the Y axis.
    auto translationYTo(CGFloat to) -> FinalBuilder;
    /// Returns an object that can be used to configure a final animation of the background color.
    auto backgroundColorTo(UIColor *to) -> FinalBuilder;
    /// Returns an object that can be used to configure a final animation of the border color.
    auto borderColorTo(UIColor *to) -> FinalBuilder;

    /// Returns an object that can be used to configure a change animation of the opacity.
    auto alpha() -> ChangeBuilder;
    /// Returns an object that can be used to configure a change animation of the relative translation along the Y axis.
    auto translationY() -> ChangeBuilder;
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
