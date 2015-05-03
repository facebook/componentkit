/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <XCTest/XCTest.h>

#import "CKComponent.h"
#import "CKComponentAnimation.h"
#import "CKComponentLifecycleManager.h"
#import "CKComponentProvider.h"
#import "CKCompositeComponent.h"
#import "CKStaticLayoutComponent.h"

@interface CKComponentViewContextTests : XCTestCase
@end

@interface CKSingleViewComponentProvider : NSObject <CKComponentProvider>
@end

/** Centers a 50x50 subcomponent inside self, which is 100x100. Neither has a view. */
@interface CKNestedComponent : CKCompositeComponent
@property (nonatomic, strong) CKComponent *subcomponent;
@end
@interface CKNestedComponentProvider : NSObject <CKComponentProvider>
@end

@implementation CKComponentViewContextTests

static const CKSizeRange size = {{100, 100}, {100, 100}};

- (void)testMountingComponentWithViewExposesViewContextWithTheCreatedView
{
  CKComponentLifecycleManager *clm =
  [[CKComponentLifecycleManager alloc] initWithComponentProvider:[CKSingleViewComponentProvider class]];
  CKComponentLifecycleManagerState state = [clm prepareForUpdateWithModel:nil constrainedSize:size context:nil];
  [clm updateWithState:state];
  CKComponent *component = state.layout.component;

  UIView *rootView = [[UIView alloc] initWithFrame:{{0,0}, size.max}];
  [clm attachToView:rootView];

  UIImageView *createdView = [[rootView subviews] firstObject];
  XCTAssertTrue([createdView isKindOfClass:[UIImageView class]], @"Expected image view but got %@", createdView);

  CKComponentViewContext context = [component viewContext];
  XCTAssertTrue(context.view == createdView, @"Expected view context to be the created view");
  XCTAssertTrue(CGRectEqualToRect(context.frame, CGRectMake(0, 0, 100, 100)), @"Expected frame to match");
}

- (void)testMountingComponentWithViewAndNestedComponentWithoutViewExposesViewContextWithSubcomponentFrameInOuterView
{
  CKComponentLifecycleManager *clm =
  [[CKComponentLifecycleManager alloc] initWithComponentProvider:[CKNestedComponentProvider class]];
  CKComponentLifecycleManagerState state = [clm prepareForUpdateWithModel:nil constrainedSize:size context:nil];
  [clm updateWithState:state];
  CKNestedComponent *component = (CKNestedComponent *)state.layout.component;

  UIView *rootView = [[UIView alloc] initWithFrame:{{0,0}, size.max}];
  [clm attachToView:rootView];

  CKComponent *subcomponent = component.subcomponent;
  CKComponentViewContext context = [subcomponent viewContext];
  XCTAssertTrue(context.view == rootView, @"Expected view context to be the root view since neither component created a view");
  XCTAssertTrue(CGRectEqualToRect(context.frame, CGRectMake(25, 25, 50, 50)), @"Expected frame to match");
}

@end

@implementation CKSingleViewComponentProvider
+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [CKComponent newWithView:{[UIImageView class]} size:{}];
}
@end

@implementation CKNestedComponentProvider
+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [CKNestedComponent new];
}
@end

@implementation CKNestedComponent

+ (instancetype)new
{
  CKComponent *subcomponent = [CKComponent newWithView:{} size:{50, 50}];
  CKNestedComponent *c =
  [super newWithComponent:
   [CKStaticLayoutComponent
    newWithView:{}
    size:{100, 100}
    children:{
      {{25, 25}, subcomponent}
    }]];
  c->_subcomponent = subcomponent;
  return c;
}

@end
