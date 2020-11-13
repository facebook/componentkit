/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKDefines.h>
#import <ComponentKit/CKComponent.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(EmptyComponent)
@interface CKEmptyComponent : CKComponent
@property (strong, nonatomic, readonly, class) CKComponent *sharedInstance NS_SWIFT_NAME(shared);
@end

NS_ASSUME_NONNULL_END
