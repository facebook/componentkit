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

#import <ComponentKit/CKInspectableView.h>
#import <ComponentKit/CKComponentScopeEnumeratorProvider.h>

/**
 A common interface shared by views that host component hierarches.
 */
@protocol CKComponentHostingViewProtocol <CKInspectableView>

/** Returns the current scope enumerator provider. Main thread only. */
- (id<CKComponentScopeEnumeratorProvider>)scopeEnumeratorProvider;

@end

#endif
