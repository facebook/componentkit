---
title: Lifecycle Manager
layout: docs
permalink: /docs/lifecycle-manager.html
---

There is a divide between most of the application (traditional imperative code) and each top-level component (below which everything is functional and immutable).

This divide is managed by the `CKComponentLifecycleManager`. This class is internal infrastructure; you shouldn't have to worry about it. Instead, use `CKComponentDataSource` or `CKComponentHostingView`. If you're curious about its inner workings, though, here's a little about how it works.

Create a lifecycle manager using its designated initializer. This takes a "component provider" (basically, a function mapping models into components) and a context object (which may hold common utilities):

```objc++
- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider
                                  context:(id)context;
```

The lifecycle manager's job is to hold the state associated with each component. It exposes a method to generate a new state object from a new model, and another method to make the generated state object its current state. (Why separate methods? The separation allows the data source to asynchronously compute new states for multiple lifecycle managers on different threads, then apply all the changes together at a single time.)

```objc++
- (CKComponentLifecycleManagerState)prepareForUpdateWithModel:(id)model constrainedSize:(CKSizeRange)constrainedSize;
- (void)updateWithState:(const CKComponentLifecycleManagerState &)state;
```

The lifecycle manager exposes methods to attach or detach to views. Attaching performs the actual operations to turn components into views. Only one lifecycle manager can be mounted on any given view.

```objc++
- (void)attachToView:(UIView *)view;
- (void)detachFromView;
```

Remember that because the lifecycle manager is internal infrastructure, its API is subject to change. Don't use it directly.
