/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKLabelComponent.h"

#import <ComponentTextKit/CKTextComponent.h>
#import <ComponentKit/CKComponentViewConfiguration_SwiftBridge+Internal.h>
#import <ComponentKit/CKComponentViewAttribute_SwiftBridge+Internal.h>
#import <ComponentKit/CKComponentSize_SwiftBridge+Internal.h>

@implementation CKLabelComponent

- (instancetype)initWithText:(NSString *)text
            truncationString:(NSString *)truncationString
                        font:(UIFont *)font
                       color:(UIColor *)color
               lineBreakMode:(NSLineBreakMode )lineBreakMode
        maximumNumberOfLines:(NSUInteger )maximumNumberOfLines
                shadowOffset:(CGSize )shadowOffset
                 shadowColor:(UIColor *)shadowColor
               shadowOpacity:(CGFloat )shadowOpacity
                shadowRadius:(CGFloat )shadowRadius
                   alignment:(NSTextAlignment )alignment
         firstLineHeadIndent:(CGFloat )firstLineHeadIndent
                  headIndent:(CGFloat )headIndent
                  tailIndent:(CGFloat )tailIndent
          lineHeightMultiple:(CGFloat )lineHeightMultiple
           maximumLineHeight:(CGFloat )maximumLineHeight
           minimumLineHeight:(CGFloat )minimumLineHeight
                 lineSpacing:(CGFloat )lineSpacing
            paragraphSpacing:(CGFloat )paragraphSpacing
      paragraphSpacingBefore:(CGFloat )paragraphSpacingBefore
                   swiftSize:(CKComponentSize_SwiftBridge *)swiftSize
             swiftAttributes:(NSArray<CKComponentViewAttribute_SwiftBridge *> *)swiftAttributes

{
  const auto labelAttributes = CKLabelAttributes{
    .string = text,
    .font = font,
    .color = color,
    .lineBreakMode = lineBreakMode,
    .maximumNumberOfLines = maximumNumberOfLines,
    .shadowOffset = shadowOffset,
    .shadowColor = shadowColor,
    .shadowOpacity = shadowOpacity,
    .shadowRadius = shadowRadius,
    .alignment = alignment,
    .firstLineHeadIndent = firstLineHeadIndent,
    .headIndent = headIndent,
    .tailIndent = tailIndent,
    .lineHeightMultiple = lineHeightMultiple,
    .maximumLineHeight = maximumLineHeight,
    .minimumLineHeight = minimumLineHeight,
    .lineSpacing = lineSpacing,
    .paragraphSpacing = paragraphSpacing,
    .paragraphSpacingBefore = paragraphSpacingBefore,
  };
  const auto size = swiftSize != nil ? swiftSize.componentSize : CKComponentSize{};
  return [self initWithLabelAttributes:labelAttributes
                        viewAttributes:CKComponentViewAttribute_SwiftBridgeToMap(swiftAttributes)
                                  size:size];
}

- (instancetype)initWithLabelAttributes:(const CKLabelAttributes &)attributes
                         viewAttributes:(const CKViewComponentAttributeValueMap &)viewAttributes
                                   size:(const CKComponentSize &)size
{
  CKViewComponentAttributeValueMap copiedMap = viewAttributes;
  return [super initWithView:{} component:
          [CKTextComponent
           newWithTextAttributes:textKitAttributes(attributes)
           viewAttributes:std::move(copiedMap)
           options:{.accessibilityContext = {.isAccessibilityElement = @(YES)}}
           size:size]];
}

+ (instancetype)newWithLabelAttributes:(const CKLabelAttributes &)attributes
                        viewAttributes:(const CKViewComponentAttributeValueMap &)viewAttributes
                                  size:(const CKComponentSize &)size
{
  return [[self alloc] initWithLabelAttributes:attributes viewAttributes:viewAttributes size:size];;
}

static const CKTextKitAttributes textKitAttributes(const CKLabelAttributes &labelAttributes)
{
  return {
    .attributedString = formattedAttributedString(labelAttributes.string, labelAttributes),
    .truncationAttributedString = formattedAttributedString(labelAttributes.truncationString, labelAttributes),
    .lineBreakMode = labelAttributes.lineBreakMode,
    .maximumNumberOfLines = labelAttributes.maximumNumberOfLines,
    .shadowOffset = labelAttributes.shadowOffset,
    .shadowColor = labelAttributes.shadowColor,
    .shadowOpacity = labelAttributes.shadowOpacity,
    .shadowRadius = labelAttributes.shadowRadius,
  };
}

static NSAttributedString *formattedAttributedString(NSString *string, const CKLabelAttributes &labelAttributes)
{
  if (!string) {
    return nil;
  }
  return [[NSAttributedString alloc] initWithString:string
                                         attributes:stringAttributes(labelAttributes)];
}

static NSDictionary *stringAttributes(const CKLabelAttributes &labelAttributes)
{
  NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
  if (labelAttributes.font) {
    attributes[NSFontAttributeName] = labelAttributes.font;
  }
  if (labelAttributes.color) {
    attributes[NSForegroundColorAttributeName] = labelAttributes.color;
  }
  attributes[NSParagraphStyleAttributeName] = paragraphStyle(labelAttributes);
  return attributes;
}

static NSParagraphStyle *paragraphStyle(const CKLabelAttributes &labelAttributes)
{
  NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
  ps.alignment = labelAttributes.alignment;
  ps.firstLineHeadIndent = labelAttributes.firstLineHeadIndent;
  ps.headIndent = labelAttributes.headIndent;
  ps.tailIndent = labelAttributes.tailIndent;
  ps.lineHeightMultiple = labelAttributes.lineHeightMultiple;
  ps.maximumLineHeight = labelAttributes.maximumLineHeight;
  ps.minimumLineHeight = labelAttributes.minimumLineHeight;
  ps.lineSpacing = labelAttributes.lineSpacing;
  ps.paragraphSpacing = labelAttributes.paragraphSpacing;
  ps.paragraphSpacingBefore = labelAttributes.paragraphSpacingBefore;
  return ps;
}

@end
