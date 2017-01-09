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

struct CKButtonComponentAccessibilityConfiguration {
  /** Accessibility label for the button. If one is not provided, the button title will be used as a label */
  NSString *accessibilityLabel;
};

struct CKButtonTitle {
  CKButtonTitle() : title(nil), attributedTitle(nil) {};
  CKButtonTitle(std::nullptr_t v) : title(nil), attributedTitle(nil) {};
  CKButtonTitle(NSString *t) : title(t), attributedTitle(nil) {};
  CKButtonTitle(NSAttributedString *t) : title(nil), attributedTitle(t) {};

  NSString *title;
  NSAttributedString *attributedTitle;
  
  bool operator==(const CKButtonTitle &other) const
  {
    return CKObjectIsEqual(title, other.title)
    && CKObjectIsEqual(attributedTitle, other.attributedTitle);
  }
};

/**
 A component that creates a UIButton.

 This component chooses the smallest size within its SizeRange that will fit its content. If its max size is smaller
 than the size required to fit its content, it will be truncated.
 */
@interface CKButtonComponent : CKComponent

+ (instancetype)newWithTitles:(const std::unordered_map<UIControlState, CKButtonTitle> &)titles
                  titleColors:(const std::unordered_map<UIControlState, UIColor *> &)titleColors
                       images:(const std::unordered_map<UIControlState, UIImage *> &)images
             backgroundImages:(const std::unordered_map<UIControlState, UIImage *> &)backgroundImages
                    titleFont:(UIFont *)titleFont
                     selected:(BOOL)selected
                      enabled:(BOOL)enabled
                       action:(const CKTypedComponentAction<UIEvent *> &)action
                         size:(const CKComponentSize &)size
                   attributes:(const CKViewComponentAttributeValueMap &)attributes
   accessibilityConfiguration:(CKButtonComponentAccessibilityConfiguration)accessibilityConfiguration;

@end
