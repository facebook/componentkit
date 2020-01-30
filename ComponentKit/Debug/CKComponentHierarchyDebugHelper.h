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

#import <ComponentKit/CKComponentViewConfiguration.h>

@class CKComponent;
@class CKComponentRootView;
@class UIView;

struct CKComponentLayout;

/**
 CKComponentHierarchyDebugHelper allows
 */
@interface CKComponentHierarchyDebugHelper : NSObject
/**
 Describe the component hierarchy starting from the window. This recursively searches downwards in the view hierarchy to
 find views which have a lifecycle manager, from which we can get the component layout hierarchies.
 @return A string with a description of the hierarchy.
 */
+ (NSString *)componentHierarchyDescription NS_EXTENSION_UNAVAILABLE("Recursively describes components using -[UIApplication keyWindow]");

@end

#endif
