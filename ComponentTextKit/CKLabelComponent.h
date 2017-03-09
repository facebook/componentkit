/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKCompositeComponent.h>

struct CKLabelAttributes
{
  /** The string you would like to render in the label. If nil no text will be displayed. */
  NSString *string;
  /** 
   The truncation string to use when the text component needs to clip your text.  Usually just an ellipsis. The
   truncation string shares the same formatting as the string itself.  If nil the text will simply clip.
   */
  NSString *truncationString;
  /** The font with which the label should be rendered. If nil, the system default will be used. */
  UIFont *font;
  /** The foreground color for the text.  If nil, black is used. */
  UIColor *color;
  /** The line break mode for the text container.  We only support word and char wrapping. */
  NSLineBreakMode lineBreakMode;
  /** The maximum number of lines to draw. */
  NSUInteger maximumNumberOfLines;

  /** The x and y offset for the shadow encapsulated as a size. */
  CGSize shadowOffset;
  /** The color of the shadow. */
  UIColor *shadowColor;
  /** An opacity parameter that in combination with the color determines how opaque the shadow should be */
  CGFloat shadowOpacity;
  /** The blur radius of the shadow. */
  CGFloat shadowRadius;

  /** @see NSParagraphStyle for how to use these parameters. */
  NSTextAlignment alignment;
  CGFloat firstLineHeadIndent;
  CGFloat headIndent;
  CGFloat tailIndent;
  CGFloat lineHeightMultiple;
  CGFloat maximumLineHeight;
  CGFloat minimumLineHeight;
  CGFloat lineSpacing;
  CGFloat paragraphSpacing;
  CGFloat paragraphSpacingBefore;
};

/**
 CKLabelComponent is a simplified text component that just displays NSStrings.
 
 CKTextComponent is a more powerful, fully-featured text rendering option, but sometimes you don't want all the weight
 of creating an attributed string inline just so you can render a little "From:" label in an interface.
 CKLabelComponent is meant for that purpose.  It is a composite component that just wraps a CKTextComponent.  It
 generates the corresponding attributed string from the attribute struct you provide and configures the text component
 for you.
   
 @see CKTextComponent for advanced text usages like link tapping.
 
 @param attributes The content and styling information for the text component.
 @param viewAttributes These are passed directly to CKTextComponent and its backing view.
 @param size The component size or {} for the default which is for the layout to take the maximum space available.
 */
@interface CKLabelComponent : CKCompositeComponent

+ (instancetype)newWithLabelAttributes:(const CKLabelAttributes &)attributes
                        viewAttributes:(const CKViewComponentAttributeValueMap &)viewAttributes
                                  size:(const CKComponentSize &)size;

@end
