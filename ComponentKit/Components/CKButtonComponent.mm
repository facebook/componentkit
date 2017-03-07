/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKButtonComponent.h"

#import <array>

#import <ComponentKit/CKAssert.h>

#import "CKInternalHelpers.h"
#import "CKComponentSubclass.h"

/**
 Note this only enumerates through the default UIControlStates, not any application-defined or system-reserved ones.
 It excludes any states with both UIControlStateHighlighted and UIControlStateDisabled set as that is an invalid value.
 (UIButton will, surprisingly enough, throw away one of the bits if they are set together instead of ignoring it.)
 */
static void enumerateAllStates(void (^block)(UIControlState))
{
  for (int highlighted = 0; highlighted < 2; highlighted++) {
    for (int disabled = 0; disabled < 2; disabled++) {
      for (int selected = 0; selected < 2; selected++) {
        UIControlState state = (highlighted ? UIControlStateHighlighted : 0) | (disabled ? UIControlStateDisabled : 0) | (selected ? UIControlStateSelected : 0);
        if (state & UIControlStateHighlighted && state & UIControlStateDisabled) {
          continue;
        }
        block(state);
      }
    }
  }
}

static inline NSUInteger indexForState(UIControlState state)
{
  NSUInteger offset = 0;
  if (state & UIControlStateHighlighted) {
    offset += 4;
  }
  if (state & UIControlStateDisabled) {
    offset += 2;
  }
  if (state & UIControlStateSelected) {
    offset += 1;
  }
  return offset;
}

struct CKStateConfiguration {
  CKButtonTitle title;
  UIColor *titleColor;
  UIImage *image;
  UIImage *backgroundImage;

  bool operator==(const CKStateConfiguration &other) const
  {
    return title == other.title
    && CKObjectIsEqual(titleColor, other.titleColor)
    && CKObjectIsEqual(image, other.image)
    && CKObjectIsEqual(backgroundImage, other.backgroundImage);
  }
};

/** Use indexForState to map from UIControlState to an array index. */
typedef std::array<CKStateConfiguration, 8> CKStateConfigurationArray;

@interface CKButtonComponentConfiguration : NSObject
{
@public
  CKStateConfigurationArray _configurations;
  NSUInteger _precomputedHash;
}
@end

@implementation CKButtonComponent
{
  CGSize _intrinsicSize;
}

+ (instancetype)newWithTitles:(const std::unordered_map<UIControlState, CKButtonTitle> &)titles
                  titleColors:(const std::unordered_map<UIControlState, UIColor *> &)titleColors
                       images:(const std::unordered_map<UIControlState, UIImage *> &)images
             backgroundImages:(const std::unordered_map<UIControlState, UIImage *> &)backgroundImages
                    titleFont:(UIFont *)titleFont
                     selected:(BOOL)selected
                      enabled:(BOOL)enabled
                       action:(const CKTypedComponentAction<UIEvent *> &)action
                         size:(const CKComponentSize &)size
                   attributes:(const CKViewComponentAttributeValueMap &)passedAttributes
   accessibilityConfiguration:(CKButtonComponentAccessibilityConfiguration)accessibilityConfiguration
{
  static const CKComponentViewAttribute titleFontAttribute = {"CKButtonComponent.titleFont", ^(UIButton *button, id value){
    button.titleLabel.font = value;
  }};

  static const CKComponentViewAttribute configurationAttribute = {
    "CKButtonComponent.config",
    ^(UIButton *view, CKButtonComponentConfiguration *config) {
      enumerateAllStates(^(UIControlState state) {
        const CKStateConfiguration &stateConfig = config->_configurations[indexForState(state)];
        const CKButtonTitle title = stateConfig.title;
        if (title.string) {
          [view setTitle:title.string forState:state];
        } else if (title.attributedString) {
          [view setAttributedTitle:title.attributedString forState:state];
        }
        if (stateConfig.titleColor) {
          [view setTitleColor:stateConfig.titleColor forState:state];
        }
        if (stateConfig.image) {
          [view setImage:stateConfig.image forState:state];
        }
        if (stateConfig.backgroundImage) {
          [view setBackgroundImage:stateConfig.backgroundImage forState:state];
        }
      });
    },
    // No unapplicator.
    nil,
    ^(UIButton *view, CKButtonComponentConfiguration *oldConfig, CKButtonComponentConfiguration *newConfig) {
      enumerateAllStates(^(UIControlState state) {
        const CKStateConfiguration &oldStateConfig = oldConfig->_configurations[indexForState(state)];
        const CKStateConfiguration &newStateConfig = newConfig->_configurations[indexForState(state)];
        if (!(oldStateConfig.title == newStateConfig.title)) {
          if (newStateConfig.title.string) {
            [view setTitle:newStateConfig.title.string forState:state];
            [view setAttributedTitle:nil forState:state];
          } else if (newStateConfig.title.attributedString) {
            [view setTitle:nil forState:state];
            [view setAttributedTitle:newStateConfig.title.attributedString forState:state];
          }
        }
        if (!CKObjectIsEqual(oldStateConfig.titleColor, newStateConfig.titleColor)) {
          [view setTitleColor:newStateConfig.titleColor forState:state];
        }
        if (!CKObjectIsEqual(oldStateConfig.image, newStateConfig.image)) {
          [view setImage:newStateConfig.image forState:state];
        }
        if (!CKObjectIsEqual(oldStateConfig.backgroundImage, newStateConfig.backgroundImage)) {
          [view setBackgroundImage:newStateConfig.backgroundImage forState:state];
        }
      });
    }
  };

  CKViewComponentAttributeValueMap attributes(passedAttributes);
  attributes.insert({
    {configurationAttribute, configurationFromValues(titles, titleColors, images, backgroundImages)},
    {titleFontAttribute, titleFont},
    {@selector(setSelected:), @(selected)},
    {@selector(setEnabled:), @(enabled)},
    CKComponentActionAttribute(action, UIControlEventTouchUpInside),
  });

  UIEdgeInsets contentEdgeInsets = UIEdgeInsetsZero;
  auto it = passedAttributes.find(@selector(setContentEdgeInsets:));
  if (it != passedAttributes.end()) {
    contentEdgeInsets = [it->second UIEdgeInsetsValue];
  }

  CKButtonComponent *b = [super
                          newWithView:{
                            [UIButton class],
                            std::move(attributes),
                            {
                              .accessibilityLabel = accessibilityConfiguration.accessibilityLabel,
                              .accessibilityComponentAction = enabled ? CKComponentAction(action) : NULL
                            }
                          }
                          size:size];

  UIControlState state = (selected ? UIControlStateSelected : UIControlStateNormal)
                       | (enabled ? UIControlStateNormal : UIControlStateDisabled);
  b->_intrinsicSize = intrinsicSize(valueForState(titles, state), titleFont, valueForState(images, state),
                                    valueForState(backgroundImages, state), contentEdgeInsets);

  return b;
}

- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
{
  return {self, constrainedSize.clamp(_intrinsicSize)};
}

static CKButtonComponentConfiguration *configurationFromValues(const std::unordered_map<UIControlState, CKButtonTitle> &titles,
                                                               const std::unordered_map<UIControlState, UIColor *> &titleColors,
                                                               const std::unordered_map<UIControlState, UIImage *> &images,
                                                               const std::unordered_map<UIControlState, UIImage *> &backgroundImages)
{
  CKButtonComponentConfiguration *config = [[CKButtonComponentConfiguration alloc] init];
  CKStateConfigurationArray &configs = config->_configurations;
  NSUInteger hash = 0;
  for (const auto it : titles) {
    configs[indexForState(it.first)].title = it.second;
    hash ^= (it.first ^ [(it.second.string ?: it.second.attributedString) hash]);
  }
  for (const auto it : titleColors) {
    configs[indexForState(it.first)].titleColor = it.second;
    hash ^= (it.first ^ [it.second hash]);
  }
  for (const auto it : images) {
    configs[indexForState(it.first)].image = it.second;
    hash ^= (it.first ^ [it.second hash]);
  }
  for (const auto it : backgroundImages) {
    configs[indexForState(it.first)].backgroundImage = it.second;
    hash ^= (it.first ^ [it.second hash]);
  }
  config->_precomputedHash = hash;
  return config;
}

template<typename T>
static T valueForState(const std::unordered_map<UIControlState, T> &m, UIControlState state)
{
  auto it = m.find(state);
  if (it != m.end()) {
    return it->second;
  }
  // "If a title is not specified for a state, the default behavior is to use the title associated with the
  // UIControlStateNormal state." (Similarly for other attributes.)
  it = m.find(UIControlStateNormal);
  if (it != m.end()) {
    return it->second;
  }
  return nil;
}

static CGSize intrinsicSize(CKButtonTitle title, UIFont *titleFont, UIImage *image,
                            UIImage *backgroundImage, UIEdgeInsets contentEdgeInsets)
{
  if (!titleFont)
    titleFont = [UIFont systemFontOfSize:17.0f];
  NSDictionary *attributes = @{NSFontAttributeName: titleFont};

  const CGSize infiniteSize = CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX);
  
  CGSize titleSize = CGSizeZero;
  if (title.attributedString.length) {
    NSMutableAttributedString *attributedString = [title.attributedString mutableCopy];
    [title.attributedString enumerateAttributesInRange:NSMakeRange(0, attributedString.length) options:0 usingBlock:^(NSDictionary<NSString *,id> *attrs, NSRange range, BOOL *stop) {
      NSMutableDictionary *mergedAttributes = [attributes mutableCopy];
      [mergedAttributes addEntriesFromDictionary:attrs];
      [attributedString addAttributes:mergedAttributes range:range];
    }];
    titleSize = [attributedString boundingRectWithSize:infiniteSize options:NSStringDrawingUsesLineFragmentOrigin context:NULL].size;
  } else if (title.string.length) {
    titleSize = [title.string boundingRectWithSize:infiniteSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:NULL].size;
  }
  titleSize = CGSizeMake(ceil(titleSize.width), ceil(titleSize.height));
  
  const CGSize imageSize = image.size;
  const CGSize contentSize = {
    titleSize.width + imageSize.width + contentEdgeInsets.left + contentEdgeInsets.right,
    MAX(titleSize.height, imageSize.height) + contentEdgeInsets.top + contentEdgeInsets.bottom
  };
  const CGSize backgroundImageSize = backgroundImage.size;
  return {
    MAX(backgroundImageSize.width, contentSize.width),
    MAX(backgroundImageSize.height, contentSize.height)
  };
}

@end

@implementation CKButtonComponentConfiguration

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  } else if ([object isKindOfClass:[self class]]) {
    CKButtonComponentConfiguration *other = object;
    return _configurations == other->_configurations;
  }
  return NO;
}

- (NSUInteger)hash
{
  return _precomputedHash;
}

@end
