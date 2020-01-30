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

#import <ComponentKit/CKCategorizable.h>
#import <ComponentKit/CKComponentBoundsAnimation.h>
#import <ComponentKit/CKComponentRootLayoutProvider.h>

struct CKComponentRootLayout;
@class CKComponentScopeRoot;

@interface CKDataSourceItem : NSObject <CKComponentRootLayoutProvider, CKCategorizable>

/** The model used to compute the layout */
@property (nonatomic, strong, readonly) id model;

/** The scope root for this item, which holds references to component controllers and state */
@property (nonatomic, strong, readonly) CKComponentScopeRoot *scopeRoot;

/** The bounds animation with which to apply the layout */
@property (nonatomic, readonly) CKComponentBoundsAnimation boundsAnimation;

@end

#endif
