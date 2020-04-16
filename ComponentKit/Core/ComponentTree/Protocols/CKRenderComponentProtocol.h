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
#import <ComponentKit/CKTreeNodeProtocol.h>
#import <ComponentKit/CKReusableComponentProtocol.h>

NS_ASSUME_NONNULL_BEGIN

/**
 This protocol is being implemented by the components that has a render method: `CKRenderComponent`.

 Please DO NOT implement a new component that conforms to this protocol;
 your component should subclass either from `CKRenderComponent`.
 */
NS_SWIFT_NAME(RenderComponentProtocol)
@protocol CKRenderComponentProtocol <CKTreeNodeComponentProtocol, CKReusableComponentProtocol>

/*
 Override this method in order to provide an initialState which depends on the component's props.
 Otherwise, override `+(id)initialState` instead.
 */
- (id _Nullable)initialState;

/** Returns true if the component requires scope handle */
@property (nonatomic, assign, readonly) BOOL requiresScopeHandle;

@end

/**
 Render component with a single child.
 */
NS_SWIFT_NAME(RenderWithChildComponentProtocol)
@protocol CKRenderWithChildComponentProtocol <CKRenderComponentProtocol>

/**
 Returns a child component that needs to be rendered from this component.

 @param state The current state of the component.
 */
- (id<CKTreeNodeComponentProtocol> _Nullable)render:(id _Nullable)state;

/**
 Returns the computed child component, if there is one.
 */
@property (nonatomic, strong, readonly, nullable) id<CKTreeNodeComponentProtocol> child;

@end

NS_ASSUME_NONNULL_END
