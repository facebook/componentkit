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
  NSDictionary *_supplementaryElementIndexPathsToSnapshotViews;
  NSDictionary *_indexPathsToOriginalLayoutAttributes;
  NSDictionary *_supplementaryElementIndexPathsToOriginalLayoutAttributes;
}

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView
{
  if (self = [super init]) {
    _collectionView = collectionView;
    _numberOfSections = [collectionView numberOfSections];
    for (NSInteger i = 0; i < _numberOfSections; i++) {
      _numberOfItemsInSection.push_back([collectionView numberOfItemsInSection:i]);
    }

    // We might need to use a snapshot view to animate cells that are going offscreen, but we don't know which ones yet.
    // Grab a snapshot view for every cell; they'll be used or discarded in -applyBoundsAnimationToCollectionView:.

    const CGSize visibleSize = collectionView.bounds.size;
    const CGRect visibleRect = { collectionView.contentOffset, visibleSize };

    // Obviously we want to animate all visible cells. But what about cells that were not previously visible, but become
    // visible as a result of an item becoming smaller? We grab the layout attributes of a few more items that are
    // offscreen so that we can animate them too. (Only some, though; we don't attempt to get *all* layout attributes.)

    const CGFloat offscreenHeight = visibleSize.height / 2;
    const CGRect extendedRect = { visibleRect.origin, { visibleSize.width, visibleSize.height + offscreenHeight } };

    NSMutableDictionary *indexPathsToSnapshotViews = [NSMutableDictionary dictionary];
    NSMutableDictionary *indexPathsToOriginalLayoutAttributes = [NSMutableDictionary dictionary];
    NSMutableDictionary *supplementaryElementIndexPathsToSnapshotViews = [NSMutableDictionary dictionary];
    NSMutableDictionary *supplementaryElementIndexPathsToOriginalLayoutAttributes = [NSMutableDictionary dictionary];
    for (UICollectionViewLayoutAttributes  *attributes in [collectionView.collectionViewLayout layoutAttributesForElementsInRect:extendedRect]) {
      NSIndexPath * const indexPath = attributes.indexPath;
      switch (attributes.representedElementCategory) {
        case UICollectionElementCategoryCell: {
          indexPathsToOriginalLayoutAttributes[indexPath] = attributes;
          if (CGRectIntersectsRect(attributes.frame, visibleRect)) {
            UIView *snapshotView = [[collectionView cellForItemAtIndexPath:indexPath] snapshotViewAfterScreenUpdates:NO];
            if (snapshotView) {
              indexPathsToSnapshotViews[indexPath] = snapshotView;
            }
          }
          break;
        }
        case UICollectionElementCategorySupplementaryView: {
          supplementaryElementIndexPathsToOriginalLayoutAttributes[indexPath] = attributes;
          if (CGRectIntersectsRect(attributes.frame, visibleRect)) {
            UIView *snapshotView =
            [[collectionView supplementaryViewForElementKind:attributes.representedElementKind atIndexPath:indexPath] snapshotViewAfterScreenUpdates:NO];
            if (snapshotView) {
              supplementaryElementIndexPathsToSnapshotViews[indexPath] = snapshotView;
            }
          }
          break;
        }
        case UICollectionElementCategoryDecorationView: {
          break;
        }
      }
    }
    _indexPathsToSnapshotViews = indexPathsToSnapshotViews;
    _indexPathsToOriginalLayoutAttributes = indexPathsToOriginalLayoutAttributes;
    _supplementaryElementIndexPathsToSnapshotViews = supplementaryElementIndexPathsToSnapshotViews;
    _supplementaryElementIndexPathsToOriginalLayoutAttributes = supplementaryElementIndexPathsToOriginalLayoutAttributes;
  }
  return self;
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
  NSMutableDictionary *indexPathsToAnimatingSupplementaryViews = [NSMutableDictionary dictionary];
  NSMutableDictionary *indexPathsToSupplementaryElementKinds = [NSMutableDictionary dictionary];
  NSMutableArray *snapshotViewsToRemoveAfterAnimation = [NSMutableArray array];
  const CGRect visibleRect = {.origin = [_collectionView contentOffset], .size = [_collectionView bounds].size};
  NSIndexPath *largestAnimatingVisibleElement = largestAnimatingVisibleElementForOriginalLayout(_indexPathsToOriginalLayoutAttributes, visibleRect);
  [UIView performWithoutAnimation:^{
    [_indexPathsToOriginalLayoutAttributes enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath, UICollectionViewLayoutAttributes *attributes, BOOL *stop) {
      // If we're animating an item *out* of the collection view's visible bounds, we can't rely on animating a
      // UICollectionViewCell. Confusingly enough there will be a cell at the exact moment this function is called,
      // but the UICollectionView will reclaim and hide it at the end of the run loop turn. Use a snapshot view instead.
      // Also, the largest animating visible element will be retained inside the visible bounds so don't use a snapshot view.
      if (CGRectIntersectsRect(visibleRect, [[_collectionView layoutAttributesForItemAtIndexPath:indexPath] frame]) || [indexPath isEqual:largestAnimatingVisibleElement]) {
        UICollectionViewCell *cell = [_collectionView cellForItemAtIndexPath:indexPath];
        if (cell) {
          // Surprisingly -applyLayoutAttributes: does not apply bounds or center; that's deeper magic.
          [cell setBounds:attributes.bounds];
          [cell setCenter:attributes.center];
          indexPathsToAnimatingViews[indexPath] = cell;
        }
      } else {
        UIView *snapshotView = _indexPathsToSnapshotViews[indexPath];
        if (snapshotView) {
          [snapshotView setBounds:attributes.bounds];
          [snapshotView setCenter:attributes.center];
          [_collectionView addSubview:snapshotView];
          indexPathsToAnimatingViews[indexPath] = snapshotView;
          [snapshotViewsToRemoveAfterAnimation addObject:snapshotView];
        }
      }
    }];
    [_supplementaryElementIndexPathsToOriginalLayoutAttributes enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath, UICollectionViewLayoutAttributes *attributes, BOOL *stop) {
      if (CGRectIntersectsRect(visibleRect, [[_collectionView layoutAttributesForSupplementaryElementOfKind:attributes.representedElementKind atIndexPath:indexPath] frame])) {
        UICollectionReusableView *supplementaryView = [_collectionView supplementaryViewForElementKind:attributes.representedElementKind atIndexPath:indexPath];
        if (supplementaryView) {
          [supplementaryView setBounds:attributes.bounds];
          [supplementaryView setCenter:attributes.center];
          indexPathsToAnimatingSupplementaryViews[indexPath] = supplementaryView;
          indexPathsToSupplementaryElementKinds[indexPath] = attributes.representedElementKind;
        }
      } else {
        UIView *snapshotView = _supplementaryElementIndexPathsToSnapshotViews[indexPath];
        if (snapshotView) {
          [snapshotView setBounds:attributes.bounds];
          [snapshotView setCenter:attributes.center];
          [_collectionView addSubview:snapshotView];
          indexPathsToAnimatingSupplementaryViews[indexPath] = snapshotView;
          indexPathsToSupplementaryElementKinds[indexPath] = attributes.representedElementKind;
          [snapshotViewsToRemoveAfterAnimation addObject:snapshotView];
        }
      }
    }];
  }];

  // The smallest adjustment we have to make the content-offset to keep the largest visible element from being animated off-screen. When the largest element suddenly disappears the user
  // loses context and the result is jarring.
  CGPoint contentOffsetAdjustment = contentOffsetAdjustmentToKeepElementInVisibleBounds(largestAnimatingVisibleElement, indexPathsToAnimatingViews, _collectionView, visibleRect);

  // Then move them back to their current positions with animation:
  void (^restore)(void) = ^{
    [indexPathsToAnimatingViews enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath, UIView *view, BOOL *stop) {
      UICollectionViewLayoutAttributes *attributes = [_collectionView layoutAttributesForItemAtIndexPath:indexPath];
      [view setBounds:attributes.bounds];
      [view setCenter:attributes.center];
    }];
    [indexPathsToAnimatingSupplementaryViews enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath, UIView *view, BOOL *stop) {
      UICollectionViewLayoutAttributes *attributes =
      [_collectionView layoutAttributesForSupplementaryElementOfKind:indexPathsToSupplementaryElementKinds[indexPath] atIndexPath:indexPath];
      [view setBounds:attributes.bounds];
      [view setCenter:attributes.center];
    }];
    [_collectionView setContentOffset:CGPointMake(_collectionView.contentOffset.x + contentOffsetAdjustment.x, _collectionView.contentOffset.y + contentOffsetAdjustment.y)];
  };
  void (^completion)(BOOL) = ^(BOOL finished){
    for (UIView *v in snapshotViewsToRemoveAfterAnimation) {
      [v removeFromSuperview];
    }
  };
  CKComponentBoundsAnimationApply(animation, restore, completion);

  _collectionView = nil;
  _indexPathsToSnapshotViews = nil;
  _supplementaryElementIndexPathsToSnapshotViews = nil;
  _indexPathsToOriginalLayoutAttributes = nil;
  _supplementaryElementIndexPathsToOriginalLayoutAttributes = nil;
}

