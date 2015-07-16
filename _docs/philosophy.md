---
title: Philosophy
layout: docs
permalink: /docs/philosophy.html
---

Components are immutable objects that specify how to configure views.

A simple analogy is to think of a component as a stencil: a fixed description that can be used to *paint* a view but that is not a view itself. A component is often composed of other components, building up a component hierarchy that *describes* a user interface.

Let's see some sample code for rendering an article in a news app:

```objc++
@implementation ArticleComponent

+ (instancetype)newWithArticle:(ArticleModel *)article
{
  return [super newWithComponent:
          [CKStackLayoutComponent
           newWithView:{}
           size:{}
           style:{
             .direction = CKStackLayoutDirectionVertical,
           }
           children:{
             {[HeaderComponent newWithArticle:article]},
             {[MessageComponent newWithMessage:article.message]},
             {[FooterComponent newWithFooter:article.footer]},
           }];
}

@end
```

Components have three characteristics:

- **Declarative**: Instead of implementing `-sizeThatFits:` and `-layoutSubviews` and positioning subviews manually, you declare the subcomponents of your component (here, we say "stack them vertically").

- **Functional**: Data flows in one direction. Methods take data models and return totally immutable components. When state changes, ComponentKit re-renders from the root and reconciles the two component trees from the top with as few changes to the view hierarchy as possible.

- **Composable**: Here `FooterComponent` is used in a article, but it could be reused for other UI with a similar footer. Reusing it is a one-liner. `CKStackLayoutComponent` is inspired by the [flexbox model](http://www.w3.org/TR/css3-flexbox) of the web and can easily be used to implement many layouts.
