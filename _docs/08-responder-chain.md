---
title: Responder Chain
layout: docs
permalink: /docs/responder-chain.html
---

ComponentKit has a responder chain that is similar to the [responder chain on iOS](https://developer.apple.com/library/ios/documentation/EventHandling/Conceptual/EventHandlingiPhoneOS/event_delivery_responder_chain/event_delivery_responder_chain.html). The ComponentKit responder chain is separate from `UIView`'s responder chain, so you must manually bridge over to the component responder chain if desired.

<img src="/static/images/responder-chain.png" alt="Responder Chain" width="618" height="443">

1. The next responder of a component is its [controller](component-controllers.html), if it has one.
2. The next responder of a component's controller is its component's parent component.
3. If a component doesn't have a controller, its next responder is its parent component.
4. The next responder of the root component is the view it is attached to.
5. As normal, a view's next responder is its superview.
6. Eventually, this will reach the same root view as the component hierarchy.
7. It's up to you to manually bridge from the view responder chain into the component responder chain if desired by using `CKComponentActionSend` or one of the helpers described below.

Note that a component is not a subclass of `UIResponder` and it cannot become the first responder. It does implement both `nextResponder` and `targetForAction:withSender:`, however.

# Tap Handling 

The easiest way to handle taps on `UIControl` views is to use `CKComponentActionAttribute`. It returns a component attribute that triggers a [component action](component-actions.html) when any given `UIControlEvent` occurs. For example:

```objc++
@implementation SomeComponent

+ (instancetype)new
{
  return [self newWithView:{
    [UIButton class],
    {CKComponentActionAttribute(@selector(didTapButton))}
  }];
}

- (void)didTapButton
{
  // Aha! The button has been tapped.
}

@end
```

# Gestures 

That works for `UIControls`, but what about other views? Fear not, you can use `CKComponentTapGestureAttribute`. This allows you to install a tap gesture recognizer on any `UIView` and be notified when the tap occurs.

```objc++
@implementation SomeComponent

+ (instancetype)new
{
  return [self newWithView:{
    [UIView class],
    {CKComponentTapGestureAttribute(@selector(didTapView))}
  }];
}

- (void)didTapView
{
  // The view has been tapped.
}

@end
```

# Advanced Gestures 

What about advanced gestures like panning, pinching, swiping, and so on?

These are more complicated. The way the reactive-update model is implemented in ComponentKit is fairly limited, so the best option is to build an "escape hatch" from the reactive data flow for these at present. Drop down and mutate the underlying views directly as the user performs a gesture.
