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

#import "CKCollectionViewDataSourceCell.h"
#import "CKDataSourceConfigurationInternal.h"
#import "CKDataSourceListener.h"
#import "CKDataSourceItem.h"
#import "CKDataSourceState.h"
#import "CKDataSourceAppliedChanges.h"
#import "CKDataSourceInternal.h"
#import "CKCollectionViewDataSourceInternal.h"
#import "CKComponentRootViewInternal.h"
#import "CKComponentLayout.h"
#import "CKComponentAttachController.h"
#import "CKComponentBoundsAnimation+UICollectionView.h"
#import "CKComponentControllerEvents.h"
#import "CKCollectionViewDataSourceListenerAnnouncer.h"

@interface CKCollectionViewDataSource () <UICollectionViewDataSource, CKDataSourceListener>
{
  CKDataSource *_componentDataSource;
  __weak id<CKSupplementaryViewDataSource> _supplementaryViewDataSource;
  CKDataSourceState *_currentState;
  CKComponentAttachController *_attachController;
  NSMapTable<UICollectionViewCell *, CKDataSourceItem *> *_cellToItemMap;
  CKCollectionViewDataSourceListenerAnnouncer *_announcer;
  BOOL _allowTapPassthroughForCells;
}
@end

@implementation CKCollectionViewDataSource
@synthesize supplementaryViewDataSource = _supplementaryViewDataSource;

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView
           supplementaryViewDataSource:(id<CKSupplementaryViewDataSource>)supplementaryViewDataSource
                         configuration:(CKDataSourceConfiguration *)configuration
{
  self = [super init];
  if (self) {
    _componentDataSource = [[CKDataSource alloc] initWithConfiguration:configuration];
    [_componentDataSource addListener:self];

    _collectionView = collectionView;
    _collectionView.dataSource = self;
    [_collectionView registerClass:[CKCollectionViewDataSourceCell class] forCellWithReuseIdentifier:kReuseIdentifier];

    _attachController = [CKComponentAttachController new];
    _supplementaryViewDataSource = supplementaryViewDataSource;
    _cellToItemMap = [NSMapTable weakToStrongObjectsMapTable];
    _announcer = [CKCollectionViewDataSourceListenerAnnouncer new];
  }
  return self;
}

- (CKDataSourceState *)currentState
{
  CKAssertMainThread();
  return _currentState;
}

#pragma mark - Changeset application

- (void)applyChangeset:(CKDataSourceChangeset *)changeset
                  mode:(CKUpdateMode)mode
              userInfo:(NSDictionary *)userInfo
{
  [_componentDataSource applyChangeset:changeset
                                  mode:mode
                              userInfo:userInfo];
}

static void applyChangesToCollectionView(UICollectionView *collectionView,
                                         CKComponentAttachController *attachController,
                                         NSMapTable<UICollectionViewCell *, CKDataSourceItem *> *cellToItemMap,
                                         CKDataSourceState *currentState,
                                         CKDataSourceAppliedChanges *changes)
{
  [changes.updatedIndexPaths enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, BOOL *stop) {
    if (CKCollectionViewDataSourceCell *cell = (CKCollectionViewDataSourceCell *) [collectionView cellForItemAtIndexPath:indexPath]) {
      attachToCell(cell, [currentState objectAtIndexPath:indexPath], attachController, cellToItemMap, YES);
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

#pragma mark - CKDataSourceListener

- (void)dataSource:(CKDataSource *)dataSource
     didModifyPreviousState:(CKDataSourceState *)previousState
                  withState:(CKDataSourceState *)state
          byApplyingChanges:(CKDataSourceAppliedChanges *)changes
{
  [_announcer dataSourceWillBeginUpdates:self];
  const BOOL changesIncludeNonUpdates = (changes.removedIndexPaths.count ||
                                         changes.insertedIndexPaths.count ||
                                         changes.movedIndexPaths.count ||
                                         changes.insertedSections.count ||
                                         changes.removedSections.count);
  const BOOL changesIncludeOnlyUpdates = (changes.updatedIndexPaths.count && !changesIncludeNonUpdates);

  if (changesIncludeOnlyUpdates) {
    // We are not able to animate the updates individually, so we pick the
    // first bounds animation with a non-zero duration.
    CKComponentBoundsAnimation boundsAnimation = {};
    for (NSIndexPath *indexPath in changes.updatedIndexPaths) {
      boundsAnimation = [[state objectAtIndexPath:indexPath] boundsAnimation];
      if (boundsAnimation.duration)
        break;
    }

    void (^applyUpdatedState)(CKDataSourceState *) = ^(CKDataSourceState *updatedState) {
      [_collectionView performBatchUpdates:^{
        _currentState = updatedState;
      } completion:^(BOOL finished) {
        [_announcer dataSourceDidEndUpdates:self didModifyPreviousState:previousState withState:state byApplyingChanges:changes];
      }];
    };

    // We only apply the bounds animation if we found one with a duration.
    // Animating the collection view is an expensive operation and should be
    // avoided when possible.
    if (boundsAnimation.duration) {
      id boundsAnimationContext = CKComponentBoundsAnimationPrepareForCollectionViewBatchUpdates(_collectionView, heightChange(previousState, state, changes.updatedIndexPaths));
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
        CKDataSourceItem *item = [state objectAtIndexPath:indexPath];
        CKCollectionViewDataSourceCell *cell = (CKCollectionViewDataSourceCell *)[_collectionView cellForItemAtIndexPath:indexPath];
        if (cell) {
          attachToCell(cell, item, _attachController, _cellToItemMap, YES);
        }
      }
    }, nil);
  } else if (changesIncludeNonUpdates) {
    [_collectionView performBatchUpdates:^{
      applyChangesToCollectionView(_collectionView, _attachController, _cellToItemMap, state, changes);
      // Detach all the component layouts for items being deleted
      [self _detachComponentLayoutForRemovedItemsAtIndexPaths:[changes removedIndexPaths]
                                                      inState:previousState];
      [self _detachComponentLayoutForRemovedSections:[changes removedSections]
                                                      inState:previousState];
      // Update current state
      _currentState = state;
    } completion:^(BOOL finished){
      [_announcer dataSourceDidEndUpdates:self didModifyPreviousState:previousState withState:state byApplyingChanges:changes];
    }];
  }
}

static auto heightChange(CKDataSourceState *previousState, CKDataSourceState *state, NSSet *updatedIndexPaths) -> CGFloat
{
  auto change = 0.0;
  for (NSIndexPath *indexPath in updatedIndexPaths) {
    auto const oldHeight = [previousState objectAtIndexPath:indexPath].rootLayout.size().height;
    auto const newHeight = [state objectAtIndexPath:indexPath].rootLayout.size().height;
    change += (newHeight - oldHeight);
  }
  return change;
}

- (void)dataSource:(CKDataSource *)dataSource
 willApplyDeferredChangeset:(CKDataSourceChangeset *)deferredChangeset {}

- (void)_detachComponentLayoutForRemovedItemsAtIndexPaths:(NSSet *)removedIndexPaths
                                                  inState:(CKDataSourceState *)state
{
  for (NSIndexPath *indexPath in removedIndexPaths) {
    CKComponentScopeRootIdentifier identifier = [[[state objectAtIndexPath:indexPath] scopeRoot] globalIdentifier];
    [_attachController detachComponentLayoutWithScopeIdentifier:identifier];
  }
}

- (void)_detachComponentLayoutForRemovedSections:(NSIndexSet *)removedSections inState:(CKDataSourceState *)state
{
  [removedSections enumerateIndexesUsingBlock:^(NSUInteger section, BOOL *stop) {
    [state enumerateObjectsInSectionAtIndex:section
                                 usingBlock:^(CKDataSourceItem *item, NSIndexPath *indexPath, BOOL *stop2) {
      [_attachController detachComponentLayoutWithScopeIdentifier:[[item scopeRoot] globalIdentifier]];
    }];
  }];
}

#pragma mark - State

- (id<NSObject>)modelForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return [_currentState objectAtIndexPath:indexPath].model;
}

- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return [_currentState objectAtIndexPath:indexPath].rootLayout.size();
}

#pragma mark - Reload

- (void)reloadWithMode:(CKUpdateMode)mode
              userInfo:(NSDictionary *)userInfo
{
  [_componentDataSource reloadWithMode:mode userInfo:userInfo];
}

- (void)updateConfiguration:(CKDataSourceConfiguration *)configuration
                       mode:(CKUpdateMode)mode
                   userInfo:(NSDictionary *)userInfo
{
  [_componentDataSource updateConfiguration:configuration mode:mode userInfo:userInfo];
}

#pragma mark - Appearance announcements

- (void)announceWillDisplayCell:(UICollectionViewCell *)cell
{
  CKComponentScopeRootAnnounceControllerAppearance([_cellToItemMap objectForKey:cell].scopeRoot);
}

- (void)announceDidEndDisplayingCell:(UICollectionViewCell *)cell
{
  CKComponentScopeRootAnnounceControllerDisappearance([_cellToItemMap objectForKey:cell].scopeRoot);
}

#pragma mark - UICollectionViewDataSource

static NSString *const kReuseIdentifier = @"com.component_kit.collection_view_data_source.cell";

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  CKCollectionViewDataSourceCell *cell = [_collectionView dequeueReusableCellWithReuseIdentifier:kReuseIdentifier forIndexPath:indexPath];
  [cell.rootView setAllowTapPassthrough:_allowTapPassthroughForCells];
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
                         CKDataSourceItem *item,
                         CKComponentAttachController *attachController,
                         NSMapTable<UICollectionViewCell *, CKDataSourceItem *> *cellToItemMap,
                         BOOL isUpdate = NO)
{
  CKComponentAttachControllerAttachComponentRootLayout(
      attachController,
      {.layoutProvider = item,
       .scopeIdentifier = item.scopeRoot.globalIdentifier,
       .boundsAnimation = item.boundsAnimation,
       .view = cell.rootView,
       .analyticsListener = item.scopeRoot.analyticsListener,
       .isUpdate = isUpdate});
  [cellToItemMap setObject:item forKey:cell];
}

#pragma mark - Internal

- (void)setAllowTapPassthroughForCells:(BOOL)allowTapPassthroughForCells
{
  CKAssertMainThread();
  _allowTapPassthroughForCells = allowTapPassthroughForCells;
}

- (void)setState:(CKDataSourceState *)state
{
  CKAssertMainThread();
  if (_currentState == state) {
    return;
  }

  auto const previousState = _currentState;
  [_announcer dataSource:self willChangeState:previousState];
  _currentState = state;

  [_attachController detachAll];
  [_componentDataSource removeListener:self];
  _componentDataSource = [[CKDataSource alloc] initWithState:state];
  [_componentDataSource addListener:self];
  [_collectionView reloadData];
  [_announcer dataSource:self didChangeState:previousState withState:state];
}

- (void)addListener:(id<CKCollectionViewDataSourceListener>)listener
{
  [_announcer addListener:listener];
}

- (void)removeListener:(id<CKCollectionViewDataSourceListener>)listener
{
  [_announcer removeListener:listener];
}

@end
