/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKAccessibilityAggregation.h"

#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKComponentContext.h>
#import <ComponentKit/CKCompositeComponent.h>
#import <RenderCore/CKInternalHelpers.h>
#import <stack>

#import "CKComponentAccessibility.h"
#import "CKComponentInternal.h"


@interface CKAccessibilityAggregationContext : NSObject
@end

@interface CKAccessibilityAggregatorComponent : CKCompositeComponent

+ (instancetype)newWithComponent:(CKComponent *)component aggregatedAttributes:(CKAccessibilityAggregatedAttributes)attributes;

@end

@interface CKAccessibilityAggregatorElement : UIAccessibilityElement

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithComponent:(CKAccessibilityAggregatorComponent *)component NS_DESIGNATED_INITIALIZER;

@end

@interface CKAccessibilityAggregationCache : NSObject
@property (nonatomic, assign) UIAccessibilityTraits traits;
@property (nonatomic, copy) NSString* label;
@property (nonatomic, copy) NSString* hint;
@property (nonatomic, copy) NSString* value;
@property (nonatomic, copy) NSPointerArray *actions;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithLabel:(NSString *)label
                         hint:(NSString *)hint
                        value:(NSString *)value
                       traits:(UIAccessibilityTraits)traits
                      actions:(NSPointerArray *)actions NS_DESIGNATED_INITIALIZER;

@end

@implementation CKAccessibilityAggregatorComponent {
  CKComponent *_childComponent;
  CKAccessibilityAggregatedAttributes _accessibilityAttributes;
  CKAccessibilityAggregationCache *_accessibilityAttributesCache;
  CKAccessibilityAggregatorElement *_accessibilityElement;
}

+ (instancetype)newWithComponent:(CKComponent *)component aggregatedAttributes:(CKAccessibilityAggregatedAttributes)attributes
{
  CKAssertWithCategory(attributes != CKAccessibilityAggregatedAttributeNone,
                       [component className],
                       @"A CKAccessibilityAggregatorComponent should not be allocated without at least one aggregated accessibility attribute");
  const auto c = [super newWithComponent:component];
  if (c) {
    c->_childComponent = component;
    c->_accessibilityAttributes = attributes;
    c->_accessibilityAttributesCache = nil;
  }
  return c;
}

- (CK::Component::MountResult)mountInContext:(const CK::Component::MountContext &)context
                                      layout:(const RCLayout &)layout
                              supercomponent:(CKComponent *)supercomponent
{
  if (CK::Component::Accessibility::IsAccessibilityEnabled()) {
    // Resetting the cached attributes on mount in order to refresh them everytime we remount the component
    // and avoid having stale values.
    _accessibilityAttributesCache = nil;
    _accessibilityElement = [[CKAccessibilityAggregatorElement alloc] initWithComponent:self];
  }
  return [super mountInContext:context layout:layout supercomponent:supercomponent];
}

- (CKAccessibilityAggregationCache *)cachedAccessibilityAttributes
{
  if (!_accessibilityAttributesCache) {
    _accessibilityAttributesCache = populateAccessibilityAttributesCache(_accessibilityAttributes, self);
  }
  return _accessibilityAttributesCache;
}

- (NSArray *)accessibilityElements
{
  if (_accessibilityElement) {
    return @[_accessibilityElement];
  }
  return nil;
}

- (NSString *)accessibilityLabel
{
  return [self cachedAccessibilityAttributes].label;
}

- (UIAccessibilityTraits)accessibilityTraits
{
  return [self cachedAccessibilityAttributes].traits;
}

- (NSString *)accessibilityValue
{
  return [self cachedAccessibilityAttributes].value;
}

- (NSString *)accessibilityHint
{
  return [self cachedAccessibilityAttributes].hint;
}

- (BOOL)accessibilityActivate
{
  NSPointerArray *const actions = [self cachedAccessibilityAttributes].actions;
  if ([actions count] == 1) {
    return [(NSObject *)[actions pointerAtIndex:0] accessibilityActivate];
  } else {
    CKAssert(actions.count == 0, @"Multiple actions not supported, yet");
    return NO;
  }

}

