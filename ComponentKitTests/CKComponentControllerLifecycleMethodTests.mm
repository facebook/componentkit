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

#import <ComponentKitTestHelpers/CKComponentLifecycleTestController.h>

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentController.h>
#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/CKComponentScope.h>
#import <ComponentKit/CKComponentSubclass.h>

@interface CKComponentControllerLifecycleMethodTests : XCTestCase <CKComponentProvider>
@end

struct CKLifecycleMethodCounts {
  NSUInteger willMount;
  NSUInteger didMount;
  NSUInteger willRemount;
  NSUInteger didRemount;
  NSUInteger willUnmount;
  NSUInteger didUnmount;

  NSString *description() const
  {
    return [NSString stringWithFormat:@"willMount:%lu didMount:%lu willRemount:%lu didRemount:%lu willUnmount:%lu didUnmount:%lu",
            (unsigned long)willMount, (unsigned long)didMount, (unsigned long)willRemount,
            (unsigned long)didRemount, (unsigned long)willUnmount, (unsigned long)didUnmount];
  }

  bool operator==(const CKLifecycleMethodCounts &other) const
  {
    return willMount == other.willMount && didMount == other.didMount
    && willRemount == other.willRemount && didRemount == other.didRemount
    && willUnmount == other.willUnmount && didUnmount == other.didUnmount;
  }
};

@interface CKLifecycleComponentController : CKComponentController
{
@public
  CKLifecycleMethodCounts _counts;
}
@end

@interface CKLifecycleComponent : CKComponent
- (void)updateStateToIncludeNewAttribute;
@end

@implementation CKComponentControllerLifecycleMethodTests

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [CKLifecycleComponent new];
}

- (void)testThatMountingComponentCallsWillAndDidMount
{
  CKComponentLifecycleTestController *componentLifecycleTestController = [[CKComponentLifecycleTestController alloc] initWithComponentProvider:[self class]
                                                                                                                             sizeRangeProvider:nil];

  const CKComponentLifecycleTestControllerState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                    constrainedSize:{{0,0}, {100, 100}}
                                                                                                            context:nil];
  [componentLifecycleTestController updateWithState:state];

  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];
  CKLifecycleComponentController *controller = (CKLifecycleComponentController *)state.componentLayout.component.controller;
  const CKLifecycleMethodCounts actual = controller->_counts;
  const CKLifecycleMethodCounts expected = {.willMount = 1, .didMount = 1};
  XCTAssertTrue(actual == expected, @"Expected %@ but got %@", expected.description(), actual.description());
}

- (void)testThatUnmountingComponentCallsWillAndDidUnmount
{
  CKComponentLifecycleTestController *componentLifecycleTestController = [[CKComponentLifecycleTestController alloc] initWithComponentProvider:[self class]
                                                                                                                             sizeRangeProvider:nil];

  const CKComponentLifecycleTestControllerState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                    constrainedSize:{{0,0}, {100, 100}}
                                                                                                            context:nil];
  [componentLifecycleTestController updateWithState:state];

  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];
  [componentLifecycleTestController detachFromView];

  CKLifecycleComponentController *controller = (CKLifecycleComponentController *)state.componentLayout.component.controller;
  const CKLifecycleMethodCounts actual = controller->_counts;
  const CKLifecycleMethodCounts expected = {.willMount = 1, .didMount = 1, .willUnmount = 1, .didUnmount = 1};
  XCTAssertTrue(actual == expected, @"Expected %@ but got %@", expected.description(), actual.description());
}

- (void)testThatUpdatingComponentWhileMountedCallsWillAndDidRemount
{
  CKComponentLifecycleTestController *componentLifecycleTestController = [[CKComponentLifecycleTestController alloc] initWithComponentProvider:[self class]
                                                                                                                             sizeRangeProvider:nil];

  const CKComponentLifecycleTestControllerState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                    constrainedSize:{{0,0}, {100, 100}}
                                                                                                            context:nil];
  [componentLifecycleTestController updateWithState:state];

  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];
  CKLifecycleComponent *component = (CKLifecycleComponent *)state.componentLayout.component;
  [component updateStateToIncludeNewAttribute];

  CKLifecycleComponentController *controller = (CKLifecycleComponentController *)component.controller;
  const CKLifecycleMethodCounts actual = controller->_counts;
  const CKLifecycleMethodCounts expected = {.willMount = 1, .didMount = 1, .willRemount = 1, .didRemount = 1};
  XCTAssertTrue(actual == expected, @"Expected %@ but got %@", expected.description(), actual.description());
}

- (void)testThatUpdatingComponentWhileNotMountedCallsNothing
{
  CKComponentLifecycleTestController *componentLifecycleTestController = [[CKComponentLifecycleTestController alloc] initWithComponentProvider:[self class]
                                                                                                                             sizeRangeProvider:nil];

  const CKComponentLifecycleTestControllerState state = [componentLifecycleTestController prepareForUpdateWithModel:nil
                                                                                                    constrainedSize:{{0,0}, {100, 100}}
                                                                                                            context:nil];
  [componentLifecycleTestController updateWithState:state];

  UIView *view = [UIView new];
  [componentLifecycleTestController attachToView:view];
  [componentLifecycleTestController detachFromView];

  CKLifecycleComponent *component = (CKLifecycleComponent *)state.componentLayout.component;
  CKLifecycleComponentController *controller = (CKLifecycleComponentController *)component.controller;
  {
    const CKLifecycleMethodCounts actual = controller->_counts;
    const CKLifecycleMethodCounts expected = {.willMount = 1, .didMount = 1, .willUnmount = 1, .didUnmount = 1};
    XCTAssertTrue(actual == expected, @"Expected %@ but got %@", expected.description(), actual.description());
  }

  controller->_counts = {};
  [component updateStateToIncludeNewAttribute];
  {
    const CKLifecycleMethodCounts actual = controller->_counts;
    const CKLifecycleMethodCounts expected = {};
    XCTAssertTrue(actual == expected, @"Expected %@ but got %@", expected.description(), actual.description());
  }

  [componentLifecycleTestController attachToView:view];
  {
    const CKLifecycleMethodCounts actual = controller->_counts;
    const CKLifecycleMethodCounts expected = {.willMount = 1, .didMount = 1};
    XCTAssertTrue(actual == expected, @"Expected %@ but got %@", expected.description(), actual.description());
  }
}

@end

@implementation CKLifecycleComponent

+ (id)initialState
{
  return @NO;
}

+ (instancetype)new
{
  CKComponentScope scope(self);
  CKViewComponentAttributeValueMap attrs;
  if ([scope.state() boolValue]) {
    attrs.insert({@selector(setBackgroundColor:), [UIColor redColor]});
  }
  return [super newWithView:{[UIView class], std::move(attrs)} size:{}];
}

- (void)updateStateToIncludeNewAttribute
{
  [self updateState:^(id oldState){
    return @YES;
  } mode:CKUpdateModeSynchronous];
}
@end

@implementation CKLifecycleComponentController

- (void)willMount { [super willMount]; _counts.willMount++; }
- (void)didMount { [super didMount]; _counts.didMount++; }
- (void)willRemount { [super willRemount]; _counts.willRemount++; }
- (void)didRemount { [super didRemount]; _counts.didRemount++; }
- (void)willUnmount { [super willUnmount]; _counts.willUnmount++; }
- (void)didUnmount { [super didUnmount]; _counts.didUnmount++; }

@end
