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

#import <ComponentKit/CKDefines.h>
#import <ComponentKit/CKNonNull.h>

@class CKComponentRootView;

@interface CKCollectionViewDataSourceCell : UICollectionViewCell
#if CK_NOT_SWIFT
@property (nonatomic, assign, readonly) CK::NonNull<CKComponentRootView *> rootView;
#endif
@end
