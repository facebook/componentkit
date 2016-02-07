---
title: Dive Deeper
layout: docs
permalink: /docs/datasource-dive-deeper.html
---

#CKComponentDataSource in details

Here is what happens behind the scenes where a changeset is enqueued:

<img src="/static/images/datasource.png" alt="Overwiew of the datasource" width ="592" height="654">

<div class="note">
  <p>
    We will use "list view" to refer to either a <code>UICollectionView</code> or a <code>UITableView</code>
  </p>
</div>

1. A changeset is enqueued in `CKComponentDataSource` (maybe proxied by CKCollectionViewDataSource or another adapter), the CKComponentDataSource updates its internal input state.
2. Changes are asynchronously enqueued in the preparation queue and processed in the background. Each model in the changeset will get it's component tree generated and laid out by calling the `componentForModel:` function on the componentProvider.
3. Once the components are computed, the output changeset is processed:
    1. The output changeset is applied to the internal output state of `CKComponentDataSource`.
    2. `CKComponentDataSource` messages its delegate with the changeset.
    3. This changeset triggers a batch update of the list view it has a reference to. This is the way `CKComponentCollectionViewDataSource` is set up. When the output changeset is received, it will call `- performBatchUpdates:completion:` on the collection view with the right mutation calls.
4. The list view will then request updated content, either immediately if some updated content is visible or later when the updated content will become visible while scrolling :
    1. Either `-cellForRowAtIndexPath:` or `cellForItemAtIndexPath:` will be called by the list view on its datasource.
    2. The datasource calls the `CKComponentDataSource` to get an handle (a `CKComponentLifeCycleManager` in this case) on the most up to date component tree.
    3. The `CKComponentLifeCycleManager` is then returned to the list view datasource that will mount the component tree on the cell.
    4. Which is then returned to the list view that will display it.

#Use CKComponentDataSource directly


`CKCollectionViewDataSource` should be sufficient for most uses of ComponentKit with a collection view. If you need more control or want to use a components datasource with a different type of views you can still use `CKComponentDataSource` directly.

Here is an example of usage of `CKComponentDataSource` directly with a UIViewController. You can also go inspect the source code of `CKCollectionViewDataSource` and see how it's done.

## Example: Use it in your ViewController to power a UITableView

`ComponentsTableViewController.h`

```objc++
{% raw  %}
/* This file provided by Facebook is for non-commercial testing and evaluation
 * purposes only.  Facebook reserves all rights not expressly granted.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import <UIKit/UIKit.h>

@interface ComponentsTableViewController : UIViewController

@end
{% endraw  %}
```

`ComponentTableViewController.mm`

