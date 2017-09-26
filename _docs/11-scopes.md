---
title: Scopes
layout: docs
permalink: /docs/scopes.html
---

In the following component hierarchy ComponentKit has no way to distinguish the three `ListItem` components:

<img src="/static/images/tree.png" width="367" height="124" alt="Component Tree">

ComponentKit needs a way to uniquely identify each `ListItem`. Particularly as the component hierarchy is rebuilt over time:

<img src="/static/images/tree-ids.png" width="367" height="124" alt="Component Tree with IDs">

Scopes give ComponentKit the ability to assign any component with a persistent identity: _regardless of how many times a component is created in a component hierarchy it will always acquire the same component scope_. This behavior is required in the following three situations:

1. If a component has [state](state.html) it must also define a scope
2. If a component has a [component controller](component-controllers.html) it must also define a scope
3. If a component has children that themselves have state or component controllers it must also define a scope when encountering a scope collision

## Defining a Scope

Use `CKComponentScope` to define a component scope at the top of a component's `+new` method.

{% highlight objc %}
@implementation ListItemComponent

+ (instancetype)newWithListItem:(ListItem *)listItem
{
  // Defines a scope that is uniquely identified by the component's class (i.e. ListItemComponent) and the provided identifier.
  CKComponentScope scope(self, listItem.uniqueID);
  const auto c = /* ... */;
  return [super newWithComponent:c];
}

@end
{% endhighlight %}

If a component does not have a model object with a unique identifier a scope can be defined without one:

{% highlight objc %}
@implementation ListComponent

+ (instancetype)newWithList:(List *)list
{
  // Defines a scope that is uniquely identified by the component's class (i.e. ListComponent).
  CKComponentScope scope(self);
  const auto c = /* ... */;
  return [super newWithComponent:c];
}

@end
{% endhighlight %}

Omitting the scope's identifier is safe as long as there will not be more than one sibling component of the same type. The example above assumes `ListComponent`'s parent will only ever render one `ListComponent`. If that assumption no longer holds then the parent component must specify a unique identifier for scopes of its children. This is when `CKComponentKey` is helpful:

{% highlight objc %}
@implementation ListsComponent

+ (instancetype)newWithList:(NSArray<List *> *)lists
{
  // Defines a scope that is uniquely identified by the component's class (i.e. ListComponent).
  CKComponentScope scope(self);
  const auto c = /* ... */;
  return
  [super
   newWithListComponents:
   CK::map(lists, ^(List *list) {
     CKComponentKey key(@([lists indexOfObject:list]));
     return [ListComponent newWithList:list];
   })];
}

@end
{% endhighlight %}

ComponentKit's keys are an [analogous to the concept of the same name in React](https://facebook.github.io/react/docs/lists-and-keys.html#keys). They allow the parent component to implicitly provide child components with a unique identifiers _based on its knowledge of the component hierarchy_. In the `ListsComponent` example each `ListComponent` is rendered in the order provided. Since the `ListsComponent` knows how it will display each `ListComponent` it can provide a key based on each `list`'s order in the `lists` array.

## Scope collisions

Scopes must be uniquely identifiable otherwise ComponentKit will be unable to reliably associate a component with its scope. When ComponentKit cannot uniquely identify two or more scopes then it has encountered a __scope collision__ and an assertion is raised. To avoid a scope collision either:

1. Define the scope of a component encountering a scope collision with a unique identifier
2. Define a key in a parent component when creating children encountering a scope collision

The assertion raised by ComponentKit highlights where in the component hierarchy a scope collision is detected. Information provided by the framework includes the name of the component encountering the scope collision and where the component lives in the component hierarchy.
