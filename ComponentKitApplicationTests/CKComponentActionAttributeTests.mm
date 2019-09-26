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
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKComponentLayout.h>

@interface CKComponentActionAttributeTestObject : NSObject
- (void)someAction;
@end

@implementation CKComponentActionAttributeTestObject
- (void)someAction {}
@end

@interface CKComponentActionAttributeTests : XCTestCase
@end

/* This needs to be an application test, otherwise sendActionsForControlEvents: doesn't work since UIApplication is nil */
@implementation CKComponentActionAttributeTests

- (void)testControlActionAttribute
{
  __block CKComponent *actionSender = nil;

  CKComponent *controlComponent =
  CK::ComponentBuilder()
      .viewClass([UIButton class])
      .onTouchUpInside(@selector(testAction:context:))
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

  [(UIControl *)[controlComponent viewContext].view sendActionsForControlEvents:UIControlEventTouchUpInside];
  XCTAssert(actionSender == controlComponent, @"Sender should be the component that created the control");

  CKUnmountComponents(mountedComponents);
}

- (void)testControlActionAttributeWithControlEventSpecified
{
  __block BOOL receivedAction = NO;

  CKComponent *controlComponent =
  CK::ComponentBuilder()
      .viewClass([UIButton class])
      .onControlEvents(UIControlEventValueChanged, @selector(testAction:context:))
      .build();

  CKTestActionComponent *outerComponent =
  [CKTestActionComponent
   newWithSingleArgumentBlock:^(CKComponent *sender, id context){ receivedAction = YES; }
   secondArgumentBlock:^(CKComponent *sender, id obj1, id obj2) { }
   primitiveArgumentBlock:^(CKComponent *sender, int value) { }
   noArgumentBlock:^(CKComponent *sender) { }
   component:controlComponent];

  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView, nil, nil).mountedComponents;

  [(UIControl *)[controlComponent viewContext].view sendActionsForControlEvents:UIControlEventValueChanged];
  XCTAssertTrue(receivedAction, @"Should have received action");

  CKUnmountComponents(mountedComponents);
}

- (void)testMultipleControlActionAttributesWithControlEventSpecified
{
  __block NSUInteger actionCount = 0;

  CKComponent *controlComponent =
  CK::ComponentBuilder()
      .viewClass([UIButton class])
      .onControlEvents(UIControlEventValueChanged, @selector(testAction:context:))
      .onTouchUpInside(@selector(testAction:context:))
      .onControlEvents(UIControlEventTouchDown, @selector(testAction:context:))
      .build();

  CKTestActionComponent *outerComponent =
  [CKTestActionComponent
   newWithSingleArgumentBlock:^(CKComponent *sender, id context){ actionCount++; }
   secondArgumentBlock:^(CKComponent *sender, id obj1, id obj2) { }
   primitiveArgumentBlock:^(CKComponent *sender, int value) { }
   noArgumentBlock:^(CKComponent *sender) { }
   component:controlComponent];

  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView, nil, nil).mountedComponents;

  [(UIControl *)[controlComponent viewContext].view sendActionsForControlEvents:UIControlEventValueChanged];
  XCTAssertTrue(actionCount == 1, @"Should have received action for UIControlEventValueChanged");
  [(UIControl *)[controlComponent viewContext].view sendActionsForControlEvents:UIControlEventTouchUpInside];
  XCTAssertTrue(actionCount == 2, @"Should have received action for UIControlEventTouchUpInside");
  [(UIControl *)[controlComponent viewContext].view sendActionsForControlEvents:UIControlEventTouchDown];
  XCTAssertTrue(actionCount == 3, @"Should have received action for UIControlEventTouchDown");

  CKUnmountComponents(mountedComponents);
}

- (void)testControlActionIsNotSentForControlEventsThatDoNotMatch
{
  __block BOOL receivedAction = NO;

  CKComponent *controlComponent =
  CK::ComponentBuilder()
      .viewClass([UIButton class])
      .onTouchUpInside(@selector(testAction:context:))
      .build();

  CKTestActionComponent *outerComponent =
  [CKTestActionComponent
   newWithSingleArgumentBlock:^(CKComponent *sender, id context){ receivedAction = YES; }
   secondArgumentBlock:^(CKComponent *sender, id obj1, id obj2) { }
   primitiveArgumentBlock:^(CKComponent *sender, int value) { }
   noArgumentBlock:^(CKComponent *sender) { }
   component:controlComponent];

  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView, nil, nil).mountedComponents;

  [(UIControl *)[controlComponent viewContext].view sendActionsForControlEvents:UIControlEventTouchDragEnter];
  XCTAssertFalse(receivedAction, @"Should not have received callback for UIControlEventTouchDragEnter");

  CKUnmountComponents(mountedComponents);
}

- (void)testControlActionIsNotSentForNullAction
{
  __block BOOL receivedAction = NO;

  CKComponent *controlComponent =
  CK::ComponentBuilder()
      .viewClass([UIButton class])
      .onTouchUpInside(nullptr)
      .build();

  CKTestActionComponent *outerComponent =
  [CKTestActionComponent
   newWithSingleArgumentBlock:^(CKComponent *sender, id context){ receivedAction = YES; }
   secondArgumentBlock:^(CKComponent *sender, id obj1, id obj2) { }
   primitiveArgumentBlock:^(CKComponent *sender, int value) { }
   noArgumentBlock:^(CKComponent *sender) { }
   component:controlComponent];

  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView, nil, nil).mountedComponents;

  [(UIControl *)[controlComponent viewContext].view sendActionsForControlEvents:UIControlEventTouchUpInside];
  XCTAssertFalse(receivedAction, @"Should not have received callback if no action specified");

  CKUnmountComponents(mountedComponents);
}

- (void)testControlActionsWithEqualTargetsHasEqualIdentifiers
{
  CKComponentActionAttributeTestObject *obj1 = [CKComponentActionAttributeTestObject new];
  CKComponentViewAttributeValue attr1 = CKComponentActionAttribute({obj1, @selector(someAction)});
  CKComponentViewAttributeValue attr2 = CKComponentActionAttribute({obj1, @selector(someAction)});

  XCTAssertEqual(attr1.first.identifier, attr2.first.identifier);
}

- (void)testControlActionsWithNonEqualTargetsHasNonEqualIdentifiers
{
  CKComponentActionAttributeTestObject *obj1 = [CKComponentActionAttributeTestObject new];
  CKComponentActionAttributeTestObject *obj2 = [CKComponentActionAttributeTestObject new];
  CKComponentViewAttributeValue attr1 = CKComponentActionAttribute({obj1, @selector(someAction)});
  CKComponentViewAttributeValue attr2 = CKComponentActionAttribute({obj2, @selector(someAction)});

  XCTAssertNotEqual(attr1.first.identifier, attr2.first.identifier);
}

- (void)testControlActionsWithRawSelectorActionsHaveEqualIdentifiers
{
  CKComponentViewAttributeValue attr1 = CKComponentActionAttribute(@selector(someAction));
  CKComponentViewAttributeValue attr2 = CKComponentActionAttribute(@selector(someAction));

  XCTAssertEqual(attr1.first.identifier, attr2.first.identifier);
}

@end
