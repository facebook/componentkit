---
title: Indentation
layout: docs
permalink: /docs/indentation.html
---

Because components are often deeply nested structures, it's rarely possible to fit them on one line. We've developed some best practices for indentation unique to Components code. These rules should generally *not* be applied to non-Components code.

- Put a newline before `new`, so that parameters left-align instead of aligning by semicolon.
- Put a newline after `:` if the parameter value stretches to multiple lines.
- Consider putting a newline after `=` or `return` if it reduces nesting.

<div class="note">
  <p>
     These are guidelines, not ironclad rules. Feel free to ignore them on a case-by-case basis.
  </p>
</div>

This is hard to read:

{: .redhighlight }
{% highlight objc %}
HeaderComponent *header = [HeaderComponent newWithTitle:@"Hello world"
                                      subtitleComponent:[SubtitleComponent newWithSubtitle:subtitle
                                                                                     image:image]
                                                  image:image];
{% endhighlight %}

<p>Much better:</p>

{% highlight objc %}
HeaderComponent *header =
[HeaderComponent
 newWithTitle:@"Hello world"
 subtitleComponent:
 [SubtitleComponent
  newWithSubtitle:subtitle
  image:image]
 image:image];
{% endhighlight %}

<p>Within a statement, indent by only one space.</p>

<div class="note">
  <p>
     You never have to indent manually. After inserting newlines as described above, use <code>Ctrl-I</code> (Editor ▶︎ Structure ▶︎ Re-Indent) to make Xcode do the indentation work for you.
  </p>
</div>
