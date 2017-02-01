//
//  CKUniqueComponent.m
//  ComponentKit
//
//  Created by Oliver Rickard on 2/1/17.
//
//

#import "CKUniqueComponent.h"

#import "CKComponentScope.h"

@implementation CKUniqueComponent

+ (instancetype)newWithIdentifier:(id)identifier
                        component:(CKComponent *)component
{
  CKComponentScope scope(self, identifier);
  return [super newWithComponent:component];
}

@end
