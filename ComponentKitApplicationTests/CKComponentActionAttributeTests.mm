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

#import "CKComponentAction.h"
#import "CKCompositeComponent.h"
#import "CKComponentSubclass.h"
#import "CKComponentInternal.h"
#import "CKComponentLayout.h"

@interface CKTestActionComponent : CKCompositeComponent
/** @param block Executed when "testAction" is invoked on the component */
+ (instancetype)newWithBlock:(void (^)(CKComponent *sender, id context))block
                   component:(CKComponent *)component;
- (void)testAction:(CKComponent *)sender context:(id)context;
@end

@interface CKComponentActionAttributeTests : XCTestCase
@end

/* This needs to be an application test, otherwise sendActionsForControlEvents: doesn't work since UIApplication is nil */
@implementation CKComponentActionAttributeTests

- (void)testControlActionAttribute
{
  __block CKComponent *actionSender = nil;

  CKComponent *controlComponent =
  [CKComponent
   newWithView:{
     [UIButton class],
     {CKComponentActionAttribute(@selector(testAction:context:))}
   }
   size:{}];

  CKTestActionComponent *outerComponent =
  [CKTestActionComponent
   newWithBlock:^(CKComponent *sender, id context){ actionSender = sender; }
   component:controlComponent];

  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView);

  [(UIControl *)[controlComponent viewContext].view sendActionsForControlEvents:UIControlEventTouchUpInside];
  XCTAssert(actionSender == controlComponent, @"Sender should be the component that created the control");

  [mountedComponents makeObjectsPerformSelector:@selector(unmount)];
}

- (void)testControlActionAttributeWithControlEventSpecified
{
  __block BOOL receivedAction = NO;

  CKComponent *controlComponent =
  [CKComponent
   newWithView:{
     [UIButton class],
     {CKComponentActionAttribute(@selector(testAction:context:), UIControlEventValueChanged)}
   }
   size:{}];

  CKTestActionComponent *outerComponent =
  [CKTestActionComponent
   newWithBlock:^(CKComponent *sender, id context){ receivedAction = YES; }
   component:controlComponent];

  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView);

  [(UIControl *)[controlComponent viewContext].view sendActionsForControlEvents:UIControlEventValueChanged];
  XCTAssertTrue(receivedAction, @"Should have received action");

  [mountedComponents makeObjectsPerformSelector:@selector(unmount)];
}

- (void)testControlActionIsNotSentForControlEventsThatDoNotMatch
{
  __block BOOL receivedAction = NO;

  CKComponent *controlComponent =
  [CKComponent
   newWithView:{
     [UIButton class],
     {CKComponentActionAttribute(@selector(testAction:context:))}
   }
   size:{}];

  CKTestActionComponent *outerComponent =
  [CKTestActionComponent
   newWithBlock:^(CKComponent *sender, id context){ receivedAction = YES; }
   component:controlComponent];

  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView);

  [(UIControl *)[controlComponent viewContext].view sendActionsForControlEvents:UIControlEventTouchDragEnter];
  XCTAssertFalse(receivedAction, @"Should not have received callback for UIControlEventTouchDragEnter");

  [mountedComponents makeObjectsPerformSelector:@selector(unmount)];
}

- (void)testControlActionIsNotSentForNullAction
{
  __block BOOL receivedAction = NO;

  CKComponent *controlComponent =
  [CKComponent
   newWithView:{
     [UIButton class],
     {CKComponentActionAttribute(NULL)}
   }
   size:{}];

  CKTestActionComponent *outerComponent =
  [CKTestActionComponent
   newWithBlock:^(CKComponent *sender, id context){ receivedAction = YES; }
   component:controlComponent];

  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView);

  [(UIControl *)[controlComponent viewContext].view sendActionsForControlEvents:UIControlEventTouchUpInside];
  XCTAssertFalse(receivedAction, @"Should not have received callback if no action specified");

  [mountedComponents makeObjectsPerformSelector:@selector(unmount)];
}

@end

@implementation CKTestActionComponent
{
  void (^_block)(CKComponent *, id);
}

+ (instancetype)newWithBlock:(void (^)(CKComponent *sender, id context))block component:(CKComponent *)component
{
  CKTestActionComponent *c = [super newWithComponent:component];
  if (c) {
    c->_block = block;
  }
  return c;
}

- (void)testAction:(CKComponent *)sender context:(id)context
{
  _block(sender, context);
}

@end
