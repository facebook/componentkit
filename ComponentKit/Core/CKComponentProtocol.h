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
#import <ComponentKit/CKDefines.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CKComponentControllerProtocol;

NS_SWIFT_NAME(ComponentProtocol)
@protocol CKComponentProtocol <NSObject>

@property (nonatomic, copy, readonly) NSString *className;
@property (nonatomic, strong, readonly, class, nullable) id initialState;
@property (nonatomic, strong, readonly, class, nullable) Class<CKComponentControllerProtocol> controllerClass;

/*
 * For internal use only. Please do not use this. Will soon be deprecated.
 * Overriding this API has undefined behvaiour.
 */
- (id<CKComponentControllerProtocol>)buildController;

@end

NS_ASSUME_NONNULL_END