#pragma mark - Maintain context during bounds animation

// @abstract Returns the minimum content offset adjustment that would keep the largest visible element in the collection view in the viewport post-animation.
// @param largestVisibleAnimatingElementIndexPath The index path of the largest visible element that will be animated for the bounds animation.
// @param indexPathsToAnimationViews A dictionary that maps index paths of the animating elements of the collection view, to their view.
// @param collectionView The collection view the bounds change animation is being applied to.
// @param visibleRect The visible portion of the collection-view's contents.
// @return The minimum content offset to set on the collection-view that will keep the largest visible element still visible.
static CGPoint contentOffsetAdjustmentToKeepElementInVisibleBounds(NSIndexPath *largestVisibleAnimatingElementIndexPath, NSDictionary *indexPathsToAnimatingViews, UICollectionView *collectionView, CGRect visibleRect)
{
  CGPoint contentOffsetAdjustment = CGPointZero;
  BOOL largestVisibleElementWillExitVisibleRect = elementWillExitVisibleRect(largestVisibleAnimatingElementIndexPath, indexPathsToAnimatingViews, collectionView, visibleRect);

  if (largestVisibleElementWillExitVisibleRect) {
    CGRect currentBounds = ((UIView *)indexPathsToAnimatingViews[largestVisibleAnimatingElementIndexPath]).bounds;
    CGRect destinationBounds = ((UICollectionViewLayoutAttributes *) [collectionView layoutAttributesForItemAtIndexPath:largestVisibleAnimatingElementIndexPath]).bounds;

    CGFloat deltaX = CGRectGetMaxX(destinationBounds) - CGRectGetMaxX(currentBounds);
    CGFloat deltaY = CGRectGetMaxY(destinationBounds) - CGRectGetMaxY(currentBounds);

    contentOffsetAdjustment = CGPointMake(deltaX, deltaY);
  }
  return contentOffsetAdjustment;
}

