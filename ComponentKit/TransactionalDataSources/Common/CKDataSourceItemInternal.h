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

#import <ComponentKit/CKDataSourceItem.h>

/** Internal interface since this class is usually only created internally. */
@interface CKDataSourceItem ()

- (instancetype)initWithRootLayout:(const CKComponentRootLayout &)rootLayout
                             model:(id)model
                         scopeRoot:(CKComponentScopeRoot *)scopeRoot
                   boundsAnimation:(CKComponentBoundsAnimation)boundsAnimation;

/**
 Internal interface for items which are manually going to manage the creation
 of their root layout.
 */
- (instancetype)initWithModel:(id)model
                    scopeRoot:(CKComponentScopeRoot *)scopeRoot;

@end

#endif
