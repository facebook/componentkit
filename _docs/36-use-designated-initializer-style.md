---
title: Use Designated Initializer Style
layout: docs
permalink: /docs/use-designated-initializer-style.html
---
Use [designated initializer style][0] when initializing a structure.

For example, consider `CKStaticLayoutComponent` which accepts a collection of children. Each `CKStaticLayoutComponentChild` is a structure that consists of a `position`, a `component`, and a `size`. Instead of initializing contiguous members:

{: .redhighlight }
{% highlight objc %}
CKComponent *const component =
[CKStaticLayoutComponent
 newWithChildren:{
   {
     {0, 0},
     leftComponent,
     {50, 50},
   },
   {
     {50, 0},
     centerComponent,
     {50, 50},
   },
   {
     {100, 0},
     rightComponent,
     {50, 50},
   },
 }]
{% endhighlight %}

You should initialize each member by name:

{% highlight objc %}
CKComponent *const component =
[CKStaticLayoutComponent
 newWithChildren:{
   {
     .component = leftComponent,
     .size = {50, 50},
   },
   {
     .position = {50, 0},
     .component = centerComponent,
     .size = {50, 50},
   },
   {
     .position = {100, 0},
     .component = rightComponent,
     .size = {50, 50},
   },
 }]
{% endhighlight %}

Omitted members will be initialized to 0. In the example above the first child explicitly omits `position` since it will be initialized to `{0, 0}` by default.

[0]: https://en.wikipedia.org/wiki/Struct_(C_programming_language)#Struct_initialization
