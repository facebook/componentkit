---
title: Component Actions
layout: docs
permalink: /docs/component-actions.html
---

Often child components must communicate back to their parents. For example, a button component may need to signal that it has been tapped. Component actions provide a way to do this.

### What are Component Actions? 

`CKComponentAction` is just an alias for `SEL` — basically, a method name. This alias is used as a way to document the purpose of the selector, which is to send a component action.

The `CKComponentActionSend` function takes an action, a sender, and an optional opaque context object. It follows the [component responder chain](responder-chain.html) until it finds a component (or component controller) that responds to the given selector, then sends a message with the sender and context as parameters.

<div class="note-important">
  <p>
    <code>CKComponentActionSend</code> must be called on the main thread.
  </p>
</div>

### Using Component Actions 

Here's an example of how to handle a component action. (The API for `CKButtonComponent` has been simplified for this example.)

{% highlight objc %}
@implementation SampleComponent
+ (instancetype)new
{
  return [super newWithComponent:
          [CKButtonComponent
           newWithAction:@selector(someAction:)]];
}

- (void)someAction:(CKButtonComponent *)sender
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
