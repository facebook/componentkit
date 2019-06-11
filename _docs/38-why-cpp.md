---
title: Why C++
layout: docs
permalink: /docs/why-cpp.html
---
Using Objective-C++ in ComponentKit offers some serious wins in syntax. However this does mean you need to touch a limited subset of C++ to work with ComponentKit.  Don't worry, it's not too bad!

Here again is a generic article component:

{% highlight objc %}
[CKFlexboxComponent
 newWithView:{}
 size:{}
 style:{
  .direction = CKFlexboxDirectionColumn,
 } 
 children:{
   {[HeaderComponent newWithArticle:article]},
   {[MessageComponent newWithArticle:article]},
   {[FooterComponent newWithArticle:article]},
 }];
{% endhighlight %}

Here's what it might look like in pure Objective-C:

{: .redhighlight }
{% highlight objc %}
[CKFlexboxComponent newWithView:[[UIView alloc] init]
                           size:CGSizeZero
                          style:[[CKFlexboxComponentStyle alloc] initWithDirection:CKFlexboxDirectionColumn
                                                                    justifyContent:CKFlexboxJustifyContentStart
                                                                        alignItems:CKFlexboxAlignItemsStart
                                                                           spacing:0.0]
                       children:@[
  [CKFlexboxComponentChild childWithComponent:[HeaderComponent newWithArticle:article]
                                   topPadding:0
                                  leftPadding:0
                                bottomPadding:0],
  [CKFlexboxComponentChild childWithComponent:[MessageComponent newWithArticle:article]
                                   topPadding:0
                                  leftPadding:0
                                bottomPadding:0],
  [CKFlexboxComponentChild childWithComponent:[FooterComponent newWithArticle:article]
                                   topPadding:0
                                  leftPadding:0
                                bottomPadding:0]
]];
{% endhighlight %}

## Aggregate Initialization

C and C++ have [aggregate initialization](http://en.cppreference.com/w/cpp/language/aggregate_initialization), which allows initializing a struct with very terse syntax. We need Objective-C++ to take advantage of this syntax because, unlike Objective-C, Objective-C++ allows putting Objective-C objects in structs when ARC is enabled.

You can be as expressive as you like; you can use `{ .name = value, ... }` or just `{ value1, value2, ... }`. (The latter form is shorter, but fragile to argument reordering and sometimes harder to read.) Note that you can easily omit fields; in the C++ example above, the padding-related values are omitted and default to 0.

## Type Safety

In the previous example the C++ would fail to compile if we inserted a child of the wrong type, while the Objective-C example compiles with any type in the array—even an `NSString *`.

## Efficiency

Being fully declarative and immutable means you use a *lot* of objects. C++ objects are far more efficient to create because they can be stack-allocated, [emplaced](http://stackoverflow.com/questions/4303513/push-back-vs-emplace-back), [moved](http://www.cprogramming.com/c++11/rvalue-references-and-move-semantics-in-c++11.html), etc.

## Nil Safety

Objective-C containers throw if you insert `nil` elements in them but C++ containers do not. Relaxing this constraint makes it convenient to write hierarchies where any individual child may be nil:

{% highlight objc %}
  children:{
    headerComponent,
    messageComponent,
    attachmentComponent,
    footerComponent
  }
{% endhighlight %}

The alternative would be a bunch of conditionals in Objective-C:

{: .redhighlight }
{% highlight objc %}
NSMutableArray *children = [NSMutableArray array];
if (headerComponent) {
  [children addObject:headerComponent];
}
if (messageComponent) {
  [children addObject:messageComponent];
}
if (attachmentComponent) {
  [children addObject:attachmentComponent];
}
if (footerComponent) {
  [children addObject:footerComponent];
}
{% endhighlight %}
