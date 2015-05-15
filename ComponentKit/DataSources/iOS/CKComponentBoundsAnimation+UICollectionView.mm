/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentBoundsAnimation+UICollectionView.h"

#import <vector>

@interface CKComponentBoundsAnimationCollectionViewContext : NSObject
- (instancetype)initWithCollectionView:(UICollectionView *)cv;
- (void)applyBoundsAnimationToCollectionView:(const CKComponentBoundsAnimation &)animation;
@end

id CKComponentBoundsAnimationPrepareForCollectionViewBatchUpdates(UICollectionView *cv)
{
  return [[CKComponentBoundsAnimationCollectionViewContext alloc] initWithCollectionView:cv];
}

void CKComponentBoundsAnimationApplyAfterCollectionViewBatchUpdates(id context, const CKComponentBoundsAnimation &animation)
{
  [(CKComponentBoundsAnimationCollectionViewContext *)context applyBoundsAnimationToCollectionView:animation];
}

@implementation CKComponentBoundsAnimationCollectionViewContext
{
  UICollectionView *_collectionView;
  NSInteger _numberOfSections;
  std::vector<NSUInteger> _numberOfItemsInSection;
  NSDictionary *_indexPathsToSnapshotViews;
  NSDictionary *_indexPathsToOriginalLayoutAttributes;
}

- (instancetype)initWithCollectionView:(UICollectionView *)cv
{
  if (self = [super init]) {
    _collectionView = cv;
    _numberOfSections = [cv numberOfSections];
    for (NSInteger i = 0; i < _numberOfSections; i++) {
      _numberOfItemsInSection.push_back([cv numberOfItemsInSection:i]);
    }

    // We might need to use a snapshot view to animate cells that are going offscreen, but we don't know which ones yet.
    // Grab a snapshot view for every cell; they'll be used or discarded in -applyBoundsAnimationToCollectionView:.
    NSMutableDictionary *sv = [NSMutableDictionary dictionary];
    for (NSIndexPath *ip in [cv indexPathsForVisibleItems]) {
      UIView *snapshotView = [[cv cellForItemAtIndexPath:ip] snapshotViewAfterScreenUpdates:NO];
      if (snapshotView) {
        sv[ip] = snapshotView;
      }
    }
    _indexPathsToSnapshotViews = sv;

    NSMutableDictionary *la = [NSMutableDictionary dictionary];
    for (NSIndexPath *ip in visibleAndJustOffscreenIndexPaths(cv)) {
      la[ip] = [_collectionView layoutAttributesForItemAtIndexPath:ip];
    }
    _indexPathsToOriginalLayoutAttributes = la;
  }
  return self;
}

static NSArray *visibleAndJustOffscreenIndexPaths(UICollectionView *cv)
{
  NSArray *sortedIndexPaths = [[cv indexPathsForVisibleItems] sortedArrayUsingSelector:@selector(compare:)];
  if ([sortedIndexPaths count] == 0) {
    return sortedIndexPaths;
  }

  // Obviously we want to animate all visible cells. But what about cells that were not previously visible, but become
  // visible as a result of an item becoming smaller? We grab the layout attributes of a few more items that are
  // offscreen so that we can animate them too. (Only some, though; we don't attempt to get *all* layout attributes.)

  NSIndexPath *previousIndexPath = [sortedIndexPaths lastObject];
  static const NSUInteger kOffscreenIndexPathCount = 10;
  NSMutableArray *offscreenIndexPaths = [NSMutableArray array];
  while ([offscreenIndexPaths count] < kOffscreenIndexPathCount) {
    if ([previousIndexPath item] == [cv numberOfItemsInSection:[previousIndexPath section]] - 1) {
      NSUInteger nextSection = [previousIndexPath section] + 1;
      while (nextSection < [cv numberOfSections] && [cv numberOfItemsInSection:nextSection] == 0) {
        nextSection++;
      }
      if (nextSection == [cv numberOfSections]) {
        break; // No more rows to animate.
      }
      previousIndexPath = [NSIndexPath indexPathForItem:0 inSection:nextSection];
    } else {
      previousIndexPath = [NSIndexPath indexPathForItem:[previousIndexPath item] + 1 inSection:[previousIndexPath section]];
    }
    [offscreenIndexPaths addObject:previousIndexPath];
  }

  return [sortedIndexPaths arrayByAddingObjectsFromArray:offscreenIndexPaths];
}

- (void)applyBoundsAnimationToCollectionView:(const CKComponentBoundsAnimation &)animation
{
  if (animation.duration == 0) {
    return;
  }
  // The documentation states that you must not use these functions with inserts or deletes. Let's be safe:
  if ([_collectionView numberOfSections] != _numberOfSections) {
    return;
  }
  for (NSInteger i = 0; i < _numberOfSections; i++) {
    if (_numberOfItemsInSection.at(i) != [_collectionView numberOfItemsInSection:i]) {
      return;
    }
  }

  // First, move the cells to their old positions without animation:
  NSMutableDictionary *indexPathsToAnimatingViews = [NSMutableDictionary dictionary];
  NSMutableArray *snapshotViewsToRemoveAfterAnimation = [NSMutableArray array];
  [UIView performWithoutAnimation:^{
    const CGRect visibleRect = {.origin = [_collectionView contentOffset], .size = [_collectionView bounds].size};
    [_indexPathsToOriginalLayoutAttributes enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *ip, UICollectionViewLayoutAttributes *attrs, BOOL *stop) {
      // If we're animating an item *out* of the collection view's visible bounds, we can't rely on animating a
      // UICollectionViewCell. Confusingly enough there will be a cell at the exact moment this function is called,
      // but the UICollectionView will reclaim and hide it at the end of the run loop turn. Use a snapshot view instead.
      if (CGRectIntersectsRect(visibleRect, [[_collectionView layoutAttributesForItemAtIndexPath:ip] frame])) {
        UICollectionViewCell *cell = [_collectionView cellForItemAtIndexPath:ip];
        if (cell) {
          // Surprisingly -applyLayoutAttributes: does not apply bounds or center; that's deeper magic.
          [cell setBounds:attrs.bounds];
          [cell setCenter:attrs.center];
          indexPathsToAnimatingViews[ip] = cell;
        }
      } else {
        UIView *snapshotView = _indexPathsToSnapshotViews[ip];
        if (snapshotView) {
          [snapshotView setBounds:attrs.bounds];
          [snapshotView setCenter:attrs.center];
          [_collectionView addSubview:snapshotView];
          indexPathsToAnimatingViews[ip] = snapshotView;
          [snapshotViewsToRemoveAfterAnimation addObject:snapshotView];
        }
      }
    }];
  }];

  // Then move them back to their current positions with animation:
  void (^restore)(void) = ^{
    [indexPathsToAnimatingViews enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *ip, UIView *view, BOOL *stop) {
      UICollectionViewLayoutAttributes *attrs = [_collectionView layoutAttributesForItemAtIndexPath:ip];
      [view setBounds:attrs.bounds];
      [view setCenter:attrs.center];
    }];
  };
  void (^completion)(BOOL) = ^(BOOL finished){
    for (UIView *v in snapshotViewsToRemoveAfterAnimation) {
      [v removeFromSuperview];
    }
  };
  CKComponentBoundsAnimationApply(animation, restore, completion);

  _collectionView = nil;
  _indexPathsToSnapshotViews = nil;
  _indexPathsToOriginalLayoutAttributes = nil;
}

@end
