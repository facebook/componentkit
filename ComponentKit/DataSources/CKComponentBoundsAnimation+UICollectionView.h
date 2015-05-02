/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <UIKit/UIKit.h>

#import <ComponentKit/CKComponentBoundsAnimation.h>

/**
 UICollectionView's builtin animations are quite limited:
 - You cannot customize the duration or delay.
 - You cannot use a spring animation.
 - Cells that were offscreen before the change and onscreen afterwards snap directly into place without animation.

 This function provides a way to perform custom animations for UICollectionView, with the following restrictions:
 - You **must not** call this function if the update includes inserts, deletes, or moves.
   In those cases, you must rely on UICollectionView's built-in animations.
 - It can only apply a single CKComponentBoundsAnimation. If there are multiple simultaneous updates with differing
   animations, you must choose only one.
 - It may not be well-suited to complex collection view layouts.

 If you're implementing a collection view data source, call this function just before you call
 [UICollectionView -performBatchUpdates:completion:] wrapped with [UIView +performWithoutAnimation:]. For example:

   id context = CKComponentBoundsAnimationPrepareForCollectionViewBatchUpdates(collectionView);
   [UIView performWithoutAnimation:^{ [collectionView performBatchUpdates:^{} completion:nil]; }];
   CKComponentBoundsAnimationApplyAfterCollectionViewBatchUpdates(context, boundsAnimation);

 @see CKCollectionViewDataSource for a sample implementation.

 @return A context that may be passed to CKComponentBoundsAnimationApplyAfterBatchUpdates. Calling it is optional;
 for example, if you determine that the update has no animation, or that all index paths to be animated are offscreen,
 you can skip calling CKComponentBoundsAnimationApplyAfterBatchUpdates entirely.
 */
id CKComponentBoundsAnimationPrepareForCollectionViewBatchUpdates(UICollectionView *cv);

/** @see CKComponentBoundsAnimationPrepareForCollectionViewBatchUpdates */
void CKComponentBoundsAnimationApplyAfterCollectionViewBatchUpdates(id context, const CKComponentBoundsAnimation &animation);
