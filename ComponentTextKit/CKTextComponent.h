/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKComponent.h>

#import <ComponentKit/CKAsyncLayer.h>
#import <ComponentKit/CKTextKitAttributes.h>

struct CKTextComponentAccessibilityContext
{
  NSNumber *isAccessibilityElement;
  NSNumber *providesAccessibleElements;
  /**
   Should rarely be used, the component's text will be used by default.
   */
  CKComponentAccessibilityTextAttribute accessibilityLabel;
};

struct CKTextComponentOptions
{
  /**
   Controls if rendering should be done synchronously or async
   See @CKAsyncLayer
   */
  CKAsyncLayerDisplayMode displayMode;
  CKTextComponentAccessibilityContext accessibilityContext;
};

@interface CKTextComponent : CKComponent

+ (instancetype)newWithTextAttributes:(const CKTextKitAttributes &)attributes
                       viewAttributes:(const CKViewComponentAttributeValueMap &)viewAttributes
                              options:(const CKTextComponentOptions &)options
                                 size:(const CKComponentSize &)size;

@end
