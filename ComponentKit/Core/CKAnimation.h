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
    struct Timing {
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
     Represents an initial animation that animates from a specified `from` value to the current value of
     the property.
     */
    template <typename V, const char *KeyPath>
    struct BasicInitial: Timing<BasicInitial<V, KeyPath>> {
      static constexpr auto type = Type::initial;

      /**
       Specifies the initial value for the animated property.

       @param v the initial value
       */
      auto &from(V v) { _from = v; return *this; }

      /// Returns a Core Animation animation corresponding to this animation.
      auto toCA() const -> CAAnimation *
      {
        auto const a = [CABasicAnimation animationWithKeyPath:@(KeyPath)];
        a.fromValue = _from.mapToPtr([](const V &v){ return @(v); });
        this->applyTimingTo(a);
        a.fillMode = kCAFillModeBackwards;
        return a;
      }

      operator CAAnimation *() const { return toCA(); }

    private:
      Optional<V> _from;
    };

    /**
     Represents a final animation that animates from the current value of the property to the specified `to` value.
     */
    template <typename V, const char *KeyPath>
    struct BasicFinal: Timing<BasicFinal<V, KeyPath>> {
      static constexpr auto type = Type::final;

      /**
       Specifies the final value for the animated property.

       @param v the final value
       */
      auto &to(V v) { _to = v; return *this; }

      /// Returns a Core Animation animation corresponding to this animation.
      auto toCA() const -> CAAnimation *
      {
        auto const a = [CABasicAnimation animationWithKeyPath:@(KeyPath)];
        a.toValue = _to.mapToPtr([](const V &v){ return @(v); });
        this->applyTimingTo(a);
        a.fillMode = kCAFillModeForwards;
        return a;
      }

      operator CAAnimation *() const { return toCA(); }

    private:
      Optional<V> _to;
    };

    /**
     Represents a change animation that animates between the previous and the current value of the property.
     */
    template <typename V, const char *KeyPath>
    struct BasicChange: Timing<BasicChange<V, KeyPath>> {
      static constexpr auto type = Type::change;

      /// Returns a Core Animation animation corresponding to this animation.
      auto toCA() const -> CAAnimation *
      {
        auto const a = [CABasicAnimation animationWithKeyPath:@(KeyPath)];
        this->applyTimingTo(a);
        return a;
      }

      operator CAAnimation *() const { return toCA(); }
    };

    /**
     Represents an initial animation that animates from a specified `from` value to the current value of
     the property.
     */
    template <const char *KeyPath>
    struct BasicInitial<UIColor *, KeyPath>: Timing<BasicInitial<UIColor *, KeyPath>> {
      static constexpr auto type = Type::initial;

      /**
       Specifies the initial value for the animated property.

       @param c the initial value
       */
      auto &from(UIColor *c) { _from = c; return *this; }

      /// Returns a Core Animation animation corresponding to this animation.
      auto toCA() const -> CAAnimation *
      {
        auto const a = [CABasicAnimation animationWithKeyPath:@(KeyPath)];
        a.fromValue = (id)_from.CGColor;
        this->applyTimingTo(a);
        a.fillMode = kCAFillModeBackwards;
        return a;
      }

      operator CAAnimation *() const { return toCA(); }

    private:
      UIColor *_from;
    };

    /**
     Represents a final animation that animates from the current value of the property to the specified `to` value.
     */
    template <const char *KeyPath>
    struct BasicFinal<UIColor *, KeyPath>: Timing<BasicFinal<UIColor *, KeyPath>> {
      static constexpr auto type = Type::final;

      /**
       Specifies the final value for the animated property.

       @param c the final value
       */
      auto &to(UIColor *c) { _to = c; return *this; }

      /// Returns a Core Animation animation corresponding to this animation.
      auto toCA() const -> CAAnimation *
      {
        auto const a = [CABasicAnimation animationWithKeyPath:@(KeyPath)];
        a.toValue = (id)_to.CGColor;
        this->applyTimingTo(a);
        a.fillMode = kCAFillModeForwards;
        return a;
      }

      operator CAAnimation *() const { return toCA(); }

    private:
      UIColor *_to;
    };

    /**
     Represents group of animations that run in parallel.
     */
    template <typename A1, typename A2>
    struct Parallel: Timing<Parallel<A1, A2>> {
      static_assert(A1::type == A2::type, "Grouped animations must have the same type");
      static constexpr auto type = A1::type;

      Parallel(A1 a1, A2 a2)
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

    private:
      A1 _a1;
      A2 _a2;
    };

    /**
     Represents group of animations that run one after the other.
     */
    template <typename A1, typename A2>
    struct Sequence: SequenceTiming<Sequence<A1, A2>> {
      static_assert(A1::type == A2::type, "Grouped animations must have the same type");
      static constexpr auto type = A1::type;

      Sequence(A1 a1, A2 a2)
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

    private:
      A1 _a1;
      A2 _a2;
    };

    extern const char _opacity[];
    extern const char _transformTranslationY[];
    extern const char _position[];
    extern const char _backgroundColor[];
    extern const char _borderColor[];

    namespace Initial {
      /// Returns an object that can be used to configure an initial animation of the opacity.
      auto alpha() -> BasicInitial<CGFloat, _opacity>;
      /// Returns an object that can be used to configure an initial animation of the relative translation along the Y axis.
      auto translationY() -> BasicInitial<CGFloat, _transformTranslationY>;
      /// Returns an object that can be used to configure an initial animation of the background color.
      auto backgroundColor() -> BasicInitial<UIColor *, _backgroundColor>;
      /// Returns an object that can be used to configure an initial animation of the border color.
      auto borderColor() -> BasicInitial<UIColor *, _borderColor>;
    }

    namespace Final {
      /// Returns an object that can be used to configure a final animation of the opacity.
      auto alpha() -> BasicFinal<CGFloat, _opacity>;
      /// Returns an object that can be used to configure a final animation of the relative translation along the Y axis.
      auto translationY() -> BasicFinal<CGFloat, _transformTranslationY>;
      /// Returns an object that can be used to configure a final animation of the background color.
      auto backgroundColor() -> BasicFinal<UIColor *, _backgroundColor>;
      /// Returns an object that can be used to configure a final animation of the border color.
      auto borderColor() -> BasicFinal<UIColor *, _borderColor>;
    }

    namespace Change {
      /// Returns an object that can be used to configure a change animation of the opacity.
      auto alpha() -> BasicChange<CGFloat, _opacity>;
      /// Returns an object that can be used to configure a change animation of the relative translation along the Y axis.
      auto translationY() -> BasicChange<CGFloat, _transformTranslationY>;
      /// Returns an object that can be used to configure a change animation of the absolute position.
      auto position() -> BasicChange<CGPoint, _position>;
      /// Returns an object that can be used to configure a change animation of the background color.
      auto backgroundColor() -> BasicChange<UIColor *, _backgroundColor>;
      /// Returns an object that can be used to configure a change animation of the border color.
      auto borderColor() -> BasicChange<UIColor *, _borderColor>;
    }

    /**
     Returns an animation that runs given animations in parallel.

     @param a1  the first animation
     @param a2  the second animation

     @note  You don't have to specify durations for the individual animations if they all have the same duration.
     Instead, this duration can be specified once for the whole group.

     @note  Only animations of the same type can grouped, i.e.

     @code
     parallel(Initial::alpha().from(0), Initial::translationY().from(-40)) // OK
     parallel(Final::alpha().to(0), Initial::translationY().from(-40)) // Error, can't group final and initial animation
     */
    template <typename A1, typename A2>
    auto parallel(A1 a1, A2 a2) { return Parallel<A1, A2>{ a1, a2 }; }

    /**
     Returns an animation that runs given animations one after the other.

     @param a1  the first animation
     @param a2  the second animation

     @note  The duration of the sequence will be calculated automatically as a sum of individual animation durations.
     It cannot be set explicitly. If an individual animation does not have a duration set, the Core Animation
     default (0.25s) will be used.

     @note  Only animations of the same type can grouped, i.e.

     @code
     sequence(Initial::alpha().from(0), Initial::translationY().from(-40)) // OK
     sequence(Final::alpha().to(0), Initial::translationY().from(-40)) // Error, can't group final and initial animation
     */
    template <typename A1, typename A2>
    auto sequence(A1 a1, A2 a2) { return Sequence<A1, A2>{ a1, a2 }; }
  }
}
