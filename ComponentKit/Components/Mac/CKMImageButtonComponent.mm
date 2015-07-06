// Copyright 2004-present Facebook. All Rights Reserved.

#import "CKMImageButtonComponent.h"

#import <ComponentKit/CKComponentSubclass.h>

@implementation CKMImageButtonComponent

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view
                      image:(NSImage *)image
                       size:(CKComponentSize)size
{
  CKViewComponentAttributeValueMap allAttributes {
    {@selector(setBordered:), @NO},
    {@selector(setTitle:), @""},
    {@selector(setImage:), image},
  };

  allAttributes.insert(view.attributes()->begin(), view.attributes()->end());

  return [self
          newWithView:{
            {[NSButton class]},
            std::move(allAttributes),
          }
          size:size];
}

@end