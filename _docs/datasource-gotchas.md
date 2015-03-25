---
title: Gotchas
layout: docs
permalink: /docs/datasource-gotchas.html
---


## Don't forget the initial section

A datasource will initially be totally empty (no items and no sections). Inserting items in section 0 before inserting section 0 will cause an exception to be raised.

{% highlight objc++ cssclass=redhighlight %}
{% raw  %}
CKComponentCollectionViewDataSource datasource = [[CKComponentCollectionViewDataSource alloc] ...];
CKArrayControllerInputItems items;
items.insert({0, 0}, @"Hello");
// Will raise an exception
[datasource enqueueChangeset:{items}];
{% endraw  %}
{% endhighlight %}

{% highlight objc++ %}
{% raw  %}
CKComponentCollectionViewDataSource datasource = [[CKComponentCollectionViewDataSource alloc] ...];
CKArrayControllerInputItems items;
CKArrayControllerSections sections;
sections.insert(0);
items.insert({0, 0}, @"Hello");
[datasource enqueueChangeset:{sections, items}];
{% endraw  %}
{% endhighlight %}

<div class="note">
 <p>
 Why not have one section by default? Because implicit/default behaviors can be confusing.
 If that behavior was implemented as a default but not documented, it would be very confusing when inserting a section at index 0 on a newly created datasource will actually cause it to have two sections (we already have the one created by default).
 Obviously documentation would make things better but it's easy to miss a piece of documentation...
 </p>
</div>

## Lifecycle

The lifecycle of the datasource should match the lifecycle of the collection view or table view it is used with. You might otherwise end up with the content of your list view being out of sync with the internal state of the datasource and this will cause a crash eventually.

## The datasource involves asynchronous operations

**Each changeset is computed asynchronously** by `CKComponentDatasource`, therefore the corresponding changes are not reflected immediately on the corresponding `UITableView` or `UICollectionView` and it is important to be careful about sources of data being out of sync.

#### Always ask the datasource for the model corresponding to an index path

The datasource maintains an internal data structure which is the only source of truth for the corresponding `UICollectionView` or `UITableView`. For this reason you should query the datasource to get information associated with a certain indexPath. Any other source of data may be out of sync with the current state of the list view.

For instance to access the model associated to a certain index path using a `CKCollectionViewDataSource` you can use:

```objc++
[datasource objectAtindexPath:indexPath];
```

Now let's look at what could go wrong if we query another source of data.

{% highlight objc++ cssclass=redhighlight %}  
{% raw  %}
@implementation MyAwesomeController {
    CKComponentCollectionViewDataSource *_datasource;
    NSMutableArray *_listOfModels;
}

- (void)insertAtHead:(id)model {
// We first add the new model (B) at the beginning of _listOfModels which already contained (A)
    // [A] -> [B, A]
  [_listOfModels insertObject:model atIndex:0];
  CKArrayControllerInputItems items;
  items.insert({0, 0});
  // Enqueue the changeset asynchronously in the datasource
  [_datasource enqueueChangeset:{{}, items}];
}

- (void)didSelectitemAtIndexPath:(NSIndexPath *)indexPath {
// At the same time the user taps on the cell that represents A, which is still located at the indexPath (0,0)
// as the changeset has not finished computing yet.
// Ouch we actually get B, list of models and the collection view are out of sync
[_listOfModels objectAtIndex:indexPath.row];
// [_datasource modelForItemAtIndexPath:indexPath] would have properly returned A
}
{% endraw  %}
{% endhighlight %}

#### Don't ask the the list view for the position of the next insertion

The datasource gives you the current state of what is displayed on the screen, but it doesn't include what is potentially currently being computed in the background. To get this information you need to maintain state that is updated at the same time as a changeset is enqueued.

Let's look at this buggy code that uses the datasource to compute the insertion index.

{% highlight objc++ cssclass=redhighlight %}
{% raw  %}
@implementation MyAwesomeController {
    CKComponentCollectionViewDataSource *_datasource;
    NSMutableArray *_listOfModels;
}

- (void)insertAtTail:(id)model {
// We first add the new model (C) at the end of _listOfModels which already contains (A) et (B)
    // [A, B] -> [A, B, C]
  [_listOfModels addObject:model];
  CKArrayControllerInputItems items;
  // Only A is in the tableView, the components for B are still computed in the background
  // so numberOfItemsInSection returns 1, C will be inserted at index 1 and we will end up
  // with a list view displaying [A, C, B]
  Items.insert({0, _datasource.collectionView numberOfItemsInSection});
  // Enqueue the changeset asynchronously in the datasource
  [_datasource enqueueChangeset:{{}, items}];
}
{% endraw  %}
{% endhighlight %}

In `-insertAtTail` we should check `_listOfModels` instead to compute the insertion index.

{% highlight objc++ %}
{% raw  %}
- (void)insertAtTail:(id)model {
// We first add the new model (C) at the end of _listOfModels which already contains (A) et (B)
    // [A, B] -> [A, B, C]
  [_listOfModels addObject:model];
  CKArrayControllerInputItems items;
  // We properly insert C at index 2
  Items.insert({0, [_listOfModels count] ? [_listOfModels count] -1 : 0});
  // Enqueue the changeset asynchronously in the datasource
  [_datasource enqueueChangeset:{{}, items}];
}
{% endraw  %}
{% endhighlight %}
