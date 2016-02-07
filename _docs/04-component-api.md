---
title: Component API
layout: docs
permalink: /docs/component-api.html
---
The base `CKComponent` class is quite simple. Leaving out a few methods, it looks like this:

```objc++
@interface CKComponent : NSObject

/** Returns a new component. */
+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view
                       size:(const CKComponentSize &)size;

/** Returns a layout for the component and its children. */
- (CKComponentLayout)layoutThatFits:(CKSizeRange)constrainedSize
                         parentSize:(CGSize)parentSize;

@end
```

We'll get to these two methods in a moment. For now, note:

- A component is totally immutable. For example, there is no `addSubcomponent:` method.
- A component can be created on any thread. This helps keep all sizing and construction operations off the main thread.
- The Objective-C idiom `+newWith...` is used for instantiation instead of the more typical `+alloc/-initWith..`. This is mainly for brevity. Getting rid of noise is important to keep components code readable.
