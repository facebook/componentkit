---
title: No Underscores
layout: docs
permalink: /docs/no-underscores.html
---
Don't underscore-prefix private helper methods or `static` C functions.

{% highlight objc++ cssclass=redhighlight %}
- (void)_buttonAction:(CKComponent *)sender
{
  _logEvent(@"button tapped");
}
{% endhighlight %}

[Subclassing components is discouraged](never-subclass-components.html), so there's no need to worry about distinguishing public and private methods or colliding with methods in the superclass.

```objc++
- (void)buttonAction:(CKComponent *)sender
{
  logEvent(@"button tapped");
}
```
