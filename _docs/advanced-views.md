---
title: Advanced Views
layout: docs
permalink: /docs/advanced-views.html
---
Back in [Views](views.html) we glossed over `CKComponentViewClass` and `CKComponentViewAttribute`. But there's a surprising amount of power hiding here!

`CKComponentViewClass` describes how to create a `UIView`. Usually you pass an Objective-C class like `[UIImageView class]`, and ComponentKit will automatically create a view by invoking the designated initializer `-initWithFrame:`.

But of course, not all views can be created with `-initWithFrame:`. For these cases, there's an advanced constructor that takes a function pointer:

```objc++
CKComponentViewClass(UIView *(*factory)(void));
```

This allows you to use almost any view with ComponentKit. Here's one example:

```objc++
static AuthorView *authorViewForOscarWilde(void) {
  return [[AuthorView alloc] initWithName:@"Oscar Fingal O'Flahertie Wills Wilde"];
}
// ...
[CKComponent newWithView:{&authorViewForOscarWilde} size:{50, 50}]
```

<div class="note-important">
  <p> 
    However, the factory takes no arguments; you can't pass any properties from a particular component to a view's <code>-init</code>, since views must be arbitrarily recycled between components. If your view takes properties in <code>-init</code>, one possible pattern is to create a wrapping view with setter methods that tear down and re-create the problematic view as a subview.
  </p>
</div>

`CKComponentViewAttribute` has similar underpinnings. Usually you pass a `SEL`, but under the hood they're basically just arbitrary blocks paired with a unique identifier:

```objc++
struct CKComponentViewAttribute {
  std::string identifier;
  void (^applicator)(id view, id value);
  void (^unapplicator)(id view, id value);
  void (^updater)(id view, id oldValue, id newValue);
};
```

This allows you to express arbitrarily complex operations on the view, like "call this method with these N arguments". The only restriction is that you must box up the inputs to the block in a single `id` so ComponentKit can determine if it has changed across recyclings.

<div class="note">
  <p> 
    How does passing a <code>Class</code> or <code>SEL</code> work for these classes? They each have a single-argument constructor that takes a <code>Class</code>/<code>SEL</code> and creates an object that creates the right thing. C++ implicitly calls this constructor when you pass a <code>Class</code>/<code>SEL</code>.
  </p>
</div>
