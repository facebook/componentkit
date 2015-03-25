---
title: Component Actions
layout: docs
permalink: /docs/component-actions.html
---

Often child components must communicate back to their parents. For example, a button component may need to signal that it has been tapped. Component actions provide a way to do this.

### What are Component Actions? 

`CKComponentAction` is just an alias for `SEL` — basically, a method name.

The `CKComponentActionSend` function takes an action, a sender, and an optional opaque context object. It follows the [component responder chain](controls-and-the-responder-chain.html) until it finds a component (or component controller) that responds to the given selector, then sends a message with the sender and context as parameters.

(The only reason for the alias is to document that you expect the `SEL` to be called via `CKComponentActionSend`.)

### Using Component Actions 

Here's an example of how to handle a component action. (The API for `CKButtonComponent` has been simplified for this example.)

```objc++
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
```

### Why not blocks? 

Blocks might seem like a more natural way to specify callbacks. Unfortunately it's far too easy to introduce retain cycles when using blocks: components hold strong references to their child components, and the child might hold a block with a strong reference back to the parent.
