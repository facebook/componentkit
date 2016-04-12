/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <Foundation/Foundation.h>

#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKComponentViewConfiguration.h>

@class CKComponent;
@class UIView;

/**
 CKComponentDebugController exposes the functionality needed by the lldb helpers to control the debug behavior for
 components.
 */
@interface CKComponentDebugController : NSObject

+ (BOOL)debugMode;

/**
 Setting the debug mode enables the injection of debug configuration into the component.
 */
+ (void)setDebugMode:(BOOL)debugMode NS_EXTENSION_UNAVAILABLE("Recursively reflows components using -[UIApplication keyWindow]");

/**
 Components are an immutable construct. Whenever we make changes to the parameters on which the components depended,
 the changes won't be reflected in the component hierarchy until we explicitly cause a reflow/update. A reflow
 essentially rebuilds the component hierarchy and mounts it back on the view.

 This is particularly used in reflowing the component hierarchy when we set the debug mode.
 */
+ (void)reflowComponents NS_EXTENSION_UNAVAILABLE("Recursively reflows components using -[UIApplication keyWindow]");

@end

/** Returns an adjusted mount context that inserts a debug view if the viewConfiguration doesn't have a view. */
CK::Component::MountContext CKDebugMountContext(Class componentClass,
                                                const CK::Component::MountContext &context,
                                                const CKComponentViewConfiguration &viewConfiguration,
                                                const CGSize size);
