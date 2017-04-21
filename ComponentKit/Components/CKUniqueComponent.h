//
//  CKUniqueComponent.h
//  ComponentKit
//
//  Created by Oliver Rickard on 2/1/17.
//
//

#import <ComponentKit/CKCompositeComponent.h>

@interface CKUniqueComponent : CKCompositeComponent

+ (instancetype)newWithIdentifier:(id)identifier
                        component:(CKComponent *)component;

@end
