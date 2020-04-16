/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

NS_ASSUME_NONNULL_BEGIN

/**
 This protocol is being implemented by multiple components inc. but not limited to: `CKRenderComponent`.

 Please DO NOT implement a new component that conforms to this protocol;
 your component should subclass either from `CKRenderComponent`.
 */
NS_SWIFT_NAME(ReusableComponentProtocol)
@protocol CKReusableComponentProtocol <NSObject>

/*
 Override this method in order to allow ComopnentKit to reuse the previous components.

 You can always assume that the `component` parameter is the same type as your component.

 The default value is `YES`.
 */
- (BOOL)shouldComponentUpdate:(id<CKReusableComponentProtocol>)component;

/*
 This method is being called when the infrasturcture reuses the previous generation of the component.

 When a previous component is being reused, the render method WON'T be called on the new generation of the component.
 If your render method is not a pure function (for example, it saves components as iVar), you can use this method
 in order to update the new component from the reused one.
 */
- (void)didReuseComponent:(id<CKReusableComponentProtocol>)component;

/**
 Creates a new instance of render component with props from the current instance.
 */
- (instancetype)clone;

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
@property (nonatomic, strong, readonly, nullable) id componentIdentifier;

@end

NS_ASSUME_NONNULL_END
