/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKCollectionViewTransactionalDataSource.h"

#import "CKCollectionViewDataSourceCell.h"
#import "CKTransactionalComponentDataSourceConfiguration.h"
#import "CKTransactionalComponentDataSourceListener.h"
#import "CKTransactionalComponentDataSourceItem.h"
#import "CKTransactionalComponentDataSourceState.h"
#import "CKTransactionalComponentDataSourceAppliedChanges.h"
#import "CKComponentRootView.h"
#import "CKComponentLayout.h"
#import "CKComponentDataSourceAttachController.h"
#import "CKComponentBoundsAnimation+UICollectionView.h"

@interface CKCollectionViewTransactionalDataSource () <
UICollectionViewDataSource,
CKTransactionalComponentDataSourceListener
>
{
  CKTransactionalComponentDataSource *_componentDataSource;
  __weak id<CKSupplementaryViewDataSource> _supplementaryViewDataSource;
  CKTransactionalComponentDataSourceState *_currentState;
  CKComponentDataSourceAttachController *_attachController;
  NSMapTable<UICollectionViewCell *, CKTransactionalComponentDataSourceItem *> *_cellToItemMap;
  NSMutableSet<CKTransactionalComponentDataSourceItem *> *_visibleItems;
}
@end

@implementation CKCollectionViewTransactionalDataSource
@synthesize supplementaryViewDataSource = _supplementaryViewDataSource;

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView
           supplementaryViewDataSource:(id<CKSupplementaryViewDataSource>)supplementaryViewDataSource
                         configuration:(CKTransactionalComponentDataSourceConfiguration *)configuration
{
  self = [super init];
  if (self) {
    _componentDataSource = [[CKTransactionalComponentDataSource alloc] initWithConfiguration:configuration];
    [_componentDataSource addListener:self];
      
    _collectionView = collectionView;
    _collectionView.dataSource = self;
    [_collectionView registerClass:[CKCollectionViewDataSourceCell class] forCellWithReuseIdentifier:kReuseIdentifier];
    
    _attachController = [[CKComponentDataSourceAttachController alloc] init];
    _supplementaryViewDataSource = supplementaryViewDataSource;
    _cellToItemMap = [NSMapTable weakToStrongObjectsMapTable];
    _visibleItems = [NSMutableSet set];
  }
  return self;
}

#pragma mark - Changeset application

- (void)applyChangeset:(CKTransactionalComponentDataSourceChangeset *)changeset
                  mode:(CKUpdateMode)mode
              userInfo:(NSDictionary *)userInfo
{
  [_componentDataSource applyChangeset:changeset
                                  mode:mode
                              userInfo:userInfo];
}

static void applyChangesToCollectionView(UICollectionView *collectionView,
                                         CKComponentDataSourceAttachController *attachController,
                                         NSMapTable<UICollectionViewCell *, CKTransactionalComponentDataSourceItem *> *cellToItemMap,
                                         CKTransactionalComponentDataSourceState *currentState,
                                         CKTransactionalComponentDataSourceAppliedChanges *changes)
{
  [changes.updatedIndexPaths enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, BOOL *stop) {
    if (CKCollectionViewDataSourceCell *cell = (CKCollectionViewDataSourceCell *) [collectionView cellForItemAtIndexPath:indexPath]) {
      attachToCell(cell, [currentState objectAtIndexPath:indexPath], attachController, cellToItemMap);
    }
  }];
  [collectionView deleteItemsAtIndexPaths:[changes.removedIndexPaths allObjects]];
  [collectionView deleteSections:changes.removedSections];
  for (NSIndexPath *from in changes.movedIndexPaths) {
    NSIndexPath *to = changes.movedIndexPaths[from];
    [collectionView moveItemAtIndexPath:from toIndexPath:to];
  }
  [collectionView insertSections:changes.insertedSections];
  [collectionView insertItemsAtIndexPaths:[changes.insertedIndexPaths allObjects]];
}

#pragma mark - CKTransactionalComponentDataSourceListener

