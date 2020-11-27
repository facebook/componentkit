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
#import <ComponentKit/CKDefines.h>

#if CK_NOT_SWIFT

@class CKComponent;

typedef NS_OPTIONS(NSUInteger, CKAccessibilityAggregatedAttributes) {
  CKAccessibilityAggregatedAttributeNone = 0,
  CKAccessibilityAggregatedAttributeLabel = 1 << 0,
  CKAccessibilityAggregatedAttributeTraits = 1 << 1,
  CKAccessibilityAggregatedAttributeValue = 1 << 2,
  CKAccessibilityAggregatedAttributeHint = 1 << 3,
  CKAccessibilityAggregatedAttributeActions = 1 << 4,
  CKAccessibilityAggregatedAttributesAll =  CKAccessibilityAggregatedAttributeLabel |
                                            CKAccessibilityAggregatedAttributeTraits |
                                            CKAccessibilityAggregatedAttributeValue |
                                            CKAccessibilityAggregatedAttributeHint |
                                            CKAccessibilityAggregatedAttributeActions,
};

/**
 Wraps the component in an accessibility aggregation component.

 @param component The component to wrap.
 @param attributes The accessibility attributes that will be aggregated.
 */
CKComponent *CKComponentWithAccessibilityAggregationWrapper(CKComponent *component, const CKAccessibilityAggregatedAttributes attributes);

/**
 Helper function that returns true if any of the parent components will aggregate accessibility attributes
 */
BOOL CKAccessibilityAggregationIsActive();

#endif
