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

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKCompositeComponent.h>
#import <ComponentKit/CKComponentController.h>
#import <ComponentKit/CKFlexboxComponent.h>
#import <ComponentKit/CKRenderComponent.h>
#import <ComponentKit/CKRenderWithChildrenComponent.h>

// Leaf render component with component controller.
@interface CKTestChildRenderComponent : CKRenderComponent
@property (nonatomic, assign) BOOL parentHasStateUpdate;
@end

// Render component with a `CKTestChildRenderComponent` child component.
@interface CKTestRenderComponent : CKRenderComponent
@property (nonatomic, assign) BOOL didReuseComponent;
@property (nonatomic, assign) NSUInteger renderCalledCounter;
@property (nonatomic, assign) NSUInteger identifier;
@property (nonatomic, strong) CKTestChildRenderComponent *childComponent;
+ (instancetype)newWithIdentifier:(NSUInteger)identifier;
@end

// CKCompositeComponent with scope and state.
@interface CKCompositeComponentWithScopeAndState : CKCompositeComponent
@end

// An helper class that inherits from 'CKRenderWithChildrenComponent'; render the component froms the initializer
@interface CKTestRenderWithChildrenComponent : CKRenderWithChildrenComponent
+ (instancetype)newWithChildren:(std::vector<CKComponent *>)children;
@end

// Component controller
@interface CKTestChildRenderComponentController : CKComponentController
@end
