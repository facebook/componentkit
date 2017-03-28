//
//  CKScopedComponentController.h
//  ComponentKit
//
//  Created by Oliver Rickard on 3/27/17.
//
//

#import <Foundation/Foundation.h>

@protocol CKScopedComponent;

@protocol CKScopedComponentController <NSObject>

- (instancetype)initWithComponent:(id<CKScopedComponent>)component;

@end
