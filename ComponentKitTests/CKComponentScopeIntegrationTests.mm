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

#import <ComponentKit/CKComponentController.h>
#import <ComponentKit/CKBuildComponent.h>
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKComponentScopeHandle.h>
#import <ComponentKit/CKThreadLocalComponentScope.h>
#import <ComponentKit/CKFlexboxComponent.h>
#import <ComponentKit/CKComponentScopeRootFactory.h>

@interface TestScopeIntegrationComponent : CKComponent
+ (instancetype)newWithIdentifier:(NSString *)identifier title:(NSString *)title;
@end

@interface TestScopeIntegrationComponentController : CKComponentController
@end

@interface CKComponentScopeIntegrationTests : XCTestCase
@end

@implementation CKComponentScopeIntegrationTests

- (void)testSiblingComponentsWithSameTypeGetCorrectControllerAndState_WithoutScopeIdentifiers
{
  __block TestScopeIntegrationComponent *component1;
  __block TestScopeIntegrationComponent *component2;

  auto const state1 = @"1";
  auto const state2 = @"2";

  auto const c = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, ^{
    component1 = [TestScopeIntegrationComponent newWithIdentifier:nil title:state1];
    component2 = [TestScopeIntegrationComponent newWithIdentifier:nil title:state2];
    return CK::FlexboxComponentBuilder()
               .child(component1)
               .child(component2)
               .build();
  });

  [self verifyComponentsHasCorrectStateAndController:component1 component2:component2 state1:state1 state2:state2];
}

- (void)testSiblingComponentsWithSameTypeGetCorrectControllerAndState_WithIdenticalScopeIdentifiers
{
  __block TestScopeIntegrationComponent *component1;
  __block TestScopeIntegrationComponent *component2;

  auto const state1 = @"1";
  auto const state2 = @"2";

  auto const c = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, ^{
    component1 = [TestScopeIntegrationComponent newWithIdentifier:@"1" title:state1];
    component2 = [TestScopeIntegrationComponent newWithIdentifier:@"1" title:state2];
    return CK::FlexboxComponentBuilder()
               .child(component1)
               .child(component2)
               .build();
  });

  [self verifyComponentsHasCorrectStateAndController:component1 component2:component2 state1:state1 state2:state2];
}

- (void)testSiblingComponentsWithSameTypeGetCorrectControllerAndState_WithDifferentScopeIdentifiers
{
  __block TestScopeIntegrationComponent *component1;
  __block TestScopeIntegrationComponent *component2;

  auto const state1 = @"1";
  auto const state2 = @"2";

  auto const c = CKBuildComponent(CKComponentScopeRootWithDefaultPredicates(nil, nil), {}, ^{
    component1 = [TestScopeIntegrationComponent newWithIdentifier:@"1" title:state1];
    component2 = [TestScopeIntegrationComponent newWithIdentifier:@"2" title:state2];
    return CK::FlexboxComponentBuilder()
               .child(component1)
               .child(component2)
               .build();
  });

  [self verifyComponentsHasCorrectStateAndController:component1 component2:component2 state1:state1 state2:state2];
}

#pragma mark - Helpers

// Verify both components have different scope handles, controllers and states.
- (void)verifyComponentsHasCorrectStateAndController:(CKComponent *)component1
                                          component2:(CKComponent *)component2
                                              state1:(id)state1
                                              state2:(id)state2
{
  XCTAssertNotEqual(component1.scopeHandle.globalIdentifier, component2.scopeHandle.globalIdentifier);
  XCTAssertNotEqual(component1.controller, component2.controller);
  XCTAssertEqual(component1.scopeHandle.state, state1);
  XCTAssertEqual(component2.scopeHandle.state, state2);
}

@end

#pragma mark - Test Component

@implementation TestScopeIntegrationComponent
+ (instancetype)newWithIdentifier:(NSString *)identifier title:(NSString *)title
{
  // Create a scope with the identifier and use the title as the initial state.
  CKComponentScope scope(self, identifier, ^{
    return title;
  });
  return [super newWithView:{} size:{}];
}

+ (Class<CKComponentControllerProtocol>)controllerClass
{
  return [TestScopeIntegrationComponentController class];
}
@end

@implementation TestScopeIntegrationComponentController : CKComponentController
@end
