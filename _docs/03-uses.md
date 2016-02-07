---
title: Uses
layout: docs
permalink: /docs/uses.html
---

ComponentKit excels at powering list views with complex content. It was built to power Facebook's News Feed on iOS.

### Strengths

- Simple and Declarative: Just like React itself. [Why React?](http://facebook.github.io/react/docs/why-react.html) sums up these benefits.
- Scroll Performance: All layout is performed on a background thread, ensuring the main thread isn't tied up measuring text. 60FPS is a breeze even for deep, complex layouts like Facebook's News Feed.
- View Recycling: By requiring all view configurations to be expressed declaratively, ComponentKit makes error-free view recycling automatic.
- Composability: By encouraging heavy use of composition, it's possible to build UIs as complex as News Feed without any single component exceeding [300 lines of code](under-300-lines.html).

### Considerations

- Interfaces that aren't lists or tables aren't ideally suited to ComponentKit since it is optimized to work well with a  `UICollectionView`.
- ComponentKit is fully native and compiled. [React Native](https://code.facebook.com/videos/786462671439502/react-js-conf-2015-keynote-introducing-react-native-/) offers an alternative based on JavaScriptCore and React, including features like instant reload with no recompilation.
- Dynamic gesture-driven UIs are currently  hard to implement in ComponentKit; consider&nbsp;using&nbsp;[AsyncDisplayKit](http://asyncdisplaykit.org).
- ComponentKit is built on Objective-C++. There is no easy way to interoperate with [Swift](https://developer.apple.com/swift/) since Swift cannot bridge to C++. Experimental projects like [Few.swift](https://github.com/joshaber/Few.swift) are exploring how React's concepts could be applied in Swift.
