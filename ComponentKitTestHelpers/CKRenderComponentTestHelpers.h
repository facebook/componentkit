/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */
#import <Foundation/Foundation.h>

#import <ComponentKit/CKCompositeComponent.h>
#import <ComponentKit/CKFlexboxComponent.h>
#import <ComponentKit/CKRenderComponent.h>

@interface CKTestChildRenderComponent : CKRenderComponent

@property (nonatomic, assign) BOOL parentHasStateUpdate;

@end

@interface CKTestRenderComponent : CKRenderComponent

@property (nonatomic, assign) BOOL didReuseComponent;
@property (nonatomic, assign) NSUInteger renderCalledCounter;
@property (nonatomic, assign) NSUInteger identifier;
@property (nonatomic, strong) CKTestChildRenderComponent *childComponent;
+ (instancetype)newWithIdentifier:(NSUInteger)identifier;

@end

@interface CKCompositeComponentWithScopeAndState : CKCompositeComponent

@end
