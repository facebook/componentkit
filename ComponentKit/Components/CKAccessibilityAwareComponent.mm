/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKAccessibilityAwareComponent.h"

#import <ComponentKit/CKComponentAccessibility.h>
#import <ComponentKit/ComponentLayoutContext.h>
#import <ComponentKit/CKComponentSubclass.h>

#import <ComponentKit/CKGlobalConfig.h>

@implementation CKComponentBasedAccessibilityContext

- (instancetype)initWithComponentBasedAXEnabled:(BOOL)enabled {
  if (self = [super init]) {
    _componentBasedAXEnabled = enabled;
  }
  return self;
}

+ (instancetype)newWithComponentBasedAXEnabled:(BOOL)enabled {
  return [[self alloc] initWithComponentBasedAXEnabled:enabled];
}

@end

@interface CKAccessibilityAwareComponent : CKCompositeComponent
@end


@implementation CKAccessibilityAwareComponent

+ (instancetype)newWithComponent:(id<CKMountable>)component
{
  CKComponentScope scope(self);
  return [super newWithComponent:component];
}

@end

BOOL IsAccessibilityBasedOnComponent(CKComponent *component) {
  if (!component) {
    return NO;
  }
  auto const componentAXMode = CKReadGlobalConfig().componentAXMode;
  switch (componentAXMode) {
    case RCComponentBasedAccessibilityModeEnabled:
      return YES;
      break;
    case RCComponentBasedAccessibilityModeEnabledOnSurface:
      return [component isMemberOfClass:[CKAccessibilityAwareComponent class]];
      break;
    default:
      break;
  }
  return NO;
}

BOOL shouldUseComponentAsSourceOfAccessibility() {
  auto const componentAXMode = CKReadGlobalConfig().componentAXMode;
  // return true if component based accessiility is enabled everywhwere or
  // if it's enabled per surface, and we are in the correct surface
  return
    componentAXMode == RCComponentBasedAccessibilityModeEnabled ||
    (componentAXMode == RCComponentBasedAccessibilityModeEnabledOnSurface
    && [CKComponentContext<CKComponentBasedAccessibilityContext>::get() componentBasedAXEnabled]);
}

static BOOL isComponentBasedAccessibilityEnabledPerSurface() {
  auto const componentAXMode = CKReadGlobalConfig().componentAXMode;
  // Wrap only if we want to selectively enable component based accessibility on surface by surface base
  return
    componentAXMode == RCComponentBasedAccessibilityModeEnabledOnSurface
    && [CKComponentContext<CKComponentBasedAccessibilityContext>::get() componentBasedAXEnabled];
}

CKComponent * CKAccessibilityAwareWrapper(CKComponent *wrappedComponent) {
  if (!isComponentBasedAccessibilityEnabledPerSurface()) {
    return wrappedComponent;
  }
  return [CKAccessibilityAwareComponent newWithComponent:wrappedComponent];
}