static CKAccessibilityAggregationCache *populateAccessibilityAttributesCache(CKAccessibilityAggregatedAttributes accessibilityAttributes, CKComponent *initialObj)
{
  // This value of the context will be pushed on the Thread Local Storage of the current thread, that is the main thread when this
  // function is invoked.
  // The context pushed here will be read by the CKComponent class in order to determine what are the accessibilityElements,
  // given that the logic is different based on the fact that a component is a descendant of an aggregating component or not
  const CKComponentContext<CKAccessibilityAggregationContext> aggregationContext([CKAccessibilityAggregationContext new]);

  std::stack<NSObject *> stack;

  // Let's take advantage of nil messaging
  NSMutableString *const aggregatedLabel = ((accessibilityAttributes & CKAccessibilityAggregatedAttributeLabel) > 0) ? [NSMutableString new] : nil;
  NSMutableString *const aggregatedValue = ((accessibilityAttributes & CKAccessibilityAggregatedAttributeValue) > 0) ? [NSMutableString new] : nil;
  NSMutableString *const aggregatedHint = ((accessibilityAttributes & CKAccessibilityAggregatedAttributeHint) > 0) ? [NSMutableString new] : nil;
  NSPointerArray *const aggregatedActions = ((accessibilityAttributes & CKAccessibilityAggregatedAttributeActions) > 0) ? [NSPointerArray weakObjectsPointerArray] : nil;
  UIAccessibilityTraits aggregatedTraits = UIAccessibilityTraitNone;

  NSObject *current = initialObj;
  do {
    if (current != initialObj) {
      if ([current isAccessibilityElement] && ![current accessibilityElementsHidden]) {
        const auto accessibilityLabel = [current accessibilityLabel];
        if (aggregatedLabel && [accessibilityLabel length]) {
          [aggregatedLabel appendFormat:@"%@\n", accessibilityLabel];
        }
        aggregatedTraits |= [current accessibilityTraits];
        const auto accessibilityValue = [current accessibilityValue];
        if (aggregatedValue && [accessibilityValue length]) {
          [aggregatedValue appendFormat:@"%@", accessibilityValue];
        }
        const auto accessibilityHint = [current accessibilityHint];
        if (aggregatedHint && [accessibilityHint length]) {
          [aggregatedHint appendFormat:@"%@", accessibilityHint];
        }
        if (!stack.empty()) {
          current = stack.top();
          stack.pop();
        } else {
          current = nil;
        }
        continue;
      } else if (CKSubclassOverridesInstanceMethod(class_getSuperclass([current class]), [current class], @selector(accessibilityActivate))
                 && ![current accessibilityElementsHidden]) {
        // Add a UIView (not a subclass) accessibilityAction only if the view has isAccessibleElement overridden
        if ([current isMemberOfClass:[UIView class]]) {
          if ([current isAccessibilityElement]) {
            [aggregatedActions addPointer:(__bridge void *_Nullable)current];
          }
        } else {
          // This object can be activated, e.g. it can be triggered by a double tap. We should save it
          [aggregatedActions addPointer:(__bridge void *_Nullable)current];
        }
      }
    }
    const auto axChildren = [current respondsToSelector:@selector(accessibilityChildren)] ? [(id)current accessibilityChildren] : nil;
    if ([axChildren count] != 0) {
      // In CKAccessibilityAggregatorComponent we have to cycle over the child components,
      // because if using the UIKit accessibilityElements there will be an infinite loop
      for (NSObject *o in [axChildren reverseObjectEnumerator]) {
        stack.push(o);
      }
    } else {
      for (NSObject *o in [[current accessibilityElements] reverseObjectEnumerator]) {
        stack.push(o);
      }
    }

    if (!stack.empty()) {
      current = stack.top();
      stack.pop();
    } else {
      current = nil;
    }
  } while (current);

  return [[CKAccessibilityAggregationCache alloc]
          initWithLabel:aggregatedLabel
          hint:aggregatedHint
          value:aggregatedValue
          traits:aggregatedTraits
          actions:aggregatedActions];
}

@end

@implementation CKAccessibilityAggregationCache

- (instancetype)initWithLabel:(NSString *)label
                         hint:(NSString *)hint
                        value:(NSString *)value
                       traits:(UIAccessibilityTraits)traits
                      actions:(NSPointerArray *)actions
{
  if (self = [super init]) {
    _label = [label copy];
    _value = [value copy];
    _hint = [hint copy];
    _traits = traits;
    _actions = [actions copy];
  }
  return self;
}

@end

@implementation CKAccessibilityAggregatorElement {
  __weak CKAccessibilityAggregatorComponent *_component;
}


- (instancetype)initWithComponent:(CKAccessibilityAggregatorComponent *)component
{
  if (self = [super initWithAccessibilityContainer:component]) {
    _component = component;
    self.isAccessibilityElement = YES;
  }
  return self;
}

- (NSString *)accessibilityLabel
{
  return [_component accessibilityLabel];
}

- (NSString *)accessibilityValue
{
  return [_component accessibilityValue];
}

- (NSString *)accessibilityHint
{
  return [_component accessibilityHint];
}

- (BOOL)accessibilityActivate
{
  return [_component accessibilityActivate];
}

- (UIAccessibilityTraits)accessibilityTraits
{
  return [_component accessibilityTraits];
}

- (CGRect)accessibilityFrame
{
  return [_component accessibilityFrame];
}

@end

CKComponent *CKComponentWithAccessibilityAggregationWrapper(CKComponent *component, const CKAccessibilityAggregatedAttributes attributes)
{
  return [CKAccessibilityAggregatorComponent newWithComponent:component aggregatedAttributes:attributes];
}

@implementation CKAccessibilityAggregationContext

@end

BOOL CKAccessibilityAggregationIsActive()
{
  return CKComponentContext<CKAccessibilityAggregationContext>::get() != nil;
}
