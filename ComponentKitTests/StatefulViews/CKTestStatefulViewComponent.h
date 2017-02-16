/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKStatefulViewComponent.h>
#import <ComponentKit/CKStatefulViewComponentController.h>

@interface CKTestStatefulViewComponent : CKStatefulViewComponent
+ (instancetype)newWithColor:(UIColor *)color;
@end

@interface CKTestStatefulView : UIView
@end

@interface CKTestStatefulViewComponentController : CKStatefulViewComponentController<CKTestStatefulViewComponent *, CKTestStatefulView *, id>
@end
