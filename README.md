# [![ComponentKit](http://componentkit.org/img/componentkit_hero_logo.png)](http://componentkit.org/)

[![Build Status](https://travis-ci.org/facebook/componentkit.svg)](https://travis-ci.org/facebook/componentkit)

ComponentKit is a view framework for iOS that is heavily inspired by React. It takes a functional, declarative approach to building UI. It was built to power Facebook's News Feed and is now used throughout the Facebook iOS app.

### Quick start

ComponentKit is available to install via [Carthage](https://github.com/Carthage/Carthage). To get started add the following to your [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile):

```
github "facebook/ComponentKit" ~> 0.31
```

### Opening the Xcode projects
ComponentKit has a few dependencies that need to be installed via [Carthage](https://github.com/Carthage/Carthage). **Before you open any of the Xcode projects in this repo, make sure you run**:

```
carthage checkout
```

If Carthage isn't installed, you easily install it via Homebrew:

```
brew install carthage
```
If you can't use Homebrew, Carthage provides other [installation methods](https://github.com/Carthage/Carthage#installing-carthage).


To get started with the example app:

```
open Examples/WildeGuess/WildeGuess.xcodeproj
```

Build and run the `WildeGuess` target to try it out!

If you're interested in viewing only the ComponentKit source code in Xcode:

```
open ComponentKit.xcodeproj
```

### Learn more

* Read the [Getting Started guide](http://www.componentkit.org/docs/getting-started)
* Get the [sample projects](https://github.com/facebook/componentkit/tree/master/Examples/WildeGuess)
* Read the [objc.io article](http://www.objc.io/issue-22/facebook.html) by Adam Ernst
* Watch the [@Scale talk](https://youtu.be/mLSeEoC6GjU?t=24m18s) by Ari Grant

## Contributing

See the [CONTRIBUTING](CONTRIBUTING.md) file for how to help out.

## License

ComponentKit is BSD-licensed. We also provide an additional patent grant.

The files in the /Examples directory are licensed under a separate license as specified in each file; documentation is licensed CC-BY-4.0.
