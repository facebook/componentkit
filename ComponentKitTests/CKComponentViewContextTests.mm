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

#import <ComponentKitTestHelpers/CKComponentLifecycleTestHelper.h>

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentAnimation.h>
#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/CKCompositeComponent.h>
#import <ComponentKit/CKStaticLayoutComponent.h>

@interface CKComponentViewContextTests : XCTestCase
@end

@interface CKNestedComponent : CKCompositeComponent
@property (nonatomic, strong) CKComponent *subcomponent;

+ (instancetype)new;

@end

@implementation CKComponentViewContextTests

static CKComponent *singleViewComponentProvider(id<NSObject> model, id<NSObject>context)
{
  return CK::ComponentBuilder()
             .viewClass([UIImageView class])
             .build();
}

static CKComponent *nestedComponentProvider(id<NSObject> model, id<NSObject>context)
{
  return [CKNestedComponent new];
}

static const CKSizeRange size = {{100, 100}, {100, 100}};

- (void)testMountingComponentWithViewExposesViewContextWithTheCreatedView
{
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:singleViewComponentProvider
                                                                                                                             sizeRangeProvider:nil];
  const CKComponentLifecycleTestHelperState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                    constrainedSize:size
                                                                                                            context:nil];
  [componentLifecycleTestController updateWithState:state];
  CKComponent *component = (CKComponent *)state.componentLayout.component;

  UIView *rootView = [[UIView alloc] initWithFrame:{{0,0}, size.max}];
  [componentLifecycleTestController attachToView:rootView];

  UIImageView *createdView = [[rootView subviews] firstObject];
  XCTAssertTrue([createdView isKindOfClass:[UIImageView class]], @"Expected image view but got %@", createdView);

  CKComponentViewContext context = [component viewContext];
  XCTAssertTrue(context.view == createdView, @"Expected view context to be the created view");
  XCTAssertTrue(CGRectEqualToRect(context.frame, CGRectMake(0, 0, 100, 100)), @"Expected frame to match");
}

- (void)testMountingComponentWithViewAndNestedComponentWithoutViewExposesViewContextWithSubcomponentFrameInOuterView
{
  CKComponentLifecycleTestHelper *componentLifecycleTestController = [[CKComponentLifecycleTestHelper alloc] initWithComponentProvider:nestedComponentProvider
                                                                                                                             sizeRangeProvider:nil];
  const CKComponentLifecycleTestHelperState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                    constrainedSize:size
                                                                                                            context:nil];
  [componentLifecycleTestController updateWithState:state];
  CKNestedComponent *component = (CKNestedComponent *)state.componentLayout.component;

  UIView *rootView = [[UIView alloc] initWithFrame:{{0,0}, size.max}];
  [componentLifecycleTestController attachToView:rootView];

  CKComponent *subcomponent = component.subcomponent;
  CKComponentViewContext context = [subcomponent viewContext];
  XCTAssertTrue(context.view == rootView, @"Expected view context to be the root view since neither component created a view");
  XCTAssertTrue(CGRectEqualToRect(context.frame, CGRectMake(25, 25, 50, 50)), @"Expected frame to match");
}

@end

@implementation CKNestedComponent

+ (instancetype)new
{
  CKComponent *subcomponent = CK::ComponentBuilder()
                                  .width(50)
                                  .height(50)
                                  .build();
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
