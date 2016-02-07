---
title: Changeset API
layout: docs
permalink: /docs/datasource-changeset-api.html
---

Changesets are how you interact with the datasource. They allow you to "enqueue" sets of commands to be processed by the datasource.


These commands can be seen as a sentence with three parts :

1. **action** (insert/delete/udpate for items, insert/delete for sections)
2. **position specifier** (indexPath for items, index for sections)
3. **model** (that will be used to compute the components)

Here is some sample code, showing how to create a changeset - As you can see changesets are a c++ structure.

```objc++
CKArrayControllerInputItems items;
// Insert an item at index 0 in section 0 and compute the component for the model @"Hello"
items.insert({0, 0}, @"Hello");
// Update the item at index 1 in section 0 and update it with the component computed for the model @"World"
items.update({0, 1}, @"World");
// Delete the item at index 2 in section 0, no need for a model here :)
Items.delete({0, 2});

Sections sections;
sections.insert(0);
sections.insert(2);
sections.insert(3);

[datasource enqueueChangeset:{sections, items}];
```

Changes can also be created from `NSIndexPaths` :

```objc++
CKArrayControllerInputItems items;
NSIndexPath *insertionIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
items.insert({insertionIndexPath}, @"Hello");
```

You can even get rid of the brackets around the `NSIndexPath`, thanks to [C++ converting constructors](http://en.cppreference.com/w/cpp/language/converting_constructor) :

```objc++
CKArrayControllerInputItems items;
NSIndexPath *insertionIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
items.insert(insertionIndexPath, @"Hello");
```


## Order in which changes are applied.

<div class="note-important">
 <p>
 The order in which commands are added to the changeset doesn't define the order in which those changes will eventually be applied to the `UICollectionView` (same for `UITableViews`).
 </p>
</div>

Be wary of this fact while computing a changeset, the conventions defined in Cocoa for batch updates are as follows:

- **Deletions and Updates are applied first using the current index space.**
- **Insertions are then applied in the post deletions index space (updates obviously won't modify the index space).**

You can consult the [following section](https://developer.apple.com/library/prerelease/ios/documentation/UserExperience/Conceptual/TableView_iPhone/ManageInsertDeleteRow/ManageInsertDeleteRow.html) in the apple documentation to get more information.
