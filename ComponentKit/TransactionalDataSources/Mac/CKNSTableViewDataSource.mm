/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKNSTableViewDataSource.h"


#import <ComponentKit/CKArgumentPrecondition.h>
#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKMacros.h>

#import "CKComponentLayout.h"
#import "CKTransactionalComponentDataSource.h"
#import "CKTransactionalComponentDataSourceState.h"
#import "CKTransactionalComponentDataSourceListener.h"
#import "CKTransactionalComponentDataSourceItem.h"
#import "CKTransactionalComponentDataSourceAppliedChanges.h"
#import "CKTransactionalComponentDataSourceChangeset.h"

#import "CKComponent.h"

#import "CKComponentRootView.h"
#import "CKComponentScopeRoot.h"
#import "CKTransactionalComponentDataSourceConfiguration.h"

@interface CKNSTableViewDataSource () <CKTransactionalComponentDataSourceListener>
@end

@implementation CKNSTableViewDataSource
{
  CKTransactionalComponentDataSource *_componentDataSource;
  NSMapTable *_cellToItemMap;
}

CK_FINAL_CLASS([CKNSTableViewDataSource class]);

#pragma mark - Lifecycle

- (instancetype)initWithTableView:(NSTableView *)tableView
                componentProvider:(Class<CKComponentProvider>)componentProvider
                          context:(id<NSObject>)context
{
  self = [super init];
  if (self) {
    auto config = [[CKTransactionalComponentDataSourceConfiguration alloc] initWithComponentProvider:componentProvider
                                                                                             context:context
                                                                                           sizeRange:CKSizeRange()];

    _componentDataSource = [[CKTransactionalComponentDataSource alloc] initWithConfiguration:config];

    [_componentDataSource addListener:self];

    _tableView = tableView;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    
    _cellToItemMap = [NSMapTable weakToStrongObjectsMapTable];
  }
  return self;
}

- (instancetype)init
{
  CK_NOT_DESIGNATED_INITIALIZER();
}

#pragma mark - Changesets

- (void)applyChangeset:(CKTransactionalComponentDataSourceChangeset *)changeset
                  mode:(CKUpdateMode)mode
              userInfo:(NSDictionary *)userInfo
{
  [_componentDataSource applyChangeset:changeset mode:mode userInfo:userInfo];
}

- (id<NSObject>)modelForRow:(NSInteger)rowIndex
{
  return [[[_componentDataSource state] objectAtIndexPath:[NSIndexPath indexPathForItem:rowIndex inSection:0]] model];
}

- (CGFloat)heightForRow:(NSInteger)rowIndex
{
  return [[[_componentDataSource state] objectAtIndexPath:[NSIndexPath indexPathForItem:rowIndex inSection:0]] layout].size.height;
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
  return _componentDataSource.state.numberOfSections > 0 ? [[_componentDataSource state] numberOfObjectsInSection:0] : 0;
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
  static NSString *reuseIdentifier = @"ComponentKit";

  // Dequeue a reusable cell for this identifer
  NSView *v = [tableView makeViewWithIdentifier:reuseIdentifier owner:nil];
  if (!v) {
    v = [[NSView alloc] initWithFrame:CGRect{{0,0}, {100, 100}}];
    v.identifier = reuseIdentifier;
  }

  CKTransactionalComponentDataSourceItem *item = [[_componentDataSource state] objectAtIndexPath:[NSIndexPath indexPathForItem:row inSection:0]];
  const CKComponentLayout &layout = item.layout;

  CKMountComponentLayout(layout, v, nil, nil);

  return v;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
  CKTransactionalComponentDataSourceItem *item = [[_componentDataSource state] objectAtIndexPath:[NSIndexPath indexPathForItem:row inSection:0]];
  const CKComponentLayout &layout = item.layout;
  return layout.size.height;
}

#pragma mark - CKTransactionalComponentDataSourceListener

static NSIndexSet *firstSectionIndexSet(NSSet *indices) {
  NSMutableIndexSet *s = [NSMutableIndexSet indexSet];
  for (NSIndexPath *ip in indices) {
    if (ip.section == 0) {
      [s addIndex:ip.row];
    }
  }
  return [s copy];
}

- (void)transactionalComponentDataSource:(CKTransactionalComponentDataSource *)dataSource
                  didModifyPreviousState:(CKTransactionalComponentDataSourceState *)previousState
                       byApplyingChanges:(CKTransactionalComponentDataSourceAppliedChanges *)changes
{
  [_tableView beginUpdates];

  [_tableView removeRowsAtIndexes:firstSectionIndexSet(changes.removedIndexPaths)
                    withAnimation:NSTableViewAnimationEffectNone];

  [_tableView insertRowsAtIndexes:firstSectionIndexSet(changes.insertedIndexPaths)
                    withAnimation:NSTableViewAnimationEffectNone];

  [_tableView reloadDataForRowIndexes:firstSectionIndexSet(changes.updatedIndexPaths)
                        columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSRange{.length = NSUInteger(_tableView.numberOfColumns)}]];

  [changes.movedIndexPaths enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *key, NSIndexPath *obj, BOOL *stop) {
    [_tableView moveRowAtIndex:key.row toIndex:obj.row];
  }];

  [_tableView endUpdates];
}

@end
