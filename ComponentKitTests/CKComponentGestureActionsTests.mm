/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <UIKit/UIGestureRecognizerSubclass.h>
#import <XCTest/XCTest.h>

#import <OCMock/OCMock.h>

#import "CKComponent.h"
#import "CKComponentGestureActions.h"
#import "CKComponentGestureActionsInternal.h"
#import "CKComponentViewInterface.h"

@interface CKFakeActionComponent : CKComponent
- (void)test:(CKComponent *)sender;
@property (nonatomic, assign) BOOL receivedTest;
@end

@interface CKComponentGestureActionsTests : XCTestCase
@end

@implementation CKComponentGestureActionsTests

- (void)testThatApplyingATapRecognizerAttributeAddsRecognizerToViewAndUnApplyingItRemovesIt
{
  CKComponentViewAttributeValue attr = CKComponentTapGestureAttribute(@selector(test));
  UIView *view = [[UIView alloc] init];

  attr.first.applicator(view, attr.second);
  XCTAssertEqual([view.gestureRecognizers count], 1u, @"Expected tap gesture recognizer to be attached");

  attr.first.unapplicator(view, attr.second);
  XCTAssertEqual([view.gestureRecognizers count], 0u, @"Expected tap gesture recognizer to be removed");
}

- (void)testThatTapRecognizerHasComponentActionStoredOnIt
{
  CKComponentViewAttributeValue attr = CKComponentTapGestureAttribute(@selector(test));
  UIView *view = [[UIView alloc] init];

  attr.first.applicator(view, attr.second);
  UITapGestureRecognizer *recognizer = [view.gestureRecognizers firstObject];
  XCTAssertEqual([recognizer ck_componentAction], @selector(test), @"Expected ck_componentAction to be set on the GR");

  attr.first.unapplicator(view, attr.second);
}

- (void)testThatTappingAViewSendsComponentAction
{
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
  id mockComponent = [OCMockObject mockForClass:[CKComponent class]];
  CKFakeActionComponent *fakeParentComponent = [CKFakeActionComponent new];
  [[[mockComponent stub] andReturn:fakeParentComponent] nextResponder];
  [[[mockComponent stub] andReturn:fakeParentComponent] targetForAction:[OCMArg anySelector] withSender:[OCMArg any]];
  view.ck_component = mockComponent;

  CKComponentViewAttributeValue attr = CKComponentTapGestureAttribute(@selector(test:));
  attr.first.applicator(view, attr.second);

  // Simulating touches is a PITA, but we can hack it by accessing the CKComponentGestureActionForwarder directly.
  UIGestureRecognizer *tapRecognizer = [view.gestureRecognizers firstObject];
  [[CKComponentGestureActionForwarder sharedInstance] handleGesture:tapRecognizer];
  XCTAssertTrue([fakeParentComponent receivedTest], @"Expected handler to be called");
}

@end

@implementation CKFakeActionComponent
- (void)test:(CKComponent *)sender
{
  _receivedTest = YES;
}
@end
