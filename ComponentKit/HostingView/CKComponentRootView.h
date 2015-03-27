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

/**
 A common root view used by CKComponentHostingView and CKCollectionViewDataSource.
 If implementing your own data source you are not required to use this root view, but you may wish to.
 */
@interface CKComponentRootView : UIView
@end
