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
  const Map map;
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
  /// Wether the button is selected.
  BOOL selected = NO;
  /// Wether the button is enabled.
  BOOL enabled = YES;
  /// The maximum number of lines to use for rendering text.
  NSInteger numberOfLines = 1;
  /// Additional attributes for the underlying UIBUtton
  CKViewComponentAttributeValueMap attributes;
  /// Accessibility context for the button.
  CKComponentAccessibilityContext accessibilityContext;
  /// Size restrictions for the button.
  CKComponentSize size;
};

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

+ (instancetype)newWithAction:(const CKAction<UIEvent *>)action
                      options:(const CKButtonComponentOptions &)options;

@end
