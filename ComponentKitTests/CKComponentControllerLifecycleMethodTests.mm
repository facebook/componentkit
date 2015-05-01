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

#import <ComponentKitTestLib/CKComponentTestRootScope.h>

#import "CKComponent.h"
#import "CKComponentController.h"
#import "CKComponentLifecycleManager.h"
#import "CKComponentProvider.h"
#import "CKComponentScope.h"
#import "CKComponentSubclass.h"

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
@property (nonatomic, weak) CKLifecycleComponentController *controller;
- (void)updateStateToIncludeNewAttribute;
@end

@implementation CKComponentControllerLifecycleMethodTests

+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [CKLifecycleComponent new];
}

- (void)testThatMountingComponentCallsWillAndDidMount
{
  CKComponentLifecycleManager *clm = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class]];

  CKComponentLifecycleManagerState state = [clm prepareForUpdateWithModel:nil constrainedSize:{{0,0}, {100, 100}} context:nil];
  [clm updateWithState:state];

  UIView *view = [[UIView alloc] init];
  [clm attachToView:view];
  CKLifecycleComponentController *controller = ((CKLifecycleComponent *)state.layout.component).controller;
  const CKLifecycleMethodCounts actual = controller->_counts;
  const CKLifecycleMethodCounts expected = {.willMount = 1, .didMount = 1};
  XCTAssertTrue(actual == expected, @"Expected %@ but got %@", expected.description(), actual.description());
}

- (void)testThatUnmountingComponentCallsWillAndDidUnmount
{
  CKComponentLifecycleManager *clm = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class]];

  CKComponentLifecycleManagerState state = [clm prepareForUpdateWithModel:nil constrainedSize:{{0,0}, {100, 100}} context:nil];
  [clm updateWithState:state];

  UIView *view = [[UIView alloc] init];
  [clm attachToView:view];
  [clm detachFromView];

  CKLifecycleComponentController *controller = ((CKLifecycleComponent *)state.layout.component).controller;
  const CKLifecycleMethodCounts actual = controller->_counts;
  const CKLifecycleMethodCounts expected = {.willMount = 1, .didMount = 1, .willUnmount = 1, .didUnmount = 1};
  XCTAssertTrue(actual == expected, @"Expected %@ but got %@", expected.description(), actual.description());
}

- (void)testThatUpdatingComponentWhileMountedCallsWillAndDidRemount
{
  CKComponentLifecycleManager *clm = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class]];

  CKComponentLifecycleManagerState state = [clm prepareForUpdateWithModel:nil constrainedSize:{{0,0}, {100, 100}} context:nil];
  [clm updateWithState:state];

  UIView *view = [[UIView alloc] init];
  [clm attachToView:view];
  CKLifecycleComponent *component = (CKLifecycleComponent *)state.layout.component;
  [component updateStateToIncludeNewAttribute];

  CKLifecycleComponentController *controller = component.controller;
  const CKLifecycleMethodCounts actual = controller->_counts;
  const CKLifecycleMethodCounts expected = {.willMount = 1, .didMount = 1, .willRemount = 1, .didRemount = 1};
  XCTAssertTrue(actual == expected, @"Expected %@ but got %@", expected.description(), actual.description());
}

- (void)testThatUpdatingComponentWhileNotMountedCallsNothing
{
  CKComponentLifecycleManager *clm = [[CKComponentLifecycleManager alloc] initWithComponentProvider:[self class]];

  CKComponentLifecycleManagerState state = [clm prepareForUpdateWithModel:nil constrainedSize:{{0,0}, {100, 100}} context:nil];
  [clm updateWithState:state];

  UIView *view = [[UIView alloc] init];
  [clm attachToView:view];
  [clm detachFromView];

  CKLifecycleComponent *component = (CKLifecycleComponent *)state.layout.component;
  CKLifecycleComponentController *controller = component.controller;
  {
    const CKLifecycleMethodCounts actual = controller->_counts;
    const CKLifecycleMethodCounts expected = {.willMount = 1, .didMount = 1, .willUnmount = 1, .didUnmount = 1};
    XCTAssertTrue(actual == expected, @"Expected %@ but got %@", expected.description(), actual.description());
  }

  controller->_counts = {}; // Reset all to zero
  [component updateStateToIncludeNewAttribute];
  {
    const CKLifecycleMethodCounts actual = controller->_counts;
    const CKLifecycleMethodCounts expected = {};
    XCTAssertTrue(actual == expected, @"Expected %@ but got %@", expected.description(), actual.description());
  }

  [clm attachToView:view];
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
  CKComponentScope scope(self); // components with controllers must have a scope
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
  }];
}
@end

@implementation CKLifecycleComponentController

- (void)didUpdateComponent
{
  [super didUpdateComponent];
  [(CKLifecycleComponent *)[self component] setController:self];
}

- (void)willMount { [super willMount]; _counts.willMount++; }
- (void)didMount { [super didMount]; _counts.didMount++; }
- (void)willRemount { [super willRemount]; _counts.willRemount++; }
- (void)didRemount { [super didRemount]; _counts.didRemount++; }
- (void)willUnmount { [super willUnmount]; _counts.willUnmount++; }
- (void)didUnmount { [super didUnmount]; _counts.didUnmount++; }

@end
