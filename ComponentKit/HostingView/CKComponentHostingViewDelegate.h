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

@class UIView;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ComponentHostingViewDelegate)
@protocol CKComponentHostingViewDelegate <NSObject>
@required
/**
 Called after the hosting view updates the component view to a new size.

 The delegate can use this callback to appropriately resize the view frame to fit the new
 component size. The view will not resize itself.
 */
- (void)componentHostingViewDidInvalidateSize:(UIView *)hostingView;
@end

NS_ASSUME_NONNULL_END
