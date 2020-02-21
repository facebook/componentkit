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
#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKRenderComponentProtocol.h>

NS_ASSUME_NONNULL_BEGIN

/*
@warning Overriding -layoutThatFits:parentSize: or -computeLayoutThatFits: is **not allowed** for any subclass.
*/

@interface CKRenderComponent : CKComponent <CKRenderWithChildComponentProtocol>

/**
 Returns a child component that needs to be rendered from this component.

 @param state The current state of the component.
 */
- (CKComponent * _Nullable)render:(id _Nullable)state;

#if CK_NOT_SWIFT

/**
 Returns view configuration for the component.

 This method is optional - it can be used in case the view configuration is based on a state.
 View configuration: A struct describing the view for this component.

 @param state The current state of the component.
 */
- (CKComponentViewConfiguration)viewConfigurationWithState:(id)state;

#endif

@end

#if CK_SWIFT
#define CK_RENDER_COMPONENT_INIT_UNAVAILABLE \
  - (instancetype)init NS_UNAVAILABLE;
#else
#define CK_RENDER_COMPONENT_INIT_UNAVAILABLE \
  + (instancetype)new NS_UNAVAILABLE;
#endif

NS_ASSUME_NONNULL_END
