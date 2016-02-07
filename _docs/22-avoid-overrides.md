---
title: Avoid Overrides
layout: docs
permalink: /docs/avoid-overrides.html
---
Method overrides make components more difficult to use.

Imagine you're adding an optional text color parameter to a component. You might be tempted to add an override:

{% highlight objc++ cssclass=redhighlight %}
@interface ArticleTextComponent
+ (instancetype)newWithText:(NSString *)text;
+ (instancetype)newWithText:(NSString *)text textColor:(UIColor *)textColor;
@end
{% endhighlight %}

But someone will later add another override:

{% highlight objc++ cssclass=redhighlight %}

  @interface ArticleTextComponent
  + (instancetype)newWithText:(NSString *)text;
  + (instancetype)newWithText:(NSString *)text textColor:(UIColor *)textColor;
  + (instancetype)newWithText:(NSString *)text backgroundColor:(UIColor *)textColor;
  + (instancetype)newWithText:(NSString *)text 
                    textColor:(UIColor *)textColor
              backgroundColor:(UIColor *)backgroundColor;
@end
{% endhighlight %}

The component is splintering. It's not obvious which override to use and we need a lot of boilerplate behind the scenes to redirect to the designated initializer.

Instead, always expose all parameters in a single designated initializer and document which are optional.

  ```objc++

@interface ArticleTextComponent
/**
 @param text The text to render in the component.
 @param textColor Optional; pass nil for the default.
 @param backgroundColor Optional; pass nil for the default.
 */
+ (instancetype)newWithText:(NSString *)text 
                  textColor:(UIColor *)textColor
            backgroundColor:(UIColor *)backgroundColor;
@end
```

If there are too many parameters, a useful pattern is a "style struct". For example, see `CKTextComponent`:

```objc++
struct CKTextKitAttributes {
  NSAttributedString *attributedString;
  NSAttributedString *truncationAttributedString;
  NSCharacterSet *avoidTailTruncationSet;
  NSLineBreakMode lineBreakMode;
  NSUInteger maximumNumberOfLines;
  CGSize shadowOffset;
  UIColor *shadowColor;
  CGFloat shadowOpacity;
  CGFloat shadowRadius;
};

@interface CKTextComponent : CKComponent
+ (instancetype)newWithTextAttributes:(const CKTextKitAttributes &)attributes
                       viewAttributes:(const CKViewComponentAttributeValueMap &)viewAttributes
                 accessibilityContext:(const CKTextComponentAccessibilityContext &)accessibilityContext;
@end
```

Using [aggregate initialization](http://en.cppreference.com/w/cpp/language/aggregate_initialization), it's easy to initialize the style struct with only some parameters:

```objc++
{
  .shadowColor = [UIColor blackColor],
  .maximumNumberOfLines = 1,
}
```
