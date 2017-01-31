//
//  CKScrollComponent.h
//  ComponentKit
//
//  Created by Oliver Rickard on 1/31/17.
//
//

#import <ComponentKit/CKComponent.h>

@interface CKScrollComponent : CKComponent

+ (instancetype)newWithAttributes:(const CKViewComponentAttributeValueMap &)attributes
                        component:(CKComponent *)component;

@end
