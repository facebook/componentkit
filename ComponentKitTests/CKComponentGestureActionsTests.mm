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

#import <ComponentKit/CKComponent+UIView.h>
#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentGestureActions.h>
#import <ComponentKit/CKComponentGestureActionsInternal.h>

@interface CKFakeActionComponent : CKComponent <UIGestureRecognizerDelegate>
- (void)test:(CKComponent *)sender;
@property (nonatomic, assign) BOOL receivedTest;

@property (nonatomic, assign) BOOL receivedGestureShouldBegin;

@end

@interface CKComponentGestureActionsTests : XCTestCase
@end

@implementation CKComponentGestureActionsTests

- (void)testThatApplyingATapRecognizerAttributeAddsRecognizerToViewAndUnApplyingItRemovesIt
{
  CKComponentViewAttributeValue attr = CKComponentTapGestureAttribute(@selector(test));
  UIView *view = [UIView new];

  attr.first.applicator(view, attr.second);
  XCTAssertEqual([view.gestureRecognizers count], 1u, @"Expected tap gesture recognizer to be attached");

  attr.first.unapplicator(view, attr.second);
  XCTAssertEqual([view.gestureRecognizers count], 0u, @"Expected tap gesture recognizer to be removed");
}

- (void)testThatTapRecognizerHasComponentActionStoredOnIt
{
  CKComponentViewAttributeValue attr = CKComponentTapGestureAttribute(@selector(test));
  UIView *view = [UIView new];

  attr.first.applicator(view, attr.second);
  UITapGestureRecognizer *recognizer = [view.gestureRecognizers firstObject];
  XCTAssertEqual(CKComponentGestureGetAction(recognizer).selector(), @selector(test), @"Expected ck_componentAction to be set on the GR");

  attr.first.unapplicator(view, attr.second);
}

- (void)testThatTappingAViewSendsComponentAction
{
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
  id mockComponent = [OCMockObject mockForClass:[CKComponent class]];
  [[[mockComponent stub] andReturn:@"MyClass"] className];
  CKFakeActionComponent *fakeParentComponent = [CKFakeActionComponent new];
  [[[mockComponent stub] andReturn:fakeParentComponent] nextResponder];
  [[[mockComponent stub] andReturn:fakeParentComponent] targetForAction:[OCMArg anySelector] withSender:[OCMArg any]];
  CKSetMountedComponentForView(view, mockComponent);

  CKComponentViewAttributeValue attr = CKComponentTapGestureAttribute(@selector(test:));
  attr.first.applicator(view, attr.second);

  // Simulating touches is a PITA, but we can hack it by accessing the CKComponentGestureActionForwarder directly.
  UIGestureRecognizer *tapRecognizer = [view.gestureRecognizers firstObject];
  [[CKComponentGestureActionForwarder sharedInstance] handleGesture:tapRecognizer];
  XCTAssertTrue([fakeParentComponent receivedTest], @"Expected handler to be called");
}

- (void)testThatTappingAViewWithoutAComponentAssociatedDoenNotSendComponentAction
{
  //For this test the view does not have any component associated
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
  id mockComponent = [OCMockObject mockForClass:[CKComponent class]];
  CKFakeActionComponent *fakeParentComponent = [CKFakeActionComponent new];
  [[[mockComponent stub] andReturn:fakeParentComponent] nextResponder];
  [[[mockComponent stub] andReturn:fakeParentComponent] targetForAction:[OCMArg anySelector] withSender:[OCMArg any]];

  CKComponentViewAttributeValue attr = CKComponentTapGestureAttribute(@selector(test:));
  attr.first.applicator(view, attr.second);

  UIGestureRecognizer *tapRecognizer = [view.gestureRecognizers firstObject];
  [[CKComponentGestureActionForwarder sharedInstance] handleGesture:tapRecognizer];
  XCTAssertFalse([fakeParentComponent receivedTest], @"Expected handler not to be called");
}


- (void)testThatApplyingATapRecognizerAttributeWithNoActionDoesNotAddRecognizerToView
{
  CKComponentViewAttributeValue attr = CKComponentTapGestureAttribute(nullptr);
  UIView *view = [UIView new];

  attr.first.applicator(view, attr.second);
  XCTAssertEqual([view.gestureRecognizers count], 0u, @"Expected no gesture recognizer");
  attr.first.unapplicator(view, attr.second);
}

