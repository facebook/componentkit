---
title: No Side Effects
layout: docs
permalink: /docs/no-side-effects.html
---

Your `+new` method should not modify any global variables or global state. This could result in a component returning different results for the same parameters, which would be strange.

If you're a functional programming nerd, you can think of `+new` as a [pure function](http://en.wikipedia.org/wiki/Pure_function) mapping from a set of input parameters to a component. (Pure functions have many benefits, which I won't attempt to outline here.)
