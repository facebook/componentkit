/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <ComponentKitTestHelpers/CKTestActionComponent.h>

#import <ComponentKit/CKAction.h>
#import <ComponentKit/CKCompositeComponent.h>
#import <ComponentKit/CKComponentSubclass.h>

@interface CKComponentAccessibilityCustomActionsAttributeTests : XCTestCase
@end

@implementation CKComponentAccessibilityCustomActionsAttributeTests

- (void)testCustomActionsAttribute
{
  __block CKComponent *actionSender = nil;
  
  CKComponent *controlComponent =
  CK::ComponentBuilder()
      .viewClass([UIView class])
      .attribute(CKComponentAccessibilityCustomActionsAttribute({{@"Test", @selector(testNoArgumentAction:)}}))
      .build();
  
  CKTestActionComponent *outerComponent =
  [CKTestActionComponent
   newWithSingleArgumentBlock:^(CKComponent *sender, id context) { }
   secondArgumentBlock:^(CKComponent *sender, id obj1, id obj2) { }
   primitiveArgumentBlock:^(CKComponent *sender, int value) { }
   noArgumentBlock:^(CKComponent *sender) { actionSender = sender; }
   component:controlComponent];
  
  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView, nil, nil).mountedComponents;
  
  UIAccessibilityCustomAction *action = controlComponent.viewContext.view.accessibilityCustomActions.firstObject;
  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[action.target methodSignatureForSelector:action.selector]];
  invocation.selector = action.selector;
  [invocation invokeWithTarget:action.target];
  XCTAssert(actionSender == controlComponent, @"Sender should be the component with the attribute");
  
  CKUnmountComponents(mountedComponents);
}

- (void)testCustomActionsOrderIsPreserved
{
  __block CKComponent *actionSender = nil;
  
  CKComponent *controlComponent =
  CK::ComponentBuilder()
      .viewClass([UIView class])
      .attribute(CKComponentAccessibilityCustomActionsAttribute({
       {@"Test", @selector(testAction:context:)},
       {@"Test 2", @selector(testAction:context:)},
       {@"Test 3", @selector(testAction:context:)},
     }))
      .build();
  
  CKTestActionComponent *outerComponent =
  [CKTestActionComponent
   newWithSingleArgumentBlock:^(CKComponent *sender, id context) { actionSender = sender; }
   secondArgumentBlock:^(CKComponent *sender, id obj1, id obj2) { }
   primitiveArgumentBlock:^(CKComponent *sender, int value) { }
   noArgumentBlock:^(CKComponent *sender) { }
   component:controlComponent];
  
  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView, nil, nil).mountedComponents;
  
  UIAccessibilityCustomAction *action = [controlComponent.viewContext.view.accessibilityCustomActions objectAtIndex:2];
  XCTAssertEqualObjects(action.name, @"Test 3");
  
  CKUnmountComponents(mountedComponents);
}

- (void)testCustomActionIsNotAddedForNullAction
{
  __block CKComponent *actionSender = nil;
  
  CKComponent *controlComponent =
  CK::ComponentBuilder()
      .viewClass([UIView class])
      .attribute(CKComponentAccessibilityCustomActionsAttribute({
       {@"Test", nullptr},
       {@"Test 2", @selector(testAction:context:)},
     }))
      .build();
  
  CKTestActionComponent *outerComponent =
  [CKTestActionComponent
   newWithSingleArgumentBlock:^(CKComponent *sender, id context) { actionSender = sender; }
   secondArgumentBlock:^(CKComponent *sender, id obj1, id obj2) { }
   primitiveArgumentBlock:^(CKComponent *sender, int value) { }
   noArgumentBlock:^(CKComponent *sender) { }
   component:controlComponent];
  
  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView, nil, nil).mountedComponents;
  
  XCTAssertEqual(controlComponent.viewContext.view.accessibilityCustomActions.count, 1);
  
  CKUnmountComponents(mountedComponents);
}

@end
