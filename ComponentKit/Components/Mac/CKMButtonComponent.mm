// Copyright 2004-present Facebook. All Rights Reserved.

#import "CKMButtonComponent.h"

#import <ComponentKit/CKComponentSubclass.h>

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
  NSDictionary *attributes = @{
                               NSFontAttributeName: [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSRegularControlSize]]
                               };
  CGSize size = [_title sizeWithAttributes:attributes];
  size.height = 24.0;
  size.width += 14.0 * 2;  // for padding around button's title
  size.width = ceil(size.width);
  return {self, constrainedSize.clamp(size)};
}

@end