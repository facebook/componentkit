---
title: Components Can't Be Delegates Directly
layout: docs
permalink: /docs/components-cant-be-delegates.html
---

TL;DR: You can use `CKComponentDelegateAttribute` to configure a delegate for a view to proxy delegate methods back to your component.

Components are **short-lived**, and their lifecycle is not under your control. Thus they should not be delegates or `NSNotification` observers.

An example: imagine you're showing a `UIAlertView`. You might be tempted to make the component the delegate:

{: .redhighlight }
{% highlight objc %}
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

{% highlight objc %}

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
{% endhighlight %}

Your other option is to use `CKComponentDelegateAttribute`, which will proxy delegate callbacks into the component responder chain.

{% highlight objc %}
[CKComponent
 newWithView:{[UIScrollView class], {
   CKComponentDelegateAttribute(@selector(setDelegate:), {
   @selector(scrollViewDidScroll:),
   @selector(scrollViewDidZoom:),
   })
 }}
 size:{}] ...
 {% endhighlight %}
 
 Then in your component, you can implement the delegate methods `-scrollViewDidScroll:` and `-scrollViewDidZoom:`.
 
