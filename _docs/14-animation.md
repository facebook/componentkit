---
title: Animation 
layout: docs
permalink: /docs/animation.html
---

# Summary

ComponentKit exposes three ways to perform animations on a component.

## animationsOnInitialMount

Override this method to specify how to animate the initial appearance of a component:

{% highlight objc %}
- (std::vector<CKComponentAnimation>)animationsOnInitialMount
{
    return { {self, fadeToAppear()} };
}

static CAAnimation *fadeToAppear()
{
  CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
  fade.fromValue = @(0);
  fade.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
  fade.duration = 0.5;
  return fade;
}
{% endhighlight %}

## animationsFromPreviousComponent:

Override this method to specify how to animate between two versions of a component. Here's an example from the example app:

{% highlight objc %}
- (std::vector<CKComponentAnimation>)animationsFromPreviousComponent:(InteractiveQuoteComponent *)previousComponent
{
  if (previousComponent->_overlay == nil && _overlay != nil) {
    return { {_overlay, scaleToAppear()} }; // Scale the overlay in when it appears.
  } else {
    return {};
  }
}

static CAAnimation *scaleToAppear()
{
  CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform"];
  scale.fromValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.0, 0.0, 0.0)];
  scale.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
  scale.duration = 0.2;
  return scale;
}
{% endhighlight %}

## boundsAnimationFromPreviousComponent:

Override this method to specify how the top-level bounds of a component should animate inside a `UICollectionView`. For example, if you were implementing an expandable article component that changes its height, you could specify a spring animation for changing the cell bounds:

{% highlight objc %}
- (CKComponentBoundsAnimation)boundsAnimationFromPreviousComponent:(ArticleComponent *)previousComponent
{
  if (previousComponent->_state == ArticleComponentStateCollapsed && _state == ArticleComponentStateExpanded) {
    return {
      .mode = CKComponentBoundsAnimationModeSpring,
      .duration = 0.5,
      .springDampingRatio = 0.7,
      .springInitialVelocity = 1.0,
    };
  } else {
    return {};
  }
}
{% endhighlight %}

## Notes

**If you implement either method, your component must have a [scope](scopes.html).**

If updating your component's [state](state.html) changes it's bounds, both `boundsAnimationFromPreviousComponent` and `animationsFromPreviousComponent` will be called. 

## In-depth

### UIKit Animations

Engineers on iOS are used to the simple UIView implicit animations. Here’s what they look like:

{% highlight objc %}
UIView *view = ...;
[UIView animateWithDuration:0.3 animations:^{
	view.frame = CGRectMake(50, 50, view.frame.size.width, view.frame.size.height);
}];
{% endhighlight %}

With this little bit of code, we’ve taken a UIView and changed its frame’s origin to be (50, 50), and animate it along a straight line to the new position. By making the change within a block, UIKit is able to record mutations to its model data and forms a transaction that it bundles into an animation for the render server lasting 300 ms. from the view’s current position to its new position.

There are all kinds of properties the developer can animate with this API: alpha, scale, rotation, Z position. Implicit animations can control their durations, easing curves, and can specify that the animated property should begin at its current display or model properties.

This API is used for the majority of animations that you see in apps on iOS.

#### CoreAnimation

CoreAnimation is the underlying rendering engine that is used on iOS and most of Mac OS to render contents on the screen using Metal. It operates in a different process from our app. It has its own representations of all the layers on the screen, and their current properties, as displayed to the user. Mutations to the views and layers inside our app get packaged into a transaction which are transmitted to the render server through a special-purpose IPC bridge.

This architecture is largely responsible for the “smoothness” of iOS apps. Animations are packaged into a declaration of the intended effects, and are usually conducted on the render server directly. This means that although our main thread may be blocked, we can still animate content around the screen.

Of course, this only works without our process’ involvement if there isn’t active user input that triggers the animation. For instance, scroll animations are triggered and can be interrupted at every frame by the user. This means that the animation actually has to be marshaled by the UIThread within our process, and what makes scroll performance such a difficult challenge.

#### CALayer

UIKit uses UIView as its fundamental drawing object. This view can have child views, and manages their positioning. Views are responsible for handling touches and events, and form part of the chain of responders for things like text entry or accessibility gestures.

