---
title: Animation 
layout: docs
permalink: /docs/animation.html
---

ComponentKit exposes two ways to perform animations.

## animationsFromPreviousComponent:

Override this method to specify how to animate between two versions of a component. Here's an example from the example app:

```objc++
- (std::vector<CKComponentAnimation>)animationsFromPreviousComponent:(InteractiveQuoteComponent *)previousComponent
{
  if (previousComponent->_overlay == nil && _overlay != nil) {
    return { {_overlay, scaleToAppear()} }; // Scale the overlay in when it appears.
  } else {
    return {};
  }
}

static CAAnimation *scaleToAppear()
{
  CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform"];
  scale.fromValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.0, 0.0, 0.0)];
  scale.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
  scale.duration = 0.2;
  return scale;
}
```

## boundsAnimationFromPreviousComponent:

Override this method to specify how the top-level bounds of a component should animate inside a `UICollectionView`. For example, if you were implementing an expandable article component that changes its height, you could specify a spring animation for changing the cell bounds:

```objc++
- (CKComponentBoundsAnimation)boundsAnimationFromPreviousComponent:(ArticleComponent *)previousComponent
{
  if (previousComponent->_state == ArticleComponentStateCollapsed && _state == ArticleComponentStateExpanded) {
    return {
      .mode = CKComponentBoundsAnimationModeSpring,
      .duration = 0.5,
      .springDampingRatio = 0.7,
      .springInitialVelocity = 1.0,
    };
  } else {
    return {};
  }
}
```

## Notes

If you implement either method, your component must have a [scope](scopes.html).
