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

 By using this components, the infrastructure makes sure that the component tree (CKTreeNode) is being built for the children components.
 (If you use other base classes such as CKCompositeComponent, that part is being take care of by the infrastructure already).

 The main difference between CKRenderComponent and CKRenderLayoutWithChildrenComponent is that by subclassing CKRenderLayoutWithChildrenComponent the component tree (CKTreeNode)
 won't be created from CKBuildComponent unless there is a CKRenderComponent in the tree. We use this component to bridge non-render components into the render world.
 */
@interface CKRenderLayoutWithChildrenComponent : CKComponent <CKRenderWithChildrenComponentProtocol>

/*
 Returns a vector of 'CKComponent' children that will be rendered to the screen.

 If you override this method, you must override the `computeLayoutThatFits:` and provide a layout for these components.
 If you don't need a custom layout, you can just use CKFlexboxComponent instead.

 @param state The current state of the component.
 */
- (std::vector<CKComponent *>)renderChildren:(id)state;

@end
