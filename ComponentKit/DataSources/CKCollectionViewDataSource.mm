/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKCollectionViewDataSource.h"

#import <objc/runtime.h>

#import <ComponentKit/CKArgumentPrecondition.h>
#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKMacros.h>

#import "CKComponent.h"
#import "CKComponentBoundsAnimation+UICollectionView.h"
#import "CKComponentConstantDecider.h"
#import "CKComponentDataSource.h"
#import "CKComponentDataSourceDelegate.h"
#import "CKComponentDataSourceOutputItem.h"
#import "CKCollectionViewDataSourceCell.h"
#import "CKComponentLifecycleManager.h"
#import "CKComponentRootView.h"
#import "CKComponentScopeRoot.h"

using namespace CK::ArrayController;

@interface CKCollectionViewDataSource () <
UICollectionViewDataSource,
CKComponentDataSourceDelegate
>
@end

@implementation CKCollectionViewDataSource
{
  CKComponentDataSource *_componentDataSource;
  CKCellConfigurationFunction _cellConfigurationFunction;
  NSMapTable *_cellToItemMap;
}

CK_FINAL_CLASS([CKCollectionViewDataSource class]);

#pragma mark - Lifecycle

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView
           supplementaryViewDataSource:(id<CKSupplementaryViewDataSource>)supplementaryViewDataSource
                     componentProvider:(Class<CKComponentProvider>)componentProvider
                               context:(id<NSObject>)context
             cellConfigurationFunction:(CKCellConfigurationFunction)cellConfigurationFunction
{
  self = [super init];
  if (self) {
    _componentDataSource = [[CKComponentDataSource alloc] initWithComponentProvider:componentProvider
                                                                            context:context
                                                                            decider:[CKComponentConstantApprovingDecider class]];
    _supplementaryViewDataSource = supplementaryViewDataSource;
    _cellConfigurationFunction = cellConfigurationFunction;
    _componentDataSource.delegate = self;
    _collectionView = collectionView;
    _collectionView.dataSource = self;
    [_collectionView registerClass:[CKCollectionViewDataSourceCell class] forCellWithReuseIdentifier:kReuseIdentifier];
    _cellToItemMap = [NSMapTable weakToStrongObjectsMapTable];
  }
  return self;
}

- (instancetype)init
{
  CK_NOT_DESIGNATED_INITIALIZER();
}

- (void)dealloc
{
    _collectionView.dataSource = nil;
}

#pragma mark - Changesets

- (void)enqueueChangeset:(const CKArrayControllerInputChangeset &)changeset constrainedSize:(const CKSizeRange &)constrainedSize
{
  [_componentDataSource enqueueChangeset:changeset constrainedSize:constrainedSize];
}

- (void)updateContextAndEnqueueReload:(id)newContext
{
  CKAssertMainThread();
  [_componentDataSource updateContextAndEnqueueReload:newContext];
}

- (id<NSObject>)modelForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return [[_componentDataSource objectAtIndexPath:indexPath] model];
}

- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return [[[_componentDataSource objectAtIndexPath:indexPath] lifecycleManager] size];
}

#pragma mark - Appearance announcement

- (void)announceWillAppearForItemInCell:(UICollectionViewCell *)cell
{
  _sendAppearanceEventForCell(cell, CKComponentAnnouncedEventTreeWillAppear, _cellToItemMap);
}

- (void)announceDidDisappearForItemInCell:(UICollectionViewCell *)cell
{
  // We cannot use the indexPath directly, on deletion the indexPath of the deleted cell cannot be used to
  // get an item from the datasource.
  _sendAppearanceEventForCell(cell, CKComponentAnnouncedEventTreeDidDisappear, _cellToItemMap);
}

NS_INLINE void _sendAppearanceEventForCell(UICollectionViewCell *cell, CKComponentAnnouncedEvent event, NSMapTable *cellToItemMap)
{
  [[[[cellToItemMap objectForKey:cell] lifecycleManager] scopeRoot] announceEventToControllers:event];
}

#pragma mark - UICollectionViewDataSource

static NSString *const kReuseIdentifier = @"com.component_kit.collection_view_data_source.cell";

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  CKComponentDataSourceOutputItem *outputItem = [_componentDataSource objectAtIndexPath:indexPath];
  CKCollectionViewDataSourceCell *cell = [_collectionView dequeueReusableCellWithReuseIdentifier:kReuseIdentifier forIndexPath:indexPath];
  if (_cellConfigurationFunction) {
    _cellConfigurationFunction(cell, indexPath, [outputItem model]);
  }
  CKComponentLifecycleManager *lifecycleManager = [outputItem lifecycleManager];
  [lifecycleManager attachToView:[cell rootView]];
  // We maintain this map to be able to announce appearance events.
  [_cellToItemMap setObject:outputItem forKey:cell];
  return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
  return [_componentDataSource numberOfSections];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  return [_componentDataSource numberOfObjectsInSection:section];
}

