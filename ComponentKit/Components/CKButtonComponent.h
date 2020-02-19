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

#import <unordered_map>

#import <UIKit/UIKit.h>

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKAction.h>
#import <ComponentKit/CKContainerWrapper.h>

template <typename V>
class CKButtonComponentStateMap {
public:
  using Map = std::unordered_map<UIControlState, V>;
  /// Default constructor.
  CKButtonComponentStateMap() {}
  /// Single value (applied to `UIControlStateNormal`).
  CKButtonComponentStateMap(const V v) : map({{UIControlStateNormal, v}}) {}
  /// Multiple values for specific `UIControlState`s as inline list.
  CKButtonComponentStateMap(std::initializer_list<typename Map::value_type> init) : map(std::move(init)) {}
  /// Multiple values for specific `UIControlState`s as existing map.
  CKButtonComponentStateMap(const std::unordered_map<UIControlState, V> &m) : map(m) {};
  /// Get the states map.
  const Map &getMap() const { return map; }
private:
  Map map;
};

struct CKButtonComponentOptions {
  /// The title of the button for different states.
  CKButtonComponentStateMap<NSString *> titles;
  /// The title colors of the button for different states.
  CKButtonComponentStateMap<UIColor *> titleColors;
  /// The images of the button for different states.
  CKButtonComponentStateMap<UIImage *> images;
  /// The background images of the button for different states.
  CKButtonComponentStateMap<UIImage *> backgroundImages;
  /// The title font the button.
  UIFont *titleFont;
  /// The title alignment
  NSTextAlignment titleAlignment;
  /// Whether the button is selected.
  BOOL selected = NO;
  /// Whether the button is enabled.
  BOOL enabled = YES;
  /// The maximum number of lines to use for rendering text.
  NSInteger numberOfLines = 1;
  /// The line break mode for the title label.
  NSLineBreakMode lineBreakMode = NSLineBreakByTruncatingMiddle;
  /// Additional attributes for the underlying UIButton
  CKViewComponentAttributeValueMap attributes;
  /// Accessibility context for the button.
  CKComponentAccessibilityContext accessibilityContext;
  /// Size restrictions for the button.
  CKComponentSize size;
  /// The inset or outset margins for the rectangle around the button's content.
  UIEdgeInsets contentEdgeInsets = UIEdgeInsetsZero;
  /// The inset or outset margins for the rectangle around the button's title text.
  UIEdgeInsets titleEdgeInsets = UIEdgeInsetsZero;
  /// The inset or outset margins for the rectangle around the button's image.
  UIEdgeInsets imageEdgeInsets = UIEdgeInsetsZero;
  /// The outset for tap target expansion
  UIEdgeInsets tapTargetExpansion;
};

/**
 @uidocs https://fburl.com/CKButtonComponent:05b0

 A component that creates a UIButton.

 This component chooses the smallest size within its SizeRange that will fit its content. If its max size is smaller
 than the size required to fit its content, it will be truncated.
 */
@interface CKButtonComponent : CKComponent

+ (instancetype)newWithAction:(const CKAction<UIEvent *>)action
                      options:(const CKButtonComponentOptions &)options;

@end

#import <ComponentKit/ButtonComponentBuilder.h>

#endif