These views don’t really know that much about rendering though. There is the convenience drawRect: method that is exposed to subclasses of UIView, but its use is discouraged. Instead, each UIView is paired with a CALayer which actually hosts its content for consumption by the render server. These CALayers form the in-process representation of the data being displayed to the user.

#### CAAnimation

CAAnimation is the base-class that explicit CoreAnimation animations use to declare what effects they have on CALayers. There are a number of default animation types: property animations, basic animations, keyframe animations, spring animations, transition animations, and grouped animations. Each serves its own purpose, and can be combined together to achieve extremely complex effects.

Animations are stringly-typed transformations which can keyframe and change any exposed property that is used by the render server to display content to the user. The use of these animations are much more verbose than the UIView variants, but they are declarative and explicit instead of implicit. Ultimately UIView implicit animations are translated into CAAnimations under the hood, so they both do the same things on the render server.

#### POP

POP was a framework we wrote for Paper which manages in-process animations using a CAAnimation-like API. It’s specifically designed for user-interruptible animations that are managed using a display link which lets us alter display properties at the natural refresh rate of the screen. The use of POP animations looks almost identical to CAAnimations, but are designed from the start to be interruptible and alterable.

Use of POP requires a free main thread since it animates the layers on what is basically a timer. If the main thread is blocked while an animation is active, the updates will just be dropped until the main thread is freed up. To the user, this means the animation stutters, frames are dropped.

## Animations in ComponentKit

Now that the basics are covered, let’s talk about what we wanted to achieve with animations in ComponentKit, then we’ll talk about what makes this such a difficult proposition.

### Goals of animation support

The initial goal of the animations support in ComponentKit was to allow implementation of the simple animations present in feeds of content. The API that we wanted should:

1. Allow animation of any view-based component.
2. Allow animations in bounds changes.
3. Be similar enough to standard animation practices in iOS to be familiar to iOS engineers.
4. Support arbitrary animation types.
5. Be managed by the framework, such that reuse errors are rare.

### What makes animations difficult in CK?

Before I dig into the internals of CKComponentAnimation and the APIs on CKComponent, let’s just take a step back and understand why this is so difficult.

CKComponent forms a declarative mapping from model to view configuration. This mapping is computed and laid out on a background thread, then the resulting transaction is applied on the main thread. Generally, you do not directly configure your views, instead you build a configuration you want applied, and views are reused for you in an optimal manner.

Initially we said that animations should be handled fully in the view layer instead of inside Components (and that’s still a good rule of thumb for complex animations), but eventually people started wanting to do simple animations without having to build a custom view.

With the ComponentKit model, there is no good place for you to do your imperative animations inside the components. Components themselves are not long-lived, which means that they are constantly recycled. Of course you could do it in your CKComponentController, but if you forget to un-apply the animation, then you could easily leave it animating around the screen when the view is reused, resulting in a maddening reuse problem (goal 5 above).

### CKComponentAnimation

The core of the ComponentKit animation API is a declaration of the animations you would like to conduct in response to some action. This declaration is encapsulated in a `CKComponentAnimation`, which is a C++ struct that contains either:

1. A packaged CAAnimation, and a target component.
2. A completely custom animation.

The first type allows a component to apply a CAAnimation to the view (really, its layer) that backs a CKComponent. This means that components that wish to animate (in other words, they are the target of a CKComponentAnimation) must have a view, or in the case of a CKCompositeComponent, must render to a component that has a view.

The second type of animation allows you to configure any type of animation that you like, so long as it understands how to apply, un-apply, and update the animation in response to component changes. This is the escape hatch that allows things like POP to work with component animations.

## Types of animations

The framework divides animations into these three groupings:

1. Initial animations. These are for things like a fade in when the component first appears.
2. Lifecycle-based animations. Used to transition a component to a new state from an old one.
3. Bounds animations. Since sizing of cells is managed by the ComponentKit infrastructure, anything that alters the bounds of your component in relation to its parent will force a reflow of the collection view. This means it has to be managed via a special API.

Each of these animation types is supported through a separate method that subclasses of CKComponent may override to return a declarative list of its animations.

### Initial animations

