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

#import <ComponentKit/CKAnimation.h>
#import <ComponentKit/CKCompositeComponent.h>
#import <ComponentKit/CKComponentContext.h>

NS_ASSUME_NONNULL_BEGIN

@interface CKComponentBasedAccessibilityContext : NSObject

@property (nonatomic, assign, readonly) BOOL componentBasedAXEnabled;

+ (instancetype)newWithComponentBasedAXEnabled:(BOOL)enabled;

@end

BOOL shouldUseComponentAsSourceOfAccessibility(void);
CKComponent * CKAccessibilityAwareWrapper(CKComponent *wrappedComponent);
BOOL IsAccessibilityBasedOnComponent(CKComponent *component);

NS_ASSUME_NONNULL_END
