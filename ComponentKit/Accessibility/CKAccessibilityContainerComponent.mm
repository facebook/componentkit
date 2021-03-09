/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKAccessibilityContainerComponent.h"

#import <ComponentKit/CKComponentInternal.h>

@interface CKAccessibilityContainerComponentView: UIView
@property (nonatomic) CKAccessibilityElementsFactory accessibilityElementsFactory;
@end

@implementation CKAccessibilityContainerComponentView
{
  @package
  NSArray<UIAccessibilityElement *> *_accessibilityElements;
}

- (BOOL)isAccessibilityElement
{
  return NO; // The container is not accessible by itself
}

- (NSArray *)accessibilityElements
{
  if (!_accessibilityElements && _accessibilityElementsFactory) {
    _accessibilityElements = _accessibilityElementsFactory(self);
  }
  return _accessibilityElements;
}

@end

@interface CKAccessibilityContainerComponent : CKCompositeComponent
@end

@implementation CKAccessibilityContainerComponent

+ (instancetype)newWithComponent:(CKComponent * _Nullable)component
    accessibilityElementsFactory:(CKAccessibilityElementsFactory)factory
{
  return [super newWithView:{
    [CKAccessibilityContainerComponentView class],
    {
      {@selector(setAccessibilityElementsFactory:), factory},
    }
  } component:component];
}

#pragma mark - CK overrides

- (CK::Component::MountResult)mountInContext:(const CK::Component::MountContext &)context
                                      layout:(const RCLayout &)layout
                              supercomponent:(CKComponent *)supercomponent
{
  const auto mountResult = [super mountInContext:context layout:layout supercomponent:supercomponent];

  // Reset the cached attributes on mount in order to refresh them every time we remount the component
  // and avoid having the stale values.
  if (const auto mountedView = self.mountedView) {
    ((CKAccessibilityContainerComponentView *)mountedView)->_accessibilityElements = nil;
  }

  return mountResult;
}

@end

CKComponent *CKAccessibilityContainerComponentWrapper(CKComponent * _Nullable component, CKAccessibilityElementsFactory factory)
{
  return [CKAccessibilityContainerComponent newWithComponent:component accessibilityElementsFactory:factory];
}
