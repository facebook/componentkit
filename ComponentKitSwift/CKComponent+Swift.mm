//
//  CKComponent+Swift.m
//  ComponentKit
//
//  Created by Oliver Rickard on 12/11/16.
//
//

#import "CKComponent+Swift.h"

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentInternal.h>

@implementation CKComponent (Swift)

- (instancetype)initWithViewRef:(CKComponentViewConfigurationRef *)view
{
  CKComponentViewConfiguration config = *reinterpret_cast<CKComponentViewConfiguration *>(view);
  return [self initWithView:config
                       size:{}];
}

@end
