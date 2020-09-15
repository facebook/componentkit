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

#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKDataSourceItem.h>
#import <ComponentKit/CKDataSourceConfiguration.h>
#import <ComponentKit/CKNonNull.h>
#import <ComponentKit/CKSizeRange.h>
#import <ComponentKit/CKBuildTrigger.h>

CKDataSourceItem *CKBuildDataSourceItem(CK::NonNull<CKComponentScopeRoot *> previousRoot,
                                        const CKComponentStateUpdateMap &stateUpdates,
                                        const CKSizeRange &sizeRange,
                                        CKDataSourceConfiguration *configuration,
                                        id model,
                                        id context,
                                        CKReflowTrigger reflowTrigger = CKReflowTriggerNone);

#endif
