// Copyright 2004-present Facebook. All Rights Reserved.

#import "CKMTextLabelComponent.h"

#import "NSString+CKMTextCache.h"

#import <ComponentKit/CKComponentSubclass.h>

@implementation CKMTextLabelComponent {
  CKMTextLabelComponentAttrs _attrs;
}

+ (instancetype)newWithTextAttributes:(CKMTextLabelComponentAttrs)attrs
                       viewAttributes:(CKViewComponentAttributeValueMap)viewAttributes
                                 size:(CKComponentSize)size
{
  CKViewComponentAttributeValueMap addl = {
    {@selector(setEditable:), @NO},
    {@selector(setSelectable:), @NO},
    {@selector(setStringValue:), attrs.text ?: @""},
    {@selector(setBackgroundColor:), attrs.backgroundColor},
    {@selector(setTextColor:), attrs.color},
    {@selector(setBezeled:), @NO},
    {@selector(setAlignment:), @(attrs.alignment)},
    {@selector(setFont:), attrs.font},
  };
  viewAttributes.insert(addl.begin(), addl.end());

  CKMTextLabelComponent *c =
  [super
   newWithView:{
     {[NSTextField class]},
     {
       std::move(viewAttributes),
     },
   }
   size:size];
  if (c) {
    c->_attrs = std::move(attrs);
  }
  return c;
}

+ (NSCache *)cache
{
  static dispatch_once_t onceToken;
  static NSCache *cache;
  dispatch_once(&onceToken, ^{
    cache = [[NSCache alloc] init];
  });
  return cache;
}

- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
{
  const CGSize constraint = {
    isinf(constrainedSize.max.width) ? CGFLOAT_MAX : constrainedSize.max.width,
    isinf(constrainedSize.max.height) ? 0.0 : CGFLOAT_MAX,
  };

  NSFont *font = _attrs.font ?: [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSRegularControlSize]];
  
  NSDictionary *attributes = @{ NSFontAttributeName: font };

  CGRect rect = [_attrs.text ckm_boundingRectWithSize:constraint
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:attributes];

  rect = UIEdgeInsetsInsetRect(rect, {.left = -5, .right = -5});

  return {self, constrainedSize.clamp(rect.size)};
}

@end