---
title: Never Subclass Components
layout: docs
permalink: /docs/never-subclass-components.html
---

You should always subclass `CKCompositeComponent` when creating a component. (If you need to perform advanced layout by overriding `computeLayoutThatFits:`, you may subclass `CKComponent` directly, but this is rare.) Don't subclass other component classes.

- **Subclassing is difficult to reason about.** There is no `final` keyword in Objective-C, so *any* method can be overridden in a subclass. It's impossible to read a superclass and know what is and isn't overridden somewhere.
- **Subclassing makes refactoring the superclass difficult.** If the superclass is refactored to rename or remove a method, every subclass must be inspected to see if they were overriding the method. This is often skipped or forgotten, leading to silent bugs.

For example, imagine that we're adding a new "highlighted" card component. It should look just like a regular card component, but have a yellow background color. Don't do this:

{% highlight objc++ cssclass=redhighlight %}  
@implementation HighlightedCardComponent : CardComponent
- (UIColor *)backgroundColor
{
  // This breaks silently if the superclass method is renamed.
  return [UIColor yellowColor];
}
@end
{% endhighlight %}

Instead, make `CardComponent` take the color as a parameter and then subclass `CKCompositeComponent` to create your highlighted component:

```objc++
@implementation HighlightedCardComponent : CKCompositeComponent
+ (instancetype)newWithArticle:(CKArticle *)article
{
  return [super newWithComponent:
          [CardComponent
           newWithArticle:article
           backgroundColor:[UIColor yellowColor]]];
}
@end
```
