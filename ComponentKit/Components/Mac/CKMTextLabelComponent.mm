// Copyright 2004-present Facebook. All Rights Reserved.

#import "CKMTextLabelComponent.h"

#import "NSString+CKMTextCache.h"

#import <ComponentKit/CKComponentSubclass.h>

@implementation CKMTextLabelComponent {
  CKMTextLabelComponentAttrs _attrs;
}

+ (instancetype)newWithTextAttributes:(CKMTextLabelComponentAttrs)attrs
                       viewAttributes:(const CKViewComponentAttributeValueMap &)viewAttributes
                                 size:(CKComponentSize)size
{
  CKMTextLabelComponent *c =
  [super
   newWithView:{
     {[NSTextField class]},
     {
       {@selector(setEditable:), @NO},
       {@selector(setSelectable:), @NO},
       {@selector(setStringValue:), attrs.text ?: @""},
       {@selector(setBackgroundColor:), attrs.backgroundColor},
       {@selector(setBezeled:), @NO},
       {@selector(setAlignment:), @(attrs.alignment)},
       {@selector(setFont:), attrs.font},
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
    CGFLOAT_MAX
  };

  NSFont *font = _attrs.font ?: [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSRegularControlSize]];
  
  NSDictionary *attributes = @{ NSFontAttributeName: font };

  CGRect rect = [_attrs.text ckm_boundingRectWithSize:constraint
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:attributes];

  rect = UIEdgeInsetsInsetRect(rect, {.left = -3, .right = -3});

  return {self, constrainedSize.clamp(rect.size)};
}

@end