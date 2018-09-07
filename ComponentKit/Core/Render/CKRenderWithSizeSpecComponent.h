/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKRenderComponentProtocol.h>

/*
 *  CKRenderWithSizeSpecComponent
 */

@interface CKRenderWithSizeSpecComponent : CKComponent <CKRenderComponentProtocol>

/*
 * If you subclass from CKRenderWithSizeSpecComponent, you need to override - render:constrainedSize:restrictedToSize:relativeToParentSize: or
 * - render:constrainedSize: .
 *
 * You should also call - measureChild:constrainedSize:relativeToParentSize: for every children that it's returned in the layout
 *
 * If you don't need a custom layout, you can just use CKFlexboxComponent instead.
 *
 * @param state The current state of the component.
 * @param constrainedSize Specifies a minimum and maximum size. The receiver must choose a size that is in this range.
 * @param size The size specified during component creation.
 * @param parentSize The parent component's size. If the parent component does not have a final size in a given dimension,
 *                   then it should be passed as kCKComponentParentDimensionUndefined (for example, if the parent's width
 *                   depends on the child's size).
 *
 * @returns The component layout calculated
 */

- (CKComponentLayout)render:(id)state
            constrainedSize:(CKSizeRange)constrainedSize
           restrictedToSize:(const CKComponentSize &)size
       relativeToParentSize:(CGSize)parentSize;
/*
 *
 * @param state The current state of the component.
 * @param constrainedSize Specifies a minimum and maximum size. The receiver must choose a size that is in this range.
 *
 * @returns The component layout calculated
 */

- (CKComponentLayout)render:(id)state
            constrainedSize:(CKSizeRange)constrainedSize;

/*
 * This method should be called on every child component that will be present in the layout.
 *
 * @param child The component to compute the layout for.
 * @param constrainedSize The size range to compute the component layout within.
 * @param parentSize The parent size of the component to compute the layout for.
 *
 * @returns The child component layout
 */

- (CKComponentLayout)measureChild:(CKComponent *)child
                  constrainedSize:(CKSizeRange)constrainedSize
             relativeToParentSize:(CGSize)parentSize;

@end

