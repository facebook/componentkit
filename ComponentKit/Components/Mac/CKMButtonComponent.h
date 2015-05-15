// Copyright 2004-present Facebook. All Rights Reserved.

#import <ComponentKit/CKComponent.h>

@interface CKMButtonComponent : CKComponent

+ (instancetype)newWithTitle:(NSString *)title target:(id)target action:(CKComponentAction)action;

@end