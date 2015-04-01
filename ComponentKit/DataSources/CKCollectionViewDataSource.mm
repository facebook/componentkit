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
#import "CKComponentDataSourceOutputItem.h"
#import "CKCollectionViewDataSourceCell.h"
#import "CKComponentLifecycleManager.h"
#import "CKComponentRootView.h"

using namespace CK::ArrayController;

@interface CKCollectionViewDataSource () <
UICollectionViewDataSource,
UICollectionViewDelegate,
CKComponentDataSourceDelegate
>
@end

/** 
 This helper object is used to regulate the application of changesets to the collection view
 In rare cases, if a performBatchUpdates that mutates the structure of the collection view is executed while the previous one is not done, it will mess up 
 the internal state of the collection view and cause items not to be updated properly. 
 For this reason instead of applying directly changes to the collection view as soon as the componentDataSource is done computing them, we enqueue the 
 changesets in this "regulator" that will apply them serially.
 */
@interface CKCollectionViewDataSourceChangesetRegulator: NSObject

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView;
/** 
 Enqueue a changeset in the regulator, the changeset is either :
 - Applied immediately if nothing is enqueued in front of it
 - Defered until all of the changesets in front in the queue are performed
 */
- (void)enqueueChangesetApplicator:(ck_changeset_applicator_t)changesetApplicator;

@end

@implementation CKCollectionViewDataSource
{
  CKComponentDataSource *_componentDataSource;
  CKCellConfigurationFunction _cellConfigurationFunction;
  CKCollectionViewDataSourceChangesetRegulator *_changesetRegulator;
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
                                                                            decider:[[CKComponentConstantDecider alloc] initWithEnabled:YES]];
    _supplementaryViewDataSource = supplementaryViewDataSource;
    _cellConfigurationFunction = cellConfigurationFunction;
    _componentDataSource.delegate = self;
    _collectionView = collectionView;
    _collectionView.dataSource = self;
    [_collectionView registerClass:[CKCollectionViewDataSourceCell class] forCellWithReuseIdentifier:kReuseIdentifier];
    _changesetRegulator = [[CKCollectionViewDataSourceChangesetRegulator alloc] initWithCollectionView:collectionView];
  }
  return self;
}

- (instancetype)init
{
  CK_NOT_DESIGNATED_INITIALIZER();
}

#pragma mark - Changesets

- (void)enqueueChangeset:(const CKArrayControllerInputChangeset &)changeset constrainedSize:(const CKSizeRange &)constrainedSize
{
  [_componentDataSource enqueueChangeset:changeset constrainedSize:constrainedSize];
}

- (void)updateContextAndEnqeueReload:(id)newContext
{
  CKAssertMainThread();
  [_componentDataSource updateContextAndEnqeueReload:newContext];
}

- (id<NSObject>)modelForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return [[_componentDataSource objectAtIndexPath:indexPath] model];
}

- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return [[[_componentDataSource objectAtIndexPath:indexPath] lifecycleManager] size];
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
  [_changesetRegulator enqueueChangesetApplicator:changesetApplicator];
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

@end

@implementation CKCollectionViewDataSourceChangesetRegulator {
  UICollectionView *_collectionView;
  // Internal queue for the changeset applicators
  NSMutableArray *_changesetQueue;
  BOOL _processingChangeset;
}

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView
{
  if (self = [super init]) {
    _collectionView = collectionView;
    _changesetQueue = [NSMutableArray array];
  }
  return self;
}

- (void)enqueueChangesetApplicator:(ck_changeset_applicator_t)changesetApplicator
{
  [_changesetQueue addObject:changesetApplicator];
  [self applyNextChangeset];
}

- (void)applyNextChangeset {
  if (!_processingChangeset && [_changesetQueue count]) {
    ck_changeset_applicator_t headChangeset = _changesetQueue[0];
    [_changesetQueue removeObjectAtIndex:0];
    [_collectionView performBatchUpdates:^{
      _processingChangeset = YES;
      const auto &changeset = headChangeset();
      applyChangesetToCollectionView(changeset, _collectionView);
    } completion:^(BOOL){
      _processingChangeset = NO;
      [self applyNextChangeset];
    }];
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
    NSIndexPath *indexPath = change.indexPath.toNSIndexPath();
    switch (type) {
      case CKArrayControllerChangeTypeDelete:
        [itemRemovalIndexPaths addObject:indexPath];
        break;
      case CKArrayControllerChangeTypeInsert:
        [itemInsertionIndexPaths addObject:indexPath];
        break;
      case CKArrayControllerChangeTypeUpdate:
        [itemUpdateIndexPaths addObject:indexPath];
        break;
      default:
        CKCFailAssert(@"Unsupported change type for items: %d", type);
        break;
    }
  };
  
  Sections::Enumerator sectionsEnumerator = ^(NSIndexSet *sectionIndexes, CKArrayControllerChangeType type, BOOL *stop) {
    if (sectionIndexes.count > 0) {
      switch (type) {
        case CKArrayControllerChangeTypeDelete:
          [collectionView deleteSections:sectionIndexes];
          break;
        case CKArrayControllerChangeTypeInsert:
          [collectionView insertSections:sectionIndexes];
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
