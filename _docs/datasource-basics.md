---
title: Basics
layout: docs
permalink: /docs/datasource-basics.html
---

In this section we will go through the steps to create a `UICollectionView` powered by components.

We will use a simple setup with a `UIViewController` using a `UICollectionView` that uses a `UICollectionViewFlowLayout`.

### Setup

#### Component Provider
The `CKCollectionViewDataSource` is responsible for transforming each model into a component.

This transformation will be defined as a method on a class conforming to `CKComponentProviding`. This class will then be passed to the `CKCollectionViewDataSource` as the component provider and the datasource will call the provider every time it needs to generate a component for a model.

Let's make our UIViewController be the component provider here.

```objc++
	@interface MyController <CKComponentProviding>
	...
	@end

	@implementation MyController
	...
	+ (CKComponent *)componentForModel:(MyModel*)model context:(MyContext*)context {
		return [MyComponent newWithModel:model context:context];
	}
	...
```

<div class="note-important">
 <p>
    This class method has to be pure and thread safe.
 </p>
</div>

- **Why use a class Method and not a block?** The model to component transform should not rely on mutable state. Blocks make it very easy to capture mutable state that could introduce side effects in the system. Using a class method allows to better enforce the constraint of immutability from an API standpoint.
- **What is this context ?** The context is an arbitrary immutable object, that is passed to this method by the `CKCollectionViewDataSource`. Typically, the context can be used to pass into your component tree:
	* immutable contextual informations such as the type of device.
	* external dependencies such as an image downloader.

<div class="note-important">
 <p>
Don't access global state inside a Component. Use the context to pass this information instead.
 </p>
</div>

#### Create a `CKCollectionViewDataSource`

Ok, so now we have our view controller as the component provider, let's create our `CKComponentCollectionViewDataSource` and attach the collection view to it.

```objc++
	- (void)viewDidLoad {
	...
	self.dataSource = _dataSource = [[CKCollectionViewDataSource alloc] initWithCollectionView:self.collectionView
                                                                  supplementaryViewDataSource:nil
                                                                            componentProvider:[self class]
                                                                                      context:context
                                                                    cellConfigurationFunction:nil];
```


Note that we pass the context in the initializer. It is the same context that will get passed into `+ (CKComponent *)componentForModel:context:` every time a component needs to be computed.

### Add/Modify content in the collection view

#### Changeset API
Using `CKCollectionViewDataSource` changes are never applied directly to the collection. Instead, commands are sent to the datasource and from those commands will be used to compute the components and apply the corresponding changes to the collection view.

Let's add a section at index 0 with two items at indexes 0 and 1.

```objc++
{% raw  %}
	- (void)viewDidAppear {
		...
		CKComponentDataSourceChangeset changeset;
		// Don't forget the insertion of section 0
		changeset.sections.insert(0);
		changeset.items.insert({0,0}, firstModel);
		// You can also use NSIndexPath
		NSIndexPath indexPath = [NSIndexPath indexPathForItem:1 inSection:0];
		changeset.items.insert(indexPath, secondModel);
		[self.dataSource enqueueChangeset:changeset constrainedSize:{{0,0}, {50, 50}}];
	}
{% endraw %}
```

Later on (for instance when updated data is received from the server), we can update our first item with an updated model.

```objc++
{% raw  %}
	...
	CKComponentDataSourceChangeset changeset;
	changeset.items.update({0,0}, udpatedFirstModel);
	[self.dataSource enqueueChangeset:changeset constrainedSize:{{50,0}, {50, INF}}];
	...
{% endraw %}
```

It is also possible to remove items and sections through this [changeset API](changeset-api.html).

#### Layout

As you can see above a *constrained size* is passed every time a changeset is enqueued, this constrained size is used internally to layout the components and compute their final sizes which will have to be within those top-level constraints.

The form of the constrained size is: {% raw  %}`{{minWidth, minHeight},{maxWidth, maxHeight}}`{% endraw %}.

Let's see how the computed component sizes can be used with the `UICollectionViewFlowLayout`, for the purpose of this example let's assume that the view controller is the delegate of the flow layout.

Each item is sized so that it matches the size of its corresponding component.

```objc++
	- (CGSize)collectionView:(UICollectionView *)collectionView
                 layout:(UICollectionViewLayout *)collectionViewLayout
                 sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
 		return [self.dataSource sizeForItemAtIndexPath:indexPath];
	}
```

Pretty simple right ? And this logic can apply to any `UICollectionViewLayout` :

- The datasource computes the size of the components within the top level constraint.
- Then those sizes can be used in a `UICollectionViewLayout` to size and position the corresponding items.

### Handle actions

Time to interact with those items now; nothing special here the regular selection APIs can be used. Let's say the models have a url that should be opened when the user tap on an item.

```objc++
	- (void)dataSource:(CKComponentCollectionViewDataSource *)dataSource didSelectItemAtIndexPath:(NSIndexPath *)indexPath
	{
 		MyModel *model = (MyModel *)[self.dataSource modelForItemAtIndexPath:indexPath];
 		NSURL *navURL = model.url;
 		if (navURL) {
 			[[UIApplication sharedApplication] openURL:navURL];
 		}
 	}
```
<div class="note-important">
 <p>
The datasource is the source of truth for the collection view, if you have to retrieve a model corresponding to an indexPath always use `-modelForItemAtIndexPath`. See this <a href="/docs/datasource-gotchas.html#the-datasource-involves-asynchronous-operations">gotcha</a> for more details.
 </p>
</div>