```objc++
{% raw  %}
/* This file provided by Facebook is for non-commercial testing and evaluation
 * purposes only.  Facebook reserves all rights not expressly granted.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "ComponentsTableViewController.h"

#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/CKComponentDataSource.h>
#import <ComponentKit/CKComponentDataSourceOutputItem.h>
#import <ComponentKit/CKComponentConstantDecider.h>
#import <ComponentKit/CKDimension.h>
#import <ComponentKit/CKTextComponent.h>

static NSString *const kReuseIdentifier = @"com.component_kit.table_view_data_source.cell";

@interface ComponentsTableViewController () <
CKComponentProvider,
CKComponentDataSourceDelegate,
UITableViewDataSource,
UITableViewDelegate
>

@end

@implementation ComponentsTableViewController {
  UITableView *_tableView;
  CKComponentDataSource *_componentDataSource;
  CKSizeRange _constrainedSize;
}

- (void)loadView
{
  _tableView = [[UITableView alloc] init];
  [self setView:_tableView];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kReuseIdentifier];
  _tableView.dataSource = self;
  _tableView.delegate = self;
  _componentDataSource = [[CKComponentDataSource alloc] initWithComponentProvider:[self class]
                                                                          context:nil
                                                                          decider:[[CKComponentConstantDecider alloc] initWithEnabled:@YES]];
  _componentDataSource.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  // Insert the initial section and two rows in the componentDataSource
  CKArrayControllerSections sections;
  CKArrayControllerInputItems items;
  sections.insert(0);
  items.insert({0,0}, @"Hello");
  items.insert({0,1}, @"World !");
  CGFloat tableViewWidth = _tableView.bounds.size.width;
  [_componentDataSource enqueueChangeset:{sections, items}
                         constrainedSize:{{tableViewWidth, 0},{tableViewWidth, INFINITY}}];
}

#pragma mark - UITableViewDatasource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  // Grab the output item
  CKComponentDataSourceOutputItem *outputItem = [_componentDataSource objectAtIndexPath:indexPath];
  // Dequeue a table view cell
  UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:kReuseIdentifier];
  // Get the lifecycle manager
  CKComponentLifecycleManager *lifecycleManager = [outputItem lifecycleManager];
  // Mount the corresponding component tree in the cell container view
  [lifecycleManager attachToView:cell.contentView];
  return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  // Query the datasource for the height of the corresponding component
  return [[[_componentDataSource objectAtIndexPath:indexPath] lifecycleManager] size].height;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return [_componentDataSource numberOfSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return [_componentDataSource numberOfObjectsInSection:section];
}

#pragma mark - CKComponentDatasourceDelegate

- (void)componentDataSource:(CKComponentDataSource *)componentDataSource
          hasChangesOfTypes:(CKComponentDataSourceChangeType)changeTypes
        changesetApplicator:(ck_changeset_applicator_t)changesetApplicator
{
  // Once the datasource has computed the components, perform a batch update
  // on the tableView to insert/delete/update rows and insert/delete sections.
  [_tableView beginUpdates];
  const auto &changeset = changesetApplicator();
  applyChangesetToTableView(changeset, _tableView);
  [_tableView endUpdates];
}

static void applyChangesetToTableView(const CKArrayControllerOutputChangeset &changeset, UITableView *tableView)
{
  CKArrayControllerSections::Enumerator sectionsEnumerator = ^(NSIndexSet *sectionIndexes, CKArrayControllerChangeType type, BOOL *stop) {
    if (type == CKArrayControllerChangeTypeDelete) {
      [tableView deleteSections:sectionIndexes withRowAnimation:UITableViewRowAnimationFade];
    }
    if (type == CKArrayControllerChangeTypeInsert) {
      [tableView insertSections:sectionIndexes withRowAnimation:UITableViewRowAnimationFade];
    }
  };

  CKArrayControllerOutputItems::Enumerator itemEnumerator =
  ^(const CKArrayControllerOutputChange &change, CKArrayControllerChangeType type, BOOL *stop) {
    NSIndexPath *indexPath = change.indexPath.toNSIndexPath();
    if (type == CKArrayControllerChangeTypeDelete) {
      [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    if (type == CKArrayControllerChangeTypeInsert) {
      [tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    if (type == CKArrayControllerChangeTypeUpdate) {
      [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
  };

  // Enumerate over the changeset and for each type of change perform the corresponding changes
  // on the table view
  changeset.enumerate(sectionsEnumerator, itemEnumerator);
}

- (void)componentDataSource:(CKComponentDataSource *)componentDataSource
     didChangeSizeForObject:(CKComponentDataSourceOutputItem *)object
                atIndexPath:(NSIndexPath *)indexPath
                  animation:(const CKComponentBoundsAnimation &)animation
{
  [_tableView beginUpdates];
  [_tableView endUpdates];
}

#pragma mark - CKComponentProvider

+ (CKComponent *)componentForModel:(NSString *)model context:(id<NSObject>)context
{
  return
   [CKTextComponent
    newWithTextAttributes:{
      .attributedString =
      [[NSAttributedString alloc]
       initWithString:model
       attributes:@{NSFontAttributeName: [UIFont fontWithName:@"AmericanTypewriter" size:26]}]
    }
    viewAttributes:{{@selector(setBackgroundColor:), [UIColor clearColor]}}
    accessibilityContext:{}];
}

@end
{% endraw  %}
```
