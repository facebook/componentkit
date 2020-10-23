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
  return [component isKindOfClass:[CKAccessibilityAwareComponent class]];
}

CKComponent * CKAccessibilityAwareWrapper(CKComponent *wrappedComponent) {
  auto const shouldUseComponentAsSourceOfAccessibility = [CKComponentContext<CKComponentBasedAccessibilityContext>::get() componentBasedAXEnabled];
  if (!shouldUseComponentAsSourceOfAccessibility) {
    return wrappedComponent;
  }
  return [CKAccessibilityAwareComponent newWithComponent:wrappedComponent];
}
