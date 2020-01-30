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

#if CK_NOT_SWIFT

#import <Foundation/Foundation.h>

@protocol CKComponentProtocol;

@protocol CKComponentControllerProtocol <NSObject>

- (instancetype)initWithComponent:(id<CKComponentProtocol>)component;

@property (nonatomic, weak, readonly) id<CKComponentProtocol> component;

@end

#endif
