---
title: Avoid Local Variables, Use Const
layout: docs
permalink: /docs/avoid-local-variables.html
---
In your `+new` method:

- **Prefer inlining** what would otherwise be a single-use temporary local variable.
- If inlining isn't possible due to necessary references or code duplication concerns, **add `const`** to the
right place to make sure the temporary local variable isn't assignable by  (E.g. `NSString *const foo`
instead of `NSString *foo`).

We avoid reassigning variables because:

- **It makes code harder to read and modify** since dependencies between local variables are hard to visualize.
- **It encourages mutating local variables after assignment** which hides surprising side-effects and changes.

Here is a really tangled-up `+new` method that is hard to read, understand, or modify:

{: .redhighlight }
{% highlight objc %}
+ (instancetype)newWithArticle:(ArticleModel *)article options:(ArticleOptions)options
{
  NSAttributedString *timestamp = [CKDateFormatter stringFromDate:article.creationTime];
  HeaderComponent *header =
  [HeaderComponent
   newWithTitle:article.title
   subtitle:timestamp];

  // LOGIC ERROR! timestamp has already been used by header, but no one warns us.
  if (options & ArticleOptionHideTimestamp) {
    timestamp = nil;
  }

  MessageOptions messageOptions = 0;
  if (options & ArticleOptionShortMessage) {
    messageOptions |= MessageOptionShort;
  }
  MessageComponent *message =
  [MessageComponent
   newWithArticle:article
   options:messageOptions];

  FooterComponent *footer = [FooterComponent newWithArticle:article];

  // SUBOPTIMAL: why did we create the header only to throw it away?
  // Also, notice how far this is from where we created the header.
  if (options & ArticleOptionOmitHeader) {
    header = nil;
  }

  return [self newWithComponent:
          [CKFlexboxComponent
           newWithChildren:{
             header,
             message,
             footer
           }]];
}
{% endhighlight %}

Instead, split out logic into separate components:

{% highlight objc %}
+ (instancetype)newWithArticle:(ArticleModel *)article options:(ArticleOptions)options
{
  // Note how there are NO local variables here at all.
  return [self newWithComponent:
          [CKFlexboxComponent
           newWithChildren:{
             [ArticleHeaderComponent
              newWithArticle:article
              options:headerOptions(options)],
             [ArticleMessageComponent
              newWithArticle:article
              options:messageOptions(options)],
             [FooterComponent newWithArticle:article]
           }]];
}

// Note how this is a pure function mapping from one options bitmask to another.
static ArticleHeaderComponentOptions headerOptions(ArticleOptions options)
{
  ArticleHeaderComponentOptions options;
  if (options & ArticleOptionOmitHeader) {
    options |= ArticleHeaderComponentOptionOmit;
  }
  if (options & ArticleOptionHideTimestamp) {
    options |= ArticleHeaderComponentOptionHideTimestamp;
  }
  return options;
}
{% endhighlight %}
