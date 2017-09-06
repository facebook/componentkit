---
title: Pass in Actions
layout: docs
permalink: /docs/pass-in-actions.html
---
Follow this simple rule: Selectors should be implemented in the same file they are referenced.

The following counterexample establishes a hidden coupling between the parent and child component. If another component tries to use `ChildComponent` or if the method is renamed in `ParentComponent`, it will crash at runtime.

{: .redhighlight }
{% highlight objc %}
@implementation ParentComponent
+ (instancetype)new
{
  return [super newWithComponent:[ChildComponent new]];
}

- (void)someAction:(CKComponent *)sender
{
  // Do something
}
@end

@implementation ChildComponent
+ (instancetype)new
{
  return [super newWithComponent:
          [CKButtonComponent
           newWithAction:@selector(someAction:)]];
}
@end
{% endhighlight %}

Instead, always pass selectors from parents to children. In the following example, it is explicit that the child component needs a `CKTypedComponentAction<>` selector. If the parent component renames the `someAction:` method, it's far easier to catch renaming the parameter.

{% highlight objc %}

@implementation ParentComponent
+ (instancetype)new
{
  CKComponentScope scope(self);

  return [super newWithComponent:
          [ChildComponent
           newWithAction:{scope, @selector(someAction:)}]];
}

- (void)someAction:(CKComponent *)sender
{
  // Do something
}
@end

@implementation ChildComponent
+ (instancetype)newWithAction:(CKTypedComponentAction<>)action
{
  return [super newWithComponent:
          [CKButtonComponent
           newWithAction:action]];
}
@end
{% endhighlight %}
