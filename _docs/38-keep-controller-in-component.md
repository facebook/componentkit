---
title: Keep Controller in Component
layout: docs
permalink: /docs/keep-controller-in-component.html
---
Avoid creating a separate file for component controllers.

{% highlight objc %}
@implementation BoldToggleComponent

+ (instancetype)newWithString:(NSString *)string
{
  CKComponentScope scope(self);
  UIFont *const font = ([scope.state() boolValue] ?
                        [UIFont boldSystemFontOfSize:12.0] :
                        [UIFont systemFontOfSize:12.0]);
  return [super newWithComponent:
          [CKLabelComponent
           newWithLabelAttributes:{
             .string = string,
             .font = font,
           }
           viewAttributes:{}
           size:{}]];
}

+ (id)initialState
{
  return @NO;
}

@end

@implementation BoldToggleComponentController

- (void)didMount
{
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(updateState:)
                                               name:@"toggleBold"
                                             object:nil];
}

- (void)willUnmount
{
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:@"toggleBold"
                                                object:nil];
}

- (void)updateState:(NSNotification *)notification
{
  [self.component updateState:^(id oldState){
    return @(![oldState boolValue]);
  } mode:CKUpdateModeAsynchronous];
}

@end
{% endhighlight %}

Imagine that the component and controller were in separate in the above
example.  Then, it wouldn't be obvious why the state is necessary just by
looking at the component file, since there are no calls to `updateState` in the
component file.

It may be tempting to split the component controller into its own file in order
to make the file less than 300 lines, but we think it's worse to have the
component controller in its own file.