- (void)transactionalComponentDataSource:(CKTransactionalComponentDataSource *)dataSource
                  didModifyPreviousState:(CKTransactionalComponentDataSourceState *)previousState
                       byApplyingChanges:(CKTransactionalComponentDataSourceAppliedChanges *)changes
{
  const BOOL changesIncludeNonUpdates = (changes.removedIndexPaths.count ||
                                         changes.insertedIndexPaths.count ||
                                         changes.movedIndexPaths.count ||
                                         changes.insertedSections.count ||
                                         changes.removedSections.count);
  const BOOL changesIncludeOnlyUpdates = (changes.updatedIndexPaths.count && !changesIncludeNonUpdates);
  
  CKTransactionalComponentDataSourceState *state = [_componentDataSource state];
  
  if (changesIncludeOnlyUpdates) {
    // We are not able to animate the updates individually, so we pick the
    // first bounds animation with a non-zero duration.
    CKComponentBoundsAnimation boundsAnimation = {};
    for (NSIndexPath *indexPath in changes.updatedIndexPaths) {
      boundsAnimation = [[state objectAtIndexPath:indexPath] boundsAnimation];
      if (boundsAnimation.duration)
        break;
    }
    
    void (^applyUpdatedState)(CKTransactionalComponentDataSourceState *) = ^(CKTransactionalComponentDataSourceState *updatedState) {
      [_collectionView performBatchUpdates:^{
        _currentState = updatedState;
      } completion:^(BOOL finished) {}];
    };

    // We only apply the bounds animation if we found one with a duration.
    // Animating the collection view is an expensive operation and should be
    // avoided when possible.
    if (boundsAnimation.duration) {
      id boundsAnimationContext = CKComponentBoundsAnimationPrepareForCollectionViewBatchUpdates(_collectionView);
      [UIView performWithoutAnimation:^{
        applyUpdatedState(state);
      }];
      CKComponentBoundsAnimationApplyAfterCollectionViewBatchUpdates(boundsAnimationContext, boundsAnimation);
    } else {
      applyUpdatedState(state);
    }
    
    // Within an animation block we directly attach the updated items to
    // their respective cells if visible.
    CKComponentBoundsAnimationApply(boundsAnimation, ^{
      for (NSIndexPath *indexPath in changes.updatedIndexPaths) {
        CKTransactionalComponentDataSourceItem *item = [state objectAtIndexPath:indexPath];
        CKCollectionViewDataSourceCell *cell = (CKCollectionViewDataSourceCell *)[_collectionView cellForItemAtIndexPath:indexPath];
        if (cell) {
          attachToCell(cell, item, _attachController, _cellToItemMap);
        }
      }
    }, nil);
  } else if (changesIncludeNonUpdates) {
    [_collectionView performBatchUpdates:^{
      applyChangesToCollectionView(_collectionView, _attachController, _cellToItemMap, state, changes);
      // Detach all the component layouts for items being deleted
      [self _detachComponentLayoutForRemovedItemsAtIndexPaths:[changes removedIndexPaths]
                                                      inState:previousState];
      // Update current state
      _currentState = state;
    } completion:NULL];
  }
}

- (void)_detachComponentLayoutForRemovedItemsAtIndexPaths:(NSSet *)removedIndexPaths
                                                  inState:(CKTransactionalComponentDataSourceState *)state
{
  for (NSIndexPath *indexPath in removedIndexPaths) {
    CKComponentScopeRootIdentifier identifier = [[[state objectAtIndexPath:indexPath] scopeRoot] globalIdentifier];
    [_attachController detachComponentLayoutWithScopeIdentifier:identifier];
  }
}

#pragma mark - State

- (id<NSObject>)modelForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return [_currentState objectAtIndexPath:indexPath].model;
}

- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return [_currentState objectAtIndexPath:indexPath].layout.size;
}

#pragma mark - Reload

- (void)reloadWithMode:(CKUpdateMode)mode
              userInfo:(NSDictionary *)userInfo
{
  [_componentDataSource reloadWithMode:mode userInfo:userInfo];
}

- (void)updateConfiguration:(CKTransactionalComponentDataSourceConfiguration *)configuration
                       mode:(CKUpdateMode)mode
                   userInfo:(NSDictionary *)userInfo
{
  [_componentDataSource updateConfiguration:configuration mode:mode userInfo:userInfo];
}

#pragma mark - Appearance announcements

- (void)announceWillDisplayCell:(UICollectionViewCell *)cell
{
  CKTransactionalComponentDataSourceItem *item = [_cellToItemMap objectForKey:cell];
  [item.scopeRoot announceEventToControllers:CKComponentAnnouncedEventTreeWillAppear];
  [_visibleItems addObject:item];
}

- (void)announceDidEndDisplayingCell:(UICollectionViewCell *)cell
{
  CKTransactionalComponentDataSourceItem *item = [_cellToItemMap objectForKey:cell];
  [item.scopeRoot announceEventToControllers:CKComponentAnnouncedEventTreeDidDisappear];
  [_visibleItems removeObject:item];
}

- (void)announceScrollEventToVisibleCells
{
  for (CKTransactionalComponentDataSourceItem *item in _visibleItems) {
    [item.scopeRoot announceEventToControllers:CKComponentAnnouncedEventScrollViewDidScroll];
  }
}

#pragma mark - UICollectionViewDataSource

static NSString *const kReuseIdentifier = @"com.component_kit.collection_view_data_source.cell";

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  CKCollectionViewDataSourceCell *cell = [_collectionView dequeueReusableCellWithReuseIdentifier:kReuseIdentifier forIndexPath:indexPath];
  attachToCell(cell, [_currentState objectAtIndexPath:indexPath], _attachController, _cellToItemMap);
  return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
  return [_supplementaryViewDataSource collectionView:collectionView viewForSupplementaryElementOfKind:kind atIndexPath:indexPath];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
  return _currentState ? [_currentState numberOfSections] : 0;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  return _currentState ? [_currentState numberOfObjectsInSection:section] : 0;
}

static void attachToCell(CKCollectionViewDataSourceCell *cell,
                         CKTransactionalComponentDataSourceItem *item,
                         CKComponentDataSourceAttachController *attachController,
                         NSMapTable<UICollectionViewCell *, CKTransactionalComponentDataSourceItem *> *cellToItemMap)
{
  [attachController attachComponentLayout:item.layout withScopeIdentifier:item.scopeRoot.globalIdentifier withBoundsAnimation:item.boundsAnimation toView:cell.rootView];
  [cellToItemMap setObject:item forKey:cell];
}

@end
