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
#import <ComponentKit/CKRenderLayoutWithChildrenComponent.h>

// Leaf render component with component controller.
struct CKTestChildRenderComponentProps {
  BOOL shouldUseComponentContext;
};

@interface CKTestChildRenderComponent : CKRenderComponent
@property (nonatomic, assign) BOOL parentHasStateUpdate;
@property (nonatomic, assign) NSUInteger computeCalledCounter;
+ (instancetype)newWithProps:(const CKTestChildRenderComponentProps &)props;
@end

// Render component with a `CKTestChildRenderComponent` child component.
struct CKTestRenderComponentProps {
  NSUInteger identifier;
  BOOL shouldUseComponentContext;
};

@interface CKTestRenderComponent : CKRenderComponent
@property (nonatomic, assign) BOOL didReuseComponent;
@property (nonatomic, assign) NSUInteger renderCalledCounter;
@property (nonatomic, assign) NSUInteger identifier;
@property (nonatomic, strong) CKTestChildRenderComponent *childComponent;
+ (instancetype)newWithProps:(const CKTestRenderComponentProps &)props;
@end

// CKCompositeComponent with scope and state.
@interface CKCompositeComponentWithScopeAndState : CKCompositeComponent
@end

// Render component with CKCompositeComponentWithScopeAndState child
@interface CKTestRenderWithNonRenderWithStateChildComponent : CKRenderComponent
@property (nonatomic, assign) BOOL didReuseComponent;
@property (nonatomic, strong) CKCompositeComponentWithScopeAndState *childComponent;
@end

// A helper class that inherits from 'CKRenderLayoutWithChildrenComponent'; render the component froms the initializer
@interface CKTestRenderWithChildrenComponent : CKRenderLayoutWithChildrenComponent
+ (instancetype)newWithChildren:(std::vector<CKComponent *>)children;
@end

// Component controller
@interface CKTestChildRenderComponentController : CKComponentController
@end