#pragma mark - Supplementary views datasource

/** `collectionView:viewForSupplementaryElementOfKind:atIndexPath:` is manually forwarded to an optional supplementaryTableViewDataSource. */
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath
{
  return [_supplementaryViewDataSource collectionView:collectionView
                    viewForSupplementaryElementOfKind:kind
                                          atIndexPath:indexPath];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
  if (aSelector == @selector(collectionView:viewForSupplementaryElementOfKind:atIndexPath:)) {
    // In our protocol `collectionView:viewForSupplementaryElementOfKind:atIndexPath:` is required so we can just check for the
    // presence of the _supplementaryViewDataSource.
    return _supplementaryViewDataSource != nil;
  }
  return [super respondsToSelector:aSelector];
}

#pragma mark - CKComponentDatasourceDelegate

- (void)componentDataSource:(CKComponentDataSource *)componentDataSource
          hasChangesOfTypes:(CKComponentDataSourceChangeType)changeTypes
        changesetApplicator:(ck_changeset_applicator_t)changesetApplicator
{
  [_collectionView performBatchUpdates:^{
    const auto &changeset = changesetApplicator();
    applyChangesetToCollectionView(changeset, _collectionView);
  } completion:nil];
}

- (void)componentDataSource:(CKComponentDataSource *)componentDataSource
     didChangeSizeForObject:(CKComponentDataSourceOutputItem *)object
                atIndexPath:(NSIndexPath *)indexPath
                  animation:(const CKComponentBoundsAnimation &)animation
{
  if (animation.duration != 0 && [[_collectionView indexPathsForVisibleItems] containsObject:indexPath]) {
    id boundsAnimationContext = CKComponentBoundsAnimationPrepareForCollectionViewBatchUpdates(_collectionView);
    [UIView performWithoutAnimation:^{ [_collectionView performBatchUpdates:^{} completion:^(BOOL finished) {}]; }];
    CKComponentBoundsAnimationApplyAfterCollectionViewBatchUpdates(boundsAnimationContext, animation);
  } else {
    [[_collectionView collectionViewLayout] invalidateLayout];
  }
}

#pragma mark - Private

static void applyChangesetToCollectionView(const Output::Changeset &changeset, UICollectionView *collectionView)
{
  NSMutableArray *itemRemovalIndexPaths = [[NSMutableArray alloc] init];
  NSMutableArray *itemInsertionIndexPaths = [[NSMutableArray alloc] init];
  NSMutableArray *itemUpdateIndexPaths = [[NSMutableArray alloc] init];
  Output::Items::Enumerator itemEnumerator =
  ^(const Output::Change &change, CKArrayControllerChangeType type, BOOL *stop) {
    switch (type) {
      case CKArrayControllerChangeTypeDelete:
        [itemRemovalIndexPaths addObject:change.sourceIndexPath.toNSIndexPath()];
        break;
      case CKArrayControllerChangeTypeInsert:
        [itemInsertionIndexPaths addObject:change.destinationIndexPath.toNSIndexPath()];
        break;
      case CKArrayControllerChangeTypeUpdate:
        [itemUpdateIndexPaths addObject:change.sourceIndexPath.toNSIndexPath()];
        break;
      case CKArrayControllerChangeTypeMove:
        [collectionView moveItemAtIndexPath:change.sourceIndexPath.toNSIndexPath() toIndexPath:change.destinationIndexPath.toNSIndexPath()];
        break;
      default:
        CKCFailAssert(@"Unsupported change type for items: %d", type);
        break;
    }
  };
  
  Sections::Enumerator sectionsEnumerator = ^(NSIndexSet *sourceIndexes, NSIndexSet *destinationIndexes, CKArrayControllerChangeType type, BOOL *stop) {
    if (sourceIndexes.count > 0 || destinationIndexes.count > 0) {
      switch (type) {
        case CKArrayControllerChangeTypeDelete:
          [collectionView deleteSections:sourceIndexes];
          break;
        case CKArrayControllerChangeTypeInsert:
          [collectionView insertSections:destinationIndexes];
          break;
        case CKArrayControllerChangeTypeMove:
          [collectionView moveSection:sourceIndexes.firstIndex toSection:destinationIndexes.firstIndex];
          break;
        default:
          CKCFailAssert(@"Unsuported change type for sections %d", type);
          break;
      }
    }
  };
  
  changeset.enumerate(sectionsEnumerator, itemEnumerator);
  if (itemRemovalIndexPaths.count > 0) {
    [collectionView deleteItemsAtIndexPaths:itemRemovalIndexPaths];
  }
  if (itemUpdateIndexPaths.count > 0) {
    [collectionView reloadItemsAtIndexPaths:itemUpdateIndexPaths];
  }
  if (itemInsertionIndexPaths.count > 0) {
    [collectionView insertItemsAtIndexPaths:itemInsertionIndexPaths];
  }
}

@end
