/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <vector>

#import <UIKit/UIKit.h>

@class CKComponent;

@interface UIView (CKComponent)

/** Strong reference back to the associated component while the component is mounted. */
@property (nonatomic, strong, setter=ck_setComponent:) CKComponent *ck_component;

@end
