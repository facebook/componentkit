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

#if !defined(__cplusplus) && CK_NOT_SWIFT
#error This file must be compiled Obj-C++ or imported from Swift. Objective-C files should have their extension changed to .mm.
#endif

#import <UIKit/UIKit.h>

#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentProtocol.h>
#import <ComponentKit/CKComponentSize.h>
#import <ComponentKit/CKComponentViewConfiguration.h>
#import <ComponentKit/CKMountable.h>

NS_ASSUME_NONNULL_BEGIN

/** A component is an immutable object that specifies how to configure a view, loosely inspired by React. */
@interface CKComponent : NSObject <CKMountable, CKComponentProtocol>

/**
 @param view A struct describing the view for this component. Pass {} to specify that no view should be created.
 @param size A size constraint that should apply to this component. Pass {} to specify no size constraint.

 @example A component that renders a red square:
 [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{100, 100}]
 */
+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view
                       size:(const CKComponentSize &)size;

/**
 While the component is mounted, returns information about the component's manifestation in the view hierarchy.

 If this component creates a view, this method returns the view it created (or recycled) and a frame with origin 0,0
 and size equal to the view's bounds, since the component's size is the view's size.

 If this component does not create a view, returns the view this component is mounted within and the logical frame
 of the component's content. In this case, you should **not** make any assumptions about what class the view is.
 */
- (CKComponentViewContext)viewContext;

/**
 While the component is mounted, returns its next responder. This is the first of:
 - Its component controller, if it has one;
 - Its supercomponent;
 - The view the component is mounted within, if it is the root component.
 */
- (id _Nullable)nextResponder;

@end

#define CK_COMPONENT_INIT_UNAVAILABLE \
+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view \
                       size:(const CKComponentSize &)size NS_UNAVAILABLE

NS_ASSUME_NONNULL_END

#import <ComponentKit/ComponentBuilder.h>

#endif
