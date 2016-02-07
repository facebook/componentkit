---
title: Lifecycle Methods
layout: docs
permalink: /docs/lifecycle-methods.html
---

[Component controllers](component-controllers.html) expose lifecycle methods that allow you to perform custom operations as components mount, unmount, update, and acquire views.

<div class="note">
  <p>
     Whenever possible, avoid using lifecycle methods. Think of them as an emergency escape hatch for integrating with stateful code.
  </p>
</div>

## Ordering

Lifecycle methods have the following defined ordering.

### Mounting

1. `willMount`
2. `componentDidAcquireView` *if* the controller's component has a view
3. `didMount` after the component *and* all of its children are mounted

### Remounting 

Remounting occurs when the controller's component is already mounted and either the component is being updated or the root component is being attached to a different view.

1. `willRemount`
2. If the controller's component creates a view and its previous view cannot be recycled:
    1. `componentWillRelinquishView`
    2. `componentDidAcquireView`
3. `didRemount`

### Unmounting 

1. `willUnmount`
2. `componentWillRelinquishView` *if* the controller's component has a view
3. `didUnmount`

<div class="note-important">
  <p>
     There are no guarantees that the component's children or parents are mounted in <code>willUnmount</code> or <code>componentWillRelinquishView</code>. You <b>must not</b> use <code>CKComponentActionSend</code> or any other method that assumes the component's parents are mounted.
  </p>
</div>

### Updating 

The controller's component can be updated to a new version of the component as part of the mounting or remounting process. In this case, you'll receive the following callbacks:

1. `willUpdateComponent` before `willMount` or `willRemount`
2. `didUpdateComponent` after `didMount` or `didRemount`

## Uses 

### Mutating the View 

Generally views are a hidden implementation detail of ComponentKit, but you may need to break that abstraction:

- Animations that cannot be implemented using `animationsFromPreviousComponent:`. Be sure you remove all animations in `componentWillRelinquishView`.
- Interfacing with views that only expose event callbacks via a delegate API. Make the component controller the view's delegate in `componentDidAcquireView` and nil out the view's delegate in `componentWillRelinquishView`.

