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
#import <ComponentKit/CKRenderComponentProtocol.h>

/**
 This component should be used as the base class of non-leaf components with a custom layout (instead of CKComponent).

 By using this components, the infrastructure makes sure that the component tree (CKTreeNode) is being built for the child component of this component.
 (If you use other base classes such as CKCompositeComponent, that part is being take care of by the infrastructure already).

 The main difference between CKRenderComponent and CKRenderLayoutComponent is that by subclassing CKRenderLayoutComponent the component tree (CKTreeNode)
 won't be created from CKBuildComponent unless there is a CKRenderComponent in the tree. We use this component to bridge non-render components into the render world.
 */
@interface CKRenderLayoutComponent : CKComponent <CKRenderWithChildComponentProtocol>

/**
 Returns a child component that needs to be rendered from this component.

 @param state The current state of the component.
 */
- (CKComponent *)render:(id)state;

@end
