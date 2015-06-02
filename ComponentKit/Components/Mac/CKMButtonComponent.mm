// Copyright 2004-present Facebook. All Rights Reserved.

#import "CKMButtonComponent.h"

#import <ComponentKit/CKComponentSubclass.h>

#import "NSString+CKMTextCache.h"

@implementation CKMButtonComponent {
  NSString *_title;
}

+ (instancetype)newWithTitle:(NSString *)title target:(id)target action:(CKComponentAction)action
{
  static const CKComponentViewAttribute buttonActionAttribute = {
    "CKMButtonComponentActionAttribute",
    ^(NSButton *aButton, id value) {
      aButton.action = NSSelectorFromString(value);
    }
  };
  
  CKMButtonComponent *c =
  [super
   newWithView:{
     {[NSButton class]},
     {
       {@selector(setButtonType:), @(NSMomentaryLightButton)},
       {@selector(setBezelStyle:), @(NSRoundedBezelStyle)},
       {@selector(setTitle:), title},
       {@selector(setTarget:), target},
       {buttonActionAttribute, NSStringFromSelector(action)}
     },
   }
   size:{}];
  if (c) {
    c->_title = title;
  }
  
  return c;
}

- (CKComponentLayout)computeLayoutThatFits:(CKSizeRange)constrainedSize
{
  const CGSize constraint = {
    isinf(constrainedSize.max.width) ? CGFLOAT_MAX : constrainedSize.max.width,
    CGFLOAT_MAX
  };

  NSDictionary *attributes = @{
                               NSFontAttributeName: [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSRegularControlSize]]
                               };
  CGRect rect = [_title ckm_boundingRectWithSize:constraint
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:attributes];

  rect.size.height = 24.0;
  rect.size.width += 14.0 * 2;  // for padding around button's title
  rect.size.width = ceil(rect.size.width);
  return {self, constrainedSize.clamp(rect.size)};
}

@end