Initial animations are probably the simplest conceptually. A CKComponent may provide initial animations by overriding to this method:

{% highlight objc %}
- (std::vector<CKComponentAnimation>)animationsOnInitialMount;
{% endhighlight %}

A component may return *multiple* animations. So for instance, it could provide a fade-in in addition to a spring effect.

Returning to the example above:

{% highlight objc %}
- (std::vector<CKComponentAnimation>)animationsOnInitialMount
{
    return { {self, fadeToAppear()} };
}
{% endhighlight %}

This returns a single fade-in animation that will apply to the component when it is mounted *for the first time*.

### Lifecycle-based animations

Let's say that you have a button that needs to bounce a little bit when it is selected. This is a great example of where you'd want to use a lifecycle-based animation. These animations allow you to animate a transition from one component state to another. They differ from initial animations, since the component *has* to already exist and be mounted to animate.

Here's the method you override to return your animations:

{% highlight objc %}
- (std::vector<CKComponentAnimation>)animationsFromPreviousComponent:(CKComponent *)previousComponent;
{% endhighlight %}

Again, the component may return multiple animations from the previous version of the component. The key thing here is that you're given the previous version of the component to compare with, and only if you want to animate the change should you return something.

Returning to the example above:

{% highlight objc %}
- (std::vector<CKComponentAnimation>)animationsFromPreviousComponent:(InteractiveQuoteComponent *)previousComponent
{
  if (previousComponent->_overlay == nil && _overlay != nil) {
    return { {_overlay, scaleToAppear()} }; // Scale the overlay in when it appears.
  } else {
    return {};
  }
}
{% endhighlight %}

What has happened here is that the InteractiveQuoteComponent has called `updateState:mode:` in reaction to an action. Here we can see that the state of the previous component is inspected to determine if a fade animation is warranted. Otherwise, no animation is provided.

### Bounds animations

As I mentioned, bounds animations have to be handled specially because they actually change how changes to the UICollectionView are processed. Here's how a component would animate a bounds change:

{% highlight objc %}
- (CKComponentBoundsAnimation)boundsAnimationFromPreviousComponent:(CKComponent *)previousComponent;
An astute observer would note that bounds animations are not `CKComponentAnimation`. They are instead `CKComponentBoundsAnimation`. This is a different struct that has the following members:
struct CKComponentBoundsAnimation {
  NSTimeInterval duration;
  NSTimeInterval delay;
  CKComponentBoundsAnimationMode mode;
  UIViewAnimationOptions options;

  /** Ignored unless mode is Spring, in which case it specifies the damping ratio passed to UIKit. */
  CGFloat springDampingRatio;
  /** Ignored unless mode is Spring, in which case it specifies the initial velocity passed to UIKit. */
  CGFloat springInitialVelocity;
};
{% endhighlight %}

These allow configuration of implicit UIView animations that wrap the mutations to the collection view. This means that if a component wants to do something like expand in height, and have the collection view animate as it conducts its animation, it can return a bounds animation in addition to its normal component animation to trigger the overall change intended.

You may note that you can only return one bounds animation. This is intentional, since the bounds animation will apply to the application of the changeset in which the new component is mounted, and apply not just to the component that specifies the bounds animation, but to the entire component hierarchy.

Since bounds animations have this global scope, it is impossible for the framework to satisfy multiple bounds animation requests simultaneously. Thus, if more than one bounds animation is specified by different components in the same tree, the behavior is undefined. One of the animations will be selected, and you can't tell which one.

Returning to the example above:

{% highlight objc %}
- (CKComponentBoundsAnimation)boundsAnimationFromPreviousComponent:(ArticleComponent *)previousComponent
{
  if (previousComponent->_state == ArticleComponentStateCollapsed && _state == ArticleComponentStateExpanded) {
    return {
      .mode = CKComponentBoundsAnimationModeSpring,
      .duration = 0.5,
      .springDampingRatio = 0.7,
      .springInitialVelocity = 1.0,
    };
  } else {
    return {};
  }
}
{% endhighlight %}

This code animates a change in the size of a component within a larger component tree, and properly animates both the cells within the collection view, and also the size and positioning of elements within the component hierarchy that change.
