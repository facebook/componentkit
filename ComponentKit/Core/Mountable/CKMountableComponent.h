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

#import <ComponentKit/CKComponentSize.h>
#import <ComponentKit/CKMountable.h>

@interface CKMountableComponent : NSObject <CKMountable>

/**
 @param view A struct describing the view for this component. Pass {} to specify that no view should be created.
 @param size A size constraint that should apply to this component. Pass {} to specify no size constraint.

 @example A component that renders a red square:
 [CKMountableComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{100, 100}]
*/
+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view
                       size:(const CKComponentSize &)size;

/** Get the component size, can be empty */
- (CKComponentSize)size;

/** Can be set only during the component creation and only if there is no size already. */
- (void)setSize:(const CKComponentSize &)size;

/** Can be called only during the component creation and only if there is no existing view configuration already. */
- (void)setViewConfiguration:(const CKComponentViewConfiguration &)viewConfiguration;

@end
