// Copyright 2004-present Facebook. All Rights Reserved.

#import <ComponentKit/CKComponent.h>

@interface CKMImageButtonComponent : CKComponent

+ (instancetype)newWithView:(const CKComponentViewConfiguration &)view
                      image:(NSImage *)image
                       size:(CKComponentSize)size;

@end