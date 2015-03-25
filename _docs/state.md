---
title: State
layout: docs
permalink: /docs/state.html
---

So far we've been loosely inspired by [React](http://facebook.github.io/react/). If you're familiar with React, you'll know that React components have two elements:

- **props**: passed from the parent. These roughly correspond to our parameters passed to the `+new` method.
- **state**: internal to the component, this holds implementation details that the parent should not have to know about. The canonical example is whether some text should be rendered fully, or truncated with a "Continue Reading…" link. This is a detail the parent component should not have to manually manage.

Figuring out the difference between these two can be tricky at first. [Thinking in React](http://facebook.github.io/react/blog/2013/11/05/thinking-in-react.html) is a really helpful blog post on this topic.

Just like React, `CKComponent` has state.

```objc++
@interface CKComponent
- (void)updateState:(id (^)(id))updateBlock;
@end
```

Let's make a simple example of using state for the "Continue Reading…" link.

```objc++
@implementation MessageComponent

+ (id)initialState
{
  return @NO;
}

+ (instancetype)newWithMessage:(NSAttributedString *)message
{
  CKComponentScope scope(self);
  NSNumber *state = scope.state();
  return [super newWithComponent:
          [CKTextComponent
           newWithAttributes:{
             .attributedString = message,
             .maximumNumberOfLines = [state boolValue] ? 0 : 5,
           }
           viewAttributes:{}
           accessibilityContext:{}]];
}

- (void)didTapContinueReading
{
  [self updateState:^(id oldState){ return @YES; }];
}

@end
```
That's all there is to it. Some nice attributes:

- Continue Reading state is completely hidden from parent components and controllers. They don't need to know about it or manage it.
- State changes can be coalesced or arbitrarily delayed for performance reasons. We can easily compute the updated component off the main thread when possible/desired.
