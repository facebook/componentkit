/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKMSampleTableComponent.h"

#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKNSTableViewDataSource.h>
#import <ComponentKit/CKTransactionalComponentDataSourceChangeset.h>

@interface CKMSampleTableComponent () {
  @package
  CKComponent *_table;
  Class _cellProviderClass;
}

@property (nonatomic, copy, readonly) NSArray *models;

@end

@interface CKMSampleTableComponentController : CKComponentController
@end

@implementation CKMSampleTableComponentController {
  NSTableView *_tableView;
  CKNSTableViewDataSource *_dataSource;
  NSArray *_model;
}

- (void)dealloc
{

}

- (NSTableView *)tableView
{
  return (NSTableView *)self.tableComponent->_table.viewContext.view;
}

- (CKMSampleTableComponent *)tableComponent
{
  return (CKMSampleTableComponent *)self.component;
}

static CKTransactionalComponentDataSourceChangeset *insertItems(NSArray *models, NSUInteger startIndex) {
  NSMutableDictionary *insert = [NSMutableDictionary dictionary];
  NSInteger idx = startIndex;
  for (id model : models) {
    insert[[NSIndexPath indexPathForItem:idx inSection:0]] = model;
    idx++;
  }
  return [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset] withInsertedItems:insert] build];
};

- (void)didMount
{
  [super didMount];

  _tableView = self.tableView;

  _dataSource = [[CKNSTableViewDataSource alloc] initWithTableView:_tableView
                                                 componentProvider:self.tableComponent->_cellProviderClass
                                                           context:self];


  // Make sure we have 1 section
  CKTransactionalComponentDataSourceChangeset *base =
  [[CKTransactionalComponentDataSourceChangeset alloc] initWithUpdatedItems:nil
                                                               removedItems:nil
                                                            removedSections:nil
                                                                 movedItems:nil
                                                           insertedSections:[NSIndexSet indexSetWithIndex:0]
                                                              insertedItems:nil];

  [_dataSource applyChangeset:base mode:CKTransactionalComponentDataSourceModeSynchronous userInfo:nil];


  // This only works the first time. To get it working more generally, you would need to compute the changeset from the old to new states.
  [_dataSource applyChangeset:insertItems(self.tableComponent.models, 0)
                         mode:CKTransactionalComponentDataSourceModeAsynchronous
                     userInfo:nil];

}

- (void)didRemount
{
  [super didRemount];
}

- (void)didUnmount
{
  [super didUnmount];
}

@end

@implementation CKMSampleTableComponent

+ (instancetype)newWithScrollView:(CKComponentViewConfiguration)scrollView
                        tableView:(CKComponentViewConfiguration)tableView
                           models:(NSArray *)modelObjects
                componentProvider:(Class)componentProvider
                             size:(CKComponentSize)size;
{
  CKComponentScope s(self);

  CKMSampleTableComponent *c =
  [self newWithView:scrollView
               size:size];

  if (!c) return nil;

  c->_table = [CKComponent newWithView:tableView size:size];
  c->_cellProviderClass = componentProvider;
  c->_models = [modelObjects copy];

  return c;
}

- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
{
  CKComponentLayoutChild table = {{0,0}, [_table layoutThatFits:constrainedSize parentSize:constrainedSize.min]};
  return {self, constrainedSize.min, {table}};
}

- (CK::Component::MountResult)mountInContext:(const CK::Component::MountContext &)context
 size:(const CGSize)size
children:(std::shared_ptr<const std::vector<CKComponentLayoutChild>>)children
supercomponent:(CKComponent *)supercomponent
{
  auto result = [super mountInContext:context size:size children:children supercomponent:supercomponent];

  // Mount manually
  NSScrollView *scroll = (NSScrollView *)self.viewContext.view;

  // Mount the tableView in the scrollView

  auto &tableLayout = (*children)[0].layout;

  CKMountComponentLayout(tableLayout, scroll.contentView);

  // Now we're in the content view
  NSTableView *tableView = (NSTableView *)_table.viewContext.view;

  // This causes jumps when resizing, but if I don't reset it, then selection dragging doesn't scroll the scrollview.
  scroll.documentView = tableView;

  tableView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

  // Setup tableView in a sane way
  if (tableView.numberOfColumns == 0) {
    NSTableColumn *c = [[NSTableColumn alloc] initWithIdentifier:@"HAHA"];
    c.width = scroll.bounds.size.width;
    c.minWidth = 100;
    c.maxWidth = 1000000;
    c.resizingMask = NSTableColumnAutoresizingMask;
    [tableView addTableColumn:c];

    tableView.headerView = nil;

    tableView.columnAutoresizingStyle = NSTableViewUniformColumnAutoresizingStyle;
  }

  
  return {false, result.contextForChildren};
}


@end
