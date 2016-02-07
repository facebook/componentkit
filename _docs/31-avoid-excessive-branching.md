---
title: Avoid Excessive Branching 
layout: docs
permalink: /docs/avoid-excessive-branching.html
---

Avoid excessive branching in component code; it hurts readability.

{% highlight objc++ cssclass=redhighlight %}
+ (instancetype)newWithArticle:(Article *)article
{
  CKComponent *headerComponent;
  if (article.featured) {
    headerComponent = [FeaturedArticleHeaderComponent newWithArticle:article];
  } else {
    headerComponent = [RegularArticleHeaderComponent newWithArticle:article];
  }

  UIEdgeInsets insets = {10, 10, 10, 10};
  CGFloat imageSize = 20;
  if (iPad) {
    insets = {20, 20, 20, 20};
    imageSize = 40;
  }

  return [super newWithComponent:
          [CKStackLayoutComponent
           newWithView:{}
           size:{}
           style:{}
           children:{
             {headerComponent},
             {[ArticleTextComponent
               newWithArticle:article 
               insets:insets
               imageSize:imageSize]},
           }]]
}
{% endhighlight %}

If you find yourself branching too much, consider separating your component into smaller components and composing them.

```objc++
+ (instancetype)newWithArticle:(Article *)article
{
  return [super newWithComponent:
          [CKStackLayoutComponent
           newWithView:{}
           size:{}
           style:{}
           children:{
             // Encapsulates the choice of Featured or Regular header:
             {[ArticleHeaderComponent newWithArticle:article]},
             // Encapsulates insets and image size:
             {[ArticleBodyComponent newWithArticle:article]},
           }]]
}
```
