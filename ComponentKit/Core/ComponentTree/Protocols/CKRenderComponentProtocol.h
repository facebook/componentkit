/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKTreeNodeProtocol.h>

/**
 This protocol is being implemented by the components that has a render method: `CKRenderComponent` and `CKRenderWithChildrenComponent`.

 Please DO NOT implement a new component that conforms to this protocol;
 your component should subclass either from `CKRenderComponent` or `CKRenderWithChildrenComponent`.
 */
@protocol CKRenderComponentProtocol <CKTreeNodeComponentProtocol>

/*
 Override this method in order to provide an initialState which depends on the component's props.
 Otherwise, override `+(id)initialState` instead.
 */
+ (id)initialStateWithComponent:(id<CKRenderComponentProtocol>)component;

/*
 Override this method in order to allow ComopnentKit to reuse the previous components.

 You can always assume that the `component` parameter is the same type as your component.

 The default value is `YES`.
 */
- (BOOL)shouldComponentUpdate:(id<CKRenderComponentProtocol>)component;

/*
 This method is being called when the infrasturcture reuses the previous generation of the component.

 When a previous component is being reused, the render method WON'T be called on the new generation of the component.
 If your render method is not a pure function (for example, it saves components as iVar), you can use this method
 in order to update the new component from the reused one.
 */
- (void)didReuseComponent:(id<CKRenderComponentProtocol>)component;

/**
 Override this method in order to assign a unique identifier to a component.

 The default identifier of a component would be its class and an integer which represent the order it was built.
 However, if you reorder/add/removed sibling components from the same type/class (as a result of a state/props update),
 you need to assign them a uniqute identifier. Otherwise, the infrastrcture cannot distingiush between them after the change.

       +-----+                                  +-----+
       |     |                                  |     |
       |  A  |                                  |  A  |
       |     |                                  |     |
       +-----+             ------->             +-----+
 +-----+      +-----+                     +-----+      +-----+
 |     |      |     |                     |     |      |     |
 | B1  |      |  B2 |                     | B2  |      |  B1 |
 |     |      |     |                     |     |      |     |
 +-----+      +-----+                     +-----+      +-----+

 In this case, the infrastrcture cannot distinguish between B1 and B2, unless it provides a unqiue identifier.
 */
- (id<NSObject>)componentIdentifier;
@end


/**
 Render component with a single child.
 */
@protocol CKRenderWithChildComponentProtocol <CKRenderComponentProtocol>

/**
 Returns a child component that needs to be rendered from this component.

 @param state The current state of the component.
 */
- (id<CKTreeNodeComponentProtocol>)render:(id)state;

@end

/**
 Render component with multi child.
 */
@protocol CKRenderWithChildrenComponentProtocol <CKRenderComponentProtocol>

/*
 Returns a vector of 'CKComponent' children that will be rendered to the screen.

 @param state The current state of the component.
 */
- (std::vector<id<CKTreeNodeComponentProtocol>>)renderChildren:(id)state;

@end