// @abstract Returns the index-path of largest element in the collection, inside the collection views visible bounds, as returned by the collection view's layout attributes.
// @param indexPathToOriginalLayoutAttributes A dictionary mapping the indexpath of elements to their collection view layout attributes.
// @param visibleRect  The visible portion of the collection-view's contents.
static NSIndexPath* largestAnimatingVisibleElementForOriginalLayout(NSDictionary *indexPathToOriginalLayoutAttributes, CGRect visibleRect) {
  __block CGRect largestSoFar = CGRectZero;
  __block NSIndexPath *prominentElementIndexPath = nil;
  [indexPathToOriginalLayoutAttributes enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath, UICollectionViewLayoutAttributes *attributes, BOOL *stop) {
    CGRect intersection = CGRectIntersection(visibleRect, attributes.frame);
    if (_CGRectArea(intersection) > _CGRectArea(largestSoFar)) {
      largestSoFar = intersection;
      prominentElementIndexPath = indexPath;
    }
  }];
  return prominentElementIndexPath;
}

// Returns YES if the element is current visible, but will not be visible (will be animated off-screen) post animation.
static BOOL elementWillExitVisibleRect(NSIndexPath *indexPath, NSDictionary *indexPathsToAnimatingViews, UICollectionView *collectionView, CGRect visibleRect)
{
  UIView *animatingView = indexPathsToAnimatingViews[indexPath];
  UICollectionViewLayoutAttributes *attributes = [collectionView layoutAttributesForItemAtIndexPath:indexPath];

  BOOL isItemCurrentlyInVisibleRect = (CGRectIntersectsRect(visibleRect,animatingView.frame));
  BOOL willItemAnimateOffVisibleRect = !CGRectIntersectsRect(visibleRect, attributes.frame);

  if (isItemCurrentlyInVisibleRect && willItemAnimateOffVisibleRect) {
    return YES;
  }
  return NO;
}

static CGFloat _CGRectArea(CGRect rect)
{
  return CGRectGetWidth(rect) * CGRectGetHeight(rect);
}

@end
