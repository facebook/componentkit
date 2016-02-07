---
title: Components Can't Be Delegates
layout: docs
permalink: /docs/components-cant-be-delegates.html
---

Components are **short-lived**, and their lifecycle is not under your control. Thus they should not be delegates or `NSNotification` observers.

An example: imagine you're showing a `UIAlertView`. You might be tempted to make the component the delegate:

{% highlight objc++ cssclass=redhighlight %}
@implementation AlertDisplayComponent <UIAlertViewDelegate>
{
  UIAlertView *_alertView;
}

- (void)didTapDisplayAlert
{
  _alertView = [[UIAlertView alloc] initWithTitle:@"Are you sure?"
                                          message:nil
                                         delegate:self ...];
  [_alertView show];
}

- (void)alertView:(UIAlertView *)alert didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  [self updateState:...];
}
@end
{% endhighlight %}

But if the component hierarchy is regenerated for any reason, the original component will deallocate and the alert view will be left with no delegate.

Instead, use `CKComponentController`. Component controllers are long-lived; they persist and keep track of each updated version of your component. You can [learn more about component controllers](component-controllers.html); here's an example of their use:

```objc++

@interface AlertDisplayComponentController : CKComponentController <UIAlertViewDelegate>
@end

@implementation AlertDisplayComponentController
{
  UIAlertView *_alertView;
}

- (void)didTapDisplayAlert
{
  _alertView = [[UIAlertView alloc] initWithTitle:@"Are you sure?"
                                          message:nil
                                         delegate:self ...];
  [_alertView show];
}

- (void)alertView:(UIAlertView *)alert didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  [self.component updateState:...];
}
@end
```

