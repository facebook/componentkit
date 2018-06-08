---
title: Component Controllers
layout: docs
permalink: /docs/component-controllers.html
---

Remember the analogy made in [Philosophy](philosophy.html): components are like a stencil. They are an immutable snapshot of how a view should be configured at a given moment in time.

Every time something changes, an entirely new component is created and the old one is thrown away. This means components are **short-lived**, and their lifecycle is not under your control.

But sometimes, you do need an object with a longer lifecycle. *Component controllers* fill that role:

- [Components can't be delegates](components-cant-be-delegates.html) because they are short-lived, but component controllers can be delegates.
- Network downloads take time to complete; the component may have been recreated by the time the download completes. The controller can handle the callback.
- You may need an object to own some other object that should have a long lifetime.

## Creating Controllers 

- Controllers are instantiated automatically by ComponentKit. Don't try to create them manually.
- Define a controller by simply creating a subclass of `CKComponentController`; the naming convention is your component name plus "Controller". However, you can choose a different name or reuse an existing controller.
- Your component must have a <a href="scopes.html">`CKComponentScope`</a> to have a controller. (If you forget, you will get an assertion failure.)
- Your component must override `+ (Class<CKComponentControllerProtocol>)controllerClass` to indicate which class is its controller.
- Any `CKComponentAction` methods handled by your component can also be handled by the controller.

## Controller Flow 

<img src="/static/images/component-controllers.png" alt="Component Controller Flow" width="338" height="242">

1. The component controller is **created** with the first component.
2. When the component is updated, a new instance is generated…
3. But the component controller stays the same.

## Communication between Component and Component Controller  

There is a only a one-way communication channel between the component and its component controller - you can only pass data off of a component to a component controller. A component has no reference its corresponding component controller. This is by design. 

To pass data from a component to its controller, expose a `@property` on the component in a class extension. The controller can initialize itself with the properties in `initWithComponent:`. If these properties will be changing in subsequent state changes (i.e. a new component is being created with different values for these properties), keep them up to date in `didUpdateComponent`.

{% highlight objc %}
@interface MySongComponent()
@property (nonatomic, strong, readonly) MySong *song;     // All components for a controller share the same value
@property (nonatomic, assign, readonly) BOOL isPlaying;   // Different components may have different values (part of component state)
@end

// In order to provide the component controller class in the `+ (Class<CKComponentControllerProtocol>)controllerClass` 
// method, we have to declare the controller before the component's implementation.
@interface MySongComponentController : CKComponentController
@end

@implementation MySongComponent : CKCompositeComponent
+ (instancetype)newWithSong:(MySong *)song
{
  CKComponentScope scope(self, song.unique_id);
  const BOOL isPlaying = [scope.state() boolValue];
  MySongComponent *const c =
  [MySongComponent
   newWithComponent:[SongUIComponent
                     newWithIsPlaying:isPlaying]];
  if (c) {
    c->_song = song;
    c->_isPlaying = isPlaying;
  }
  return c;
}

+ (Class<CKComponentControllerProtocol>)controllerClass
{
  return [MySongComponentController class];
} 
@end

@implementation MySongComponentController
{
  MySong *_song;
}

- (instancetype)initWithComponent:(MySongComponent *)component
{
  if (self = [super initWithComponent:component]) {
    _song = component.song;
    [_song.setDelegate:self];
  }
  return self;
}

- (void)songStateDidChange:(BOOL)isPlaying
{
  [self.component updateState:^{
    return @(isPlaying);
  } mode:CKUpdateModeAsynchronous];
}

- (void)didUpdateComponent
{
  // This only fires on a state *change* (i.e. not through the initializer path).
}
@end
{% endhighlight %}
