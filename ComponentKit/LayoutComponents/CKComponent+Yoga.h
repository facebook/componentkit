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

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKCompositeComponent.h>
#import <ComponentKit/CKLinkable.h>

#import "yoga/Yoga.h"

YGConfigRef _Nonnull ckYogaDefaultConfig();

/**
 A protocol that is used for the components that are powered by Yoga layout engine
 (https://github.com/facebook/yoga).
 */
@protocol CKYogaBasedComponentProtocol <NSObject>

/**
 A flag that represents whether the component's layout is based on Yoga.

 The default value is NO
 */
- (BOOL)isYogaBasedLayout;

/**
 CKComponentSize of yoga node of the component. For CKComponent it is just it's size
 that is passed in the constructor. For wrapper components, like CKCompositeComponent
 it's the node size of it's child component
 */
- (CKComponentSize)nodeSize;

/**
 A method that returns a new yoga node for a constained size.

 By default returns a Yoga node with default configuration
 */
- (YGNodeRef _Nonnull)ygNode:(CKSizeRange)constrainedSize;

/**
 A method to create a component layout instance from the given node and constrained size.

 By default returns an empty layout
 */
- (CKComponentLayout)layoutFromYgNode:(YGNodeRef _Nonnull)layoutNode thatFits:(CKSizeRange)constrainedSize;

/**
 A flag that represents whether the component's layout sets a custom baseline value using the key
 [kCKComponentLayoutExtraBaselineKey] or not

 The default value is NO
 */
- (BOOL)usesCustomBaseline;
@end

CK_LINK_REQUIRE_CATEGORY(CKComponent_Yoga)
@interface CKComponent (Yoga) <CKYogaBasedComponentProtocol>
@end

CK_LINK_REQUIRE_CATEGORY(CKCompositeComponent_Yoga)
@interface CKCompositeComponent (Yoga)
@end

#endif
