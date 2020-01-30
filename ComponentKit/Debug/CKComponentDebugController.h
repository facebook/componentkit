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

#import <Foundation/Foundation.h>

#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKComponentViewConfiguration.h>

@class CKComponent;

@protocol CKComponentDebugReflowListener
- (void)didReceiveReflowComponentsRequest;
- (void)didReceiveReflowComponentsRequestWithTreeNodeIdentifier:(CKTreeNodeIdentifier)treeNodeIdentifier;
@end

/**
 CKComponentDebugController exposes the functionality needed by the lldb helpers to control the debug behavior for
 components.
 */
@interface CKComponentDebugController : NSObject

+ (BOOL)debugMode;

/**
 Setting the debug mode enables the injection of debug configuration into the component.
 */
+ (void)setDebugMode:(BOOL)debugMode;

/**
 Components are an immutable construct. Whenever we make changes to the parameters on which the components depended,
 the changes won't be reflected in the component hierarchy until we explicitly cause a reflow/update. A reflow
 essentially rebuilds the component hierarchy and remounts on the attached view, if any.

 This is automatically triggered when changing debug mode, to ensure that debug views are added or removed.
 */
+ (void)reflowComponents;

/**
 Only reflow component tree that contains the tree node identifier.
 */
+ (void)reflowComponentsWithTreeNodeIdentifier:(CKTreeNodeIdentifier)treeNodeIdentifier;

/**
 Registers an object that will be notified when +reflowComponents is called. The listener is weakly held and will
 be messaged on the main thread.
 */
+ (void)registerReflowListener:(id<CKComponentDebugReflowListener>)listener;

@end

/** Returns an adjusted mount context that inserts a debug view if the viewConfiguration doesn't have a view. */
CK::Component::MountContext CKDebugMountContext(Class componentClass,
                                                const CK::Component::MountContext &context,
                                                const CKComponentViewConfiguration &viewConfiguration,
                                                const CGSize size);

#endif
