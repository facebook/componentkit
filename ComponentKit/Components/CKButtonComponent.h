/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <unordered_map>

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentAction.h>
#import <ComponentKit/CKContainerWrapper.h>

struct CKButtonComponentAccessibilityConfiguration {
  /** Accessibility label for the button. If one is not provided, the button title will be used as a label */
  NSString *accessibilityLabel;
};

/**
 A component that creates a UIButton.

 This component chooses the smallest size within its SizeRange that will fit its content. If its max size is smaller
 than the size required to fit its content, it will be truncated.
 */
@interface CKButtonComponent : CKComponent

+ (instancetype)newWithTitles:(CKContainerWrapper<std::unordered_map<UIControlState, NSString *>> &&)titles
                  titleColors:(CKContainerWrapper<std::unordered_map<UIControlState, UIColor *>> &&)titleColors
                       images:(CKContainerWrapper<std::unordered_map<UIControlState, UIImage *>> &&)images
             backgroundImages:(CKContainerWrapper<std::unordered_map<UIControlState, UIImage *>> &&)backgroundImages
                    titleFont:(UIFont *)titleFont
                     selected:(BOOL)selected
                      enabled:(BOOL)enabled
                       action:(const CKTypedComponentAction<UIEvent *> &)action
                         size:(const CKComponentSize &)size
                   attributes:(const CKViewComponentAttributeValueMap &)attributes
   accessibilityConfiguration:(const CKButtonComponentAccessibilityConfiguration &)accessibilityConfiguration;

@end
