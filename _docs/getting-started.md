---
title: Getting Started
layout: docs
permalink: /docs/getting-started.html
---

Let's get a sample app powered by ComponentKit up and running, then make some tweaks to experiment with how components work.

Clone the Github repo and run `pod install` to set up the example app, then open the workspace:

```sh
$ git clone git@github.com:facebook/componentkit.git
$ cd componentkit/Examples/WildeGuess/
$ pod install
$ open WildeGuess.xcworkspace
```

Run the project in the simulator to see a simple app that shows a list of quotes.

Let's imagine we want to remove the white quote mark that's circled in this screenshot:

<img src="/static/images/quote-before.png" width="250" height="431" alt="FrostedQuoteComponent screenshot with quote mark circled">

First we'll need to figure out which component we need to change. Pause the app in the debugger and execute the following command in lldb. This inserts special debug views in the hierarchy, as described in [Debugging](debugging.html).

```
(lldb) e (void)[CKComponentDebugController setDebugMode:YES]
```

Then click the [Debug View Hierarchy](https://developer.apple.com/library/ios/recipes/xcode_help-debugger/using_view_debugger/using_view_debugger.html) button in Xcode and browse through the view hierarchy:

<img src="/static/images/debugger-frosted-quote.png" alt="Debugger showing FrostedQuoteComponent">

Aha! So we need to modify `FrostedQuoteComponent`. That file should make a few things clear:

- It uses the `LosAngeles` background image.
- The content is inset by 20 points on the left and right, 70 points on the top, and 25 points on the bottom.
- The content is made up of two components stacked vertically: a `CKLabelComponent` with the quote, and a second `CKLabelComponent` with an end quote symbol.

The quote mark is created here:

```
{
  // A semi-transparent end quote (") symbol placed below the quote.
  [CKInsetComponent
   ... (omitted) ...],
  .alignSelf = CKStackLayoutAlignSelfEnd, // Right aligned
}
```

Delete everything (including the curly braces), so that the `CKStackLayoutComponent` only has a single child. Run the app again and the quote mark is gone!

<img src="/static/images/quote-after.png" width="250" height="431" alt="FrostedQuoteComponent screenshot with quote mark removed">

Things look a little imbalanced now, though. There are 70 points of padding on top and only 25 points on bottom. Modify the 
`CKInsetComponent` to change the bottom padding to be 70 points as well:

```objc++
[CKInsetComponent
 newWithInsets:{.top = 70, .bottom = 70, .left = 20, .right = 20}
```

Run the app once more. Now it looks a lot better:

<img src="/static/images/quote-tweaked.png" width="250" height="431" alt="FrostedQuoteComponent screenshot with spacing tweaked">

Congratulations! You've done your first development with ComponentKit. Keep poking around the sample app to learn more, or start using it in your own apps. Just add the following to your Podfile:

```
pod 'ComponentKit', '~> 0.9'
```
