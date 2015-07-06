// Copyright 2004-present Facebook. All Rights Reserved.

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKPlatform.h>

#import <AppKit/AppKit.h>

struct CKMTextLabelComponentAttrs {
  NSString *text;
  NSFont *font;
  NSTextAlignment alignment;
  NSColor *color;
  NSColor *backgroundColor;
};

@interface CKMTextLabelComponent : CKComponent

+ (instancetype)newWithTextAttributes:(CKMTextLabelComponentAttrs)attrs
                       viewAttributes:(CKViewComponentAttributeValueMap)viewAttributes
                                 size:(CKComponentSize)size;

@end