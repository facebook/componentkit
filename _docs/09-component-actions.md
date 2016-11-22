---
title: Component Actions
layout: docs
permalink: /docs/component-actions.html
---

Often child components must communicate back to their parents. For example, a button component may need to signal that it has been tapped. Component actions provide a way to do this.

### What are Component Actions? 

`CKTypedComponentAction<T...>` is an Objective-C++ class that wraps a `SEL` (basically a method name in Objective-C), and a target. `CKTypedComponentAction<T...>` allows you to specify the types of the arguments that are provided to the receiving method.

Where possible, you should explicitly define the target of your action using either a component scope, or a target for non-Component targets. 

`CKComponentAction` is just an alias for `CKTypedComponentAction<>` — basically, a component action that provides no arguments. In general, prefer to use `CKTypedComponentAction<T>` to give your callers greater type-safety.

An action may be sent through the `send` function on `CKTypedComponentAction`, which takes the sender component, and the parameters to be passed to the receiver.

For legacy reasons, we also support using `CKComponentActionSend`. The `CKComponentActionSend` function takes an action, a sender, and an optional opaque context object. It follows the [component responder chain](responder-chain.html) until it finds a component (or component controller) that responds to the given selector, then sends a message with the sender and context as parameters.

<div class="note-important">
  <p>
    <code>CKComponentActionSend</code> must be called on the main thread.
  </p>
</div>

### Using Component Actions 

Here's an example of how to handle a component action. (The API for `CKButtonComponent` has been simplified for this example.)

{% highlight objc %}
@interface CKButtonComponent : CKCompositeComponent
+ (instancetype)newWithAction:(CKTypedComponentAction<UIEvent *>)action;
@end

@implementation SampleComponent
+ (instancetype)new
{
  CKComponentScope scope(self);
  return [super newWithComponent:
          [CKButtonComponent
           newWithAction:{@selector(someAction:event:), scope}]];
}

- (void)someAction:(CKButtonComponent *)sender event:(UIEvent *)event
{
  // Do something
}
@end

@implementation SampleOtherComponentThatDoesntCareAboutEvents
+ (instancetype)new
{
  CKComponentScope scope(self);
  return [super newWithComponent:
          [CKButtonComponent
           newWithAction:{@selector(someAction:), scope}]];
}

- (void)someAction:(CKButtonComponent *)sender
{
  // Do something
}
@end

@implementation SampleOtherComponentThatDoesntCareAboutAnyParameters
+ (instancetype)new
{
  CKComponentScope scope(self);
  return [super newWithComponent:
          [CKButtonComponent
           newWithAction:{@selector(someAction), scope}]];
}

- (void)someAction
{
  // We don't take any arguments in this example.
}
@end

@interface SampleControllerDelegatingComponentController : CKComponentController
/** Component actions may be implemented either on the component, or the controller for that component. */
- (void)someAction;
@end

@implementation SampleControllerDelegatingComponent
+ (instancetype)new
{
  CKComponentScope scope(self);
  return [super newWithComponent:
          [CKButtonComponent
           newWithAction:{@selector(someAction), scope}]];
}
@end

@implementation SampleControllerDelegatingComponentController
- (void)someAction
{
  // Do something
}
@end

{% endhighlight %}

<div class="note-important">
  <p>
    Component actions will only be sent up the component responder chain in a mounted component hierarchy. Trying to call <code>CKComponentActionSend</code> from an unmounted component will raise an assertion.
  </p>
</div>

### Why not blocks? 

Blocks might seem like a more natural way to specify callbacks. Unfortunately it's far too easy to introduce retain cycles when using blocks: components hold strong references to their child components, and the child might hold a block with a strong reference back to the parent.

### Hybrid Responder Chain

Component actions begin traversal of the [component responder chain](responder-chain.html) from the target or scoped component, or if neither are defined, at the sender of the action. They traverse upwards from there.

In general, you should avoid using the [component responder chain](responder-chain.html), but for legacy reasons it still exists. Instead, you should use target- or scope-based actions, which will verify that the action is handled directly. If you use the scope-based component action, the type-checking machinery will verify that your component or controller responds to the selector with the expected param types (to the extent that Obj-C allows) at runtime.

### Automatic Promotion

In order to support a progressive adoption of typed actions, we allow automatic "promotion" of component actions. By promotion, we mean you can provide a component action that takes less arguments to a component that expects more arguments. So, for instance, you can provide a `CKTypedComponentAction<id>(@selector(actionWithSender:firstParam:), scope)` to a component that expects a `CKTypedComponentAction<id, id>`. At runtime, your method will simply not receive the additional parameters that it does not expect.

### Explicit Demotion

Legacy callsites also may use "demotion", but it is disabled by default. By demotion, we mean providing a component action that expects *more* parameters than handled. So for instance, this would be like passing `CKTypedComponentAction<id, id, id>` to a component which expects an action of type `CKTypedComponentAction<id>`. In this case, at action-call time we would be getting less parameters than we expected. For this reason, we have forced these conversions to be explicit. You must explicitly convert your action to demote it by calling the demoted copy constructor: `CKTypedComponentAction<id>(CKTypedComponentAction<id, id, id>(@selector(someMethodWithSender:param1:param2:param3:), scope))`. At runtime the parameters that aren't provided by the action will be filled with zeros (so nil for object types, zerod structs or primitives).
