/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <Foundation/Foundation.h>

@class UICollectionReusableView;
@class UICollectionView;

/**
 The supplementaryViewDataSource can't just conform to @see UICollectionViewDataSource as this protocol includes required
 methods that are already implemented by this class. Hence we duplicate the part of the protocol related to supplementary views
 and wrap it in our internal one.
 */
@protocol CKSupplementaryViewDataSource<NSObject>

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath;

@end
