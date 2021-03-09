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
#import <ComponentKit/CKDefines.h>
#import <ComponentKit/CKSizeRange.h>
#import <ComponentKit/CKSystraceListener.h>
#import <RenderCore/RCLayout.h>

#if CK_NOT_SWIFT

NS_ASSUME_NONNULL_BEGIN

void CKComponentWillLayout(CKComponent *component, CKSizeRange constrainedSize, CGSize parentSize, id<CKSystraceListener> systraceListener);
void CKComponentDidLayout(CKComponent *component, const RCLayout &layout, CKSizeRange constrainedSize, CGSize parentSize, id<CKSystraceListener> systraceListener);

NS_ASSUME_NONNULL_END

#endif
