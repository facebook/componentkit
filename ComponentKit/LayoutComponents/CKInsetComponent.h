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

#import <ComponentKit/CKLayoutComponent.h>

NS_ASSUME_NONNULL_BEGIN

/**
 @uidocs https://fburl.com/CKInsetComponent:ac83

 A component that wraps another component, applying insets around it.

 If the child component has a size specified as a percentage, the percentage is resolved against this component's parent
 size **after** applying insets.

 @note
 CKOuterComponent contains an CKInsetComponent with an CKInnerComponent. Suppose that:
 - CKOuterComponent is 200pt wide.
 - CKInnerComponent specifies its width as 100%.
 - The CKInsetComponent has insets of 10pt on every side.
 CKInnerComponent will have size 180pt, not 200pt, because it receives a parent size that has been adjusted for insets.

 If you're familiar with CSS: CKInsetComponent's child behaves similarly to "box-sizing: border-box".

 An infinite inset is resolved as an inset equal to all remaining space after applying the other insets and child size.
 @note
 An CKInsetComponent with an infinite left inset and 10px for all other edges will position it's child 10px from the right edge.
 */
NS_SWIFT_NAME(InsetComponent)
@interface CKInsetComponent : CKLayoutComponent

CK_INIT_UNAVAILABLE;

CK_LAYOUT_COMPONENT_INIT_UNAVAILABLE;

#if CK_SWIFT

/**
 @param swiftView Passed to CKComponent -initWithView:size:. The view, if any, will extend outside the insets.
 @param insets The amount of space to inset on each side.
 @param component The wrapped child component to inset. If nil, this method returns nil.
 */
- (instancetype)initWithSwiftView:(CKComponentViewConfiguration_SwiftBridge *_Nullable)swiftView
                              top:(CKDimension_SwiftBridge *)top
                             left:(CKDimension_SwiftBridge *)left
                           bottom:(CKDimension_SwiftBridge *)bottom
                            right:(CKDimension_SwiftBridge *)right
                        component:(CKComponent *_Nullable)component NS_DESIGNATED_INITIALIZER;

#else

/**
 @param view Passed to CKComponent +newWithView:size:. The view, if any, will extend outside the insets.
 @param insets The amount of space to inset on each side.
 @param component The wrapped child component to inset. If nil, this method returns nil.
 */
- (instancetype)initWithView:(const CKComponentViewConfiguration &)view
                         top:(CKRelativeDimension)top
                        left:(CKRelativeDimension)left
                      bottom:(CKRelativeDimension)bottom
                       right:(CKRelativeDimension)right
                   component:(CKComponent *_Nullable)component NS_DESIGNATED_INITIALIZER;

/**
 @param insets The amount of space to inset on each side.
 @param component The wrapped child component to inset. If nil, this method returns nil.
 */
- (instancetype)initWithTop:(CKRelativeDimension)top
                       left:(CKRelativeDimension)left
                     bottom:(CKRelativeDimension)bottom
                      right:(CKRelativeDimension)right
                  component:(CKComponent *_Nullable)component;

#endif

@end

NS_ASSUME_NONNULL_END

#import <ComponentKit/InsetComponentBuilder.h>
