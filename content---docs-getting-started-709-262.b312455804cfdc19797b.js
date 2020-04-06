(window.webpackJsonp=window.webpackJsonp||[]).push([[31],{127:function(e,t,n){"use strict";n.r(t),n.d(t,"frontMatter",function(){return s}),n.d(t,"rightToc",function(){return c}),n.d(t,"default",function(){return u});n(0);var o=n(133),a=n(134),r=n.n(a);function i(){return(i=Object.assign||function(e){for(var t=1;t<arguments.length;t++){var n=arguments[t];for(var o in n)Object.prototype.hasOwnProperty.call(n,o)&&(e[o]=n[o])}return e}).apply(this,arguments)}function l(e,t){if(null==e)return{};var n,o,a=function(e,t){if(null==e)return{};var n,o,a={},r=Object.keys(e);for(o=0;o<r.length;o++)n=r[o],t.indexOf(n)>=0||(a[n]=e[n]);return a}(e,t);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);for(o=0;o<r.length;o++)n=r[o],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(a[n]=e[n])}return a}var s={title:"Getting Started"},c=[],p={rightToc:c},b="wrapper";function u(e){var t=e.components,n=l(e,["components"]);return Object(o.b)(b,i({},p,n,{components:t,mdxType:"MDXLayout"}),Object(o.b)("p",null,"Let's get a sample app powered by ComponentKit up and running, then make some tweaks to experiment with how components work."),Object(o.b)("p",null,"Clone the Github repo, install carthage frameworks and then open the Xcode project."),Object(o.b)("p",null,'(You may need to install Carthage first, e.g. with "brew install carthage" on macOS.)'),Object(o.b)("pre",null,Object(o.b)("code",i({parentName:"pre"},{className:"language-bash"}),"$ git clone https://github.com/facebook/componentkit\n$ cd componentkit\n$ carthage checkout\n$ cd Examples/WildeGuess/\n$ open WildeGuess.xcodeproj\n")),Object(o.b)("p",null,"Run the project in the simulator to see a simple app that shows a list of quotes."),Object(o.b)("p",null,"Let's imagine we want to remove the white quote mark that's circled in this screenshot:"),Object(o.b)("img",{src:r()("assets/quote-before.png"),width:"250",height:"431",alt:"FrostedQuoteComponent screenshot with quote mark circled"}),Object(o.b)("p",null,"First we'll need to figure out which component we need to change. Pause the app in the debugger and execute the following command in lldb. This inserts special debug views in the hierarchy, as described in ",Object(o.b)("a",i({parentName:"p"},{href:"/docs/debugging"}),"Debugging"),"."),Object(o.b)("pre",null,Object(o.b)("code",i({parentName:"pre"},{className:"language-objectivec"}),"(lldb) e (void)[CKComponentDebugController setDebugMode:YES]\n")),Object(o.b)("p",null,"Then click the ",Object(o.b)("a",i({parentName:"p"},{href:"https://developer.apple.com/library/ios/recipes/xcode_help-debugger/using_view_debugger/using_view_debugger.html"}),"Debug View Hierarchy")," button in Xcode and browse through the view hierarchy:"),Object(o.b)("img",{alt:"Debugger showing FrostedQuoteComponent",src:r()("assets/debugger-frosted-quote.png")}),Object(o.b)("p",null,"Aha! So we need to modify ",Object(o.b)("inlineCode",{parentName:"p"},"FrostedQuoteComponent"),". That file should make a few things clear:"),Object(o.b)("ul",null,Object(o.b)("li",{parentName:"ul"},"It uses the ",Object(o.b)("inlineCode",{parentName:"li"},"LosAngeles")," background image."),Object(o.b)("li",{parentName:"ul"},"The content is inset by 20 points on the left and right, 70 points on the top, and 25 points on the bottom."),Object(o.b)("li",{parentName:"ul"},"The content is made up of two components stacked vertically: a ",Object(o.b)("inlineCode",{parentName:"li"},"CKLabelComponent")," with the quote, and a second ",Object(o.b)("inlineCode",{parentName:"li"},"CKLabelComponent")," with an end quote symbol.")),Object(o.b)("p",null,"The quote mark is created here:"),Object(o.b)("pre",null,Object(o.b)("code",i({parentName:"pre"},{className:"language-objectivec"}),'{\n  // A semi-transparent end quote (") symbol placed below the quote.\n  [CKInsetComponent\n   ... (omitted) ...],\n  .alignSelf = CKFlexboxAlignSelfEnd, // Right aligned\n}\n')),Object(o.b)("p",null,"Delete everything (including the curly braces), so that the ",Object(o.b)("inlineCode",{parentName:"p"},"CKFlexboxComponent")," only has a single child. Run the app again and the quote mark is gone!"),Object(o.b)("img",{src:r()("assets/quote-after.png"),width:"250",height:"431",alt:"FrostedQuoteComponent screenshot with quote mark removed"}),Object(o.b)("p",null,"Things look a little imbalanced now, though. There are 70 points of padding on top and only 25 points on bottom. Modify the\n",Object(o.b)("inlineCode",{parentName:"p"},"CKInsetComponent")," to change the bottom padding to be 70 points as well:"),Object(o.b)("pre",null,Object(o.b)("code",i({parentName:"pre"},{className:"language-objectivec"}),"[CKInsetComponent\n newWithInsets:{.top = 70, .bottom = 70, .left = 20, .right = 20}\n")),Object(o.b)("p",null,"Run the app once more. Now it looks a lot better:"),Object(o.b)("img",{src:r()("assets/quote-tweaked.png"),width:"250",height:"431",alt:"FrostedQuoteComponent screenshot with spacing tweaked"}),Object(o.b)("p",null,"Congratulations! You've done your first development with ComponentKit. Keep poking around the sample app to learn more, or start using it in your own apps."))}u.isMDXComponent=!0}}]);