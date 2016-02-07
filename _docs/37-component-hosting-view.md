---
title: Component Hosting View
layout: docs
permalink: /docs/component-hosting-view.html
---

So you've created a component and now need some way to render it on screen. If your use case involves using components inside a `UICollectionView`, you should be using `CKCollectionViewDataSource`. However, there are some cases where you want to render a component standalone. `CKComponentHostingView` was built for this purpose.

## Setting the model 

`CKComponentHostingView` has a readwrite `model` property that can be used to set the model passed to the root component.

## Size Range Provider 

`CKComponentHostingView` requires a size range provider to be passed into the initializer. The size range provider is an object that responds to a single method (`-sizeRangeForBoundingSize:`) that calculates a constraining size for a given view bounding size. 

Typically you'll want to use `CKComponentFlexibleSizeRangeProvider`, a class that conforms to `CKComponentSizeRangeProviding` and implements a set of common sizing behaviors where none, either, or both dimensions (width and height) can be constrained to the view's bounding dimensions.

## Layout  

To determine an appropriate size for a component hosting view, call `-sizeThatFits:` with the constraining size.

If an internal state change in the component causes its size to be invalidated, `CKComponentHostingView` calls its delegate method `-componentHostingViewDidInvalidateSize:` in order to notify the owner of the view that it should resize the view (the view will **not** resize itself).