- (void)testThatWhenDelegateActionsAreSetTheyProxyToComponent
{

  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
  id mockComponent = [OCMockObject mockForClass:[CKComponent class]];
  [[[mockComponent stub] andReturn:@"MyClass"] className];
  CKFakeActionComponent *fakeParentComponent = [CKFakeActionComponent new];
  [[[mockComponent stub] andReturn:fakeParentComponent] nextResponder];
  [[[mockComponent stub] andReturn:fakeParentComponent] targetForAction:[OCMArg anySelector] withSender:[OCMArg any]];
  CKSetMountedComponentForView(view, mockComponent);

  CKComponentViewAttributeValue attr = CKComponentGestureAttribute([UIPanGestureRecognizer class], nullptr, @selector(test:), {@selector(gestureRecognizerShouldBegin:)});
  attr.first.applicator(view, attr.second);

  UIPanGestureRecognizer *gesture = view.gestureRecognizers.firstObject;
  XCTAssert(gesture.delegate, @"Gesture delegate not set");
  BOOL retVal = [gesture.delegate gestureRecognizerShouldBegin:gesture];

  XCTAssert(fakeParentComponent.receivedGestureShouldBegin, @"Didn't get proxied :(");
  XCTAssert(retVal, @"Should have returned YES");
}

- (void)testThatWithNoDelegateActionsNoDelegateIsSet
{
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
  id mockComponent = [OCMockObject mockForClass:[CKComponent class]];
  [[[mockComponent stub] andReturn:@"MyClass"] className];
  CKFakeActionComponent *fakeParentComponent = [CKFakeActionComponent new];
  [[[mockComponent stub] andReturn:fakeParentComponent] nextResponder];
  [[[mockComponent stub] andReturn:fakeParentComponent] targetForAction:[OCMArg anySelector] withSender:[OCMArg any]];
  CKSetMountedComponentForView(view, mockComponent);

  CKComponentViewAttributeValue attr = CKComponentGestureAttribute([UIPanGestureRecognizer class], nullptr, @selector(test:));
  attr.first.applicator(view, attr.second);

  UIPanGestureRecognizer *gesture = view.gestureRecognizers.firstObject;
  XCTAssertNil(gesture.delegate, @"Gesture delegate should not be set");
}

- (void)testThatApplyingANilRecognizerClassResultsInNoRecognizer
{
  CKComponentViewAttributeValue attr = CKComponentGestureAttribute(Nil, nullptr, @selector(test));
  UIView *view = [UIView new];

  attr.first.applicator(view, attr.second);
  XCTAssertEqual([view.gestureRecognizers count], 0u, @"Expected no gesture recognizer to be attached");
  attr.first.unapplicator(view, attr.second);
}

- (void)testThatApplyingATapRecognizerAttributeWithDifferentTargetToViewWithExistingRecognizerUpdatesAction
{
  CKFakeActionComponent *fake1 = [CKFakeActionComponent new];
  CKComponentViewAttributeValue attr1 = CKComponentTapGestureAttribute({fake1, @selector(test:)});

  CKFakeActionComponent *fake2 = [CKFakeActionComponent new];
  CKAction<UIGestureRecognizer *> action2 = {fake2, @selector(test:)};
  CKComponentViewAttributeValue attr2 = CKComponentTapGestureAttribute(action2);
  UIView *view = [UIView new];

  attr1.first.applicator(view, attr1.second);
  attr1.first.unapplicator(view, attr1.second);

  attr2.first.applicator(view, attr2.second);
  UITapGestureRecognizer *recognizer = [view.gestureRecognizers firstObject];
  XCTAssert(CKComponentGestureGetAction(recognizer) == action2, @"Expected ck_componentAction to be set on the GR");
  attr2.first.unapplicator(view, attr2.second);
}

@end

@implementation CKFakeActionComponent

- (void)test:(CKComponent *)sender
{
  _receivedTest = YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
  _receivedGestureShouldBegin = YES;
  return YES;
}

@end
