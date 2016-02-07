---
title: Scopes
layout: docs
permalink: /docs/scopes.html
---

In the following tree, ComponentKit has no way to distinguish the three ListItems:

<img src="/static/images/tree.png" width="367" height="124" alt="Component Tree">

We want a way to give each child a unique identifier:

<img src="/static/images/tree-ids.png" width="367" height="124" alt="Component Tree with IDs">

Scopes give components a persistent, unique identity. They're needed in three cases:

1. Components that have [state](state.html) must have a scope.
2. Components that have a [controller](component-controllers.html) must have a scope.
3. Components that have child components with state or controllers may need a scope, even if they don't have state or controllers.

## Defining a Scope

Use the `CKComponentScope` type to define a component scope at the top of a component's `+new` method.

```objc++
+ (instancetype)newWithModel:(Model *)model
{
  CKComponentScope scope(self, model.uniqueID);
  ...
  return [super newWithComponent:...];
}
```

If your component doesn't have a model object with a unique identifier, you can omit that parameter as long as there won't be multiple siblings of the same type.

```objc++
CKComponentScope scope(self);
```
