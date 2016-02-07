---
title: Layout
layout: docs
permalink: /docs/layout.html
---

`UIView` instances store position and size in their `center` and `bounds` properties. As constraints change, Core Animation performs a layout pass to call `layoutSubviews`, asking views to update these properties on their subviews.

`CKComponent` instances do not have any size or position information. Instead, ComponentKit calls the `layoutThatFits:` method with a given size constraint and the component must *return* a structure describing both its size, and the position and sizes of its children.

```objc++
struct CKComponentLayout {
  CKComponent *component;
  CGSize size;
  std::vector<CKComponentLayoutChild> children;
};

struct CKComponentLayoutChild {
  CGPoint position;
  CKComponentLayout layout;
};
```

## Layout Components

ComponentKit includes a library of components that can be composed to declaratively specify a layout.

- `CKStackLayoutComponent` is based on a simplified version of [CSS flexbox](http://www.w3.org/TR/css3-flexbox/). It allows you to stack components vertically or horizontally and specify how they should be flexed and aligned to fit in the available space.
- `CKInsetComponent` applies an inset margin around a component.
- `CKBackgroundLayoutComponent` lays out a component, stretching another component behind it as a backdrop.
- `CKOverlayLayoutComponent` lays out a component, stretching another component on top of it as an overlay.
- `CKCenterLayoutComponent` centers a component in the available space.
- `CKRatioLayoutComponent` lays out a component at a fixed aspect ratio.
- `CKStaticLayoutComponent` allows positioning children at fixed offsets.

## Implementing computeLayoutThatFits:

If the components above aren't powerful enough, you can implement `computeLayoutThatFits:` manually. This method passes you a `CKSizeRange` that specifies a min size and a max size. Choose any size in the given range, then return a `CKComponentLayout` structure with the layout of child components.

For sample implementations of `computeLayoutThatFits:`, check out the layout components in ComponentKit itself!
