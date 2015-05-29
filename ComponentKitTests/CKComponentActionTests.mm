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

#import "CKComponentAction.h"
#import "CKCompositeComponent.h"
#import "CKComponentSubclass.h"
#import "CKComponentInternal.h"
#import "CKComponentLayout.h"

@interface CKComponentActionTests : XCTestCase
@end

@implementation CKComponentActionTests

- (void)testSendActionIncludesSenderComponent
{
  __block CKComponent *actionSender = nil;

  CKComponent *innerComponent = [CKComponent new];
  CKTestActionComponent *outerComponent =
  [CKTestActionComponent
   newWithBlock:^(CKComponent *sender, id context){ actionSender = sender; }
   component:innerComponent];

  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView, nil, nil);

  CKComponentActionSend(@selector(testAction:context:), innerComponent);

  XCTAssert(actionSender == innerComponent, @"Sender should be inner component");

  [mountedComponents makeObjectsPerformSelector:@selector(unmount)];
}

- (void)testSendActionIncludesContext
{
  __block id actionContext = nil;

  CKComponent *innerComponent = [CKComponent new];
  CKTestActionComponent *outerComponent =
  [CKTestActionComponent
   newWithBlock:^(CKComponent *sender, id context){ actionContext = context; }
   component:innerComponent];

  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView, nil, nil);

  id context = @"context";

  CKComponentActionSend(@selector(testAction:context:), innerComponent, context);

  XCTAssert(actionContext == context, @"Context should match what was passed to CKComponentActionSend");

  [mountedComponents makeObjectsPerformSelector:@selector(unmount)];
}

- (void)testSendActionStartingAtSenderNextResponderReachesParentComponent
{
  __block BOOL outerReceivedTestAction = NO;
  __block BOOL innerReceivedTestAction = NO;

  CKTestActionComponent *innerComponent =
  [CKTestActionComponent
   newWithBlock:^(CKComponent *sender, id context){ innerReceivedTestAction = YES; }
   component:[CKComponent new]];

  CKTestActionComponent *outerComponent =
  [CKTestActionComponent
   newWithBlock:^(CKComponent *sender, id context){ outerReceivedTestAction = YES; }
   component:innerComponent];

  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView, nil, nil);

  CKComponentActionSend(@selector(testAction:context:), innerComponent);

  XCTAssertTrue(outerReceivedTestAction, @"Outer component should have received action sent by inner component");
  XCTAssertFalse(innerReceivedTestAction, @"Inner component should not have received action sent from it");

  [mountedComponents makeObjectsPerformSelector:@selector(unmount)];
}

- (void)testSendActionStartingAtSenderDoesNotReachParentComponent
{
  __block BOOL outerReceivedTestAction = NO;
  __block BOOL innerReceivedTestAction = NO;

  CKTestActionComponent *innerComponent =
  [CKTestActionComponent
   newWithBlock:^(CKComponent *sender, id context){ innerReceivedTestAction = YES; }
   component:[CKComponent new]];

  CKTestActionComponent *outerComponent =
  [CKTestActionComponent
   newWithBlock:^(CKComponent *sender, id context){ outerReceivedTestAction = YES; }
   component:innerComponent];

  // Must be mounted to send actions:
  UIView *rootView = [UIView new];
  NSSet *mountedComponents = CKMountComponentLayout([outerComponent layoutThatFits:{} parentSize:{}], rootView, nil, nil);

  CKComponentActionSend(@selector(testAction:context:), innerComponent, nil, CKComponentActionSendBehaviorStartAtSender);

  XCTAssertFalse(outerReceivedTestAction, @"Outer component should not have received action since inner component did");
  XCTAssertTrue(innerReceivedTestAction, @"Inner component should have received action");

  [mountedComponents makeObjectsPerformSelector:@selector(unmount)];
}

@end
