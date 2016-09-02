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

#import <ComponentKit/CKComponentContext.h>

@interface CKComponentContextTests : XCTestCase
@end

@implementation CKComponentContextTests

- (void)testEstablishingAComponentContextAllowsYouToFetchIt
{
  NSObject *o = [[NSObject alloc] init];
  CKComponentContext<NSObject> context(o);

  NSObject *o2 = CKComponentContext<NSObject>::get();
  XCTAssertTrue(o == o2);
}

- (void)testFetchingAnObjectThatHasNotBeenEstablishedWithGetReturnsNil
{
  XCTAssertNil(CKComponentContext<NSObject>::get(), @"Expected to return nil without throwing");
}

- (void)testComponentContextCleansUpWhenItGoesOutOfScope
{
  {
    NSObject *o = [[NSObject alloc] init];
    CKComponentContext<NSObject> context(o);
  }
  XCTAssertNil(CKComponentContext<NSObject>::get(), @"Expected getting NSObject to return nil as its scope is closed");
}

- (void)testNestedComponentContextChangesValueAndRestoresItAfterGoingOutOfScope
{
  NSObject *outer = [[NSObject alloc] init];
  CKComponentContext<NSObject> context(outer);
  {
    NSObject *inner = [[NSObject alloc] init];
    CKComponentContext<NSObject> context(inner);
    XCTAssertTrue(CKComponentContext<NSObject>::get() == inner);
  }
  XCTAssertTrue(CKComponentContext<NSObject>::get() == outer);
}

- (void)testTriplyNestedComponentContextWithNilMiddleValueCorrectlyRestoresOuterValue
{
  // This tests an obscure edge case with restoring values for context as we pop scopes.
  NSObject *outer = [[NSObject alloc] init];
  CKComponentContext<NSObject> context(outer);
  {
    CKComponentContext<NSObject> context(nil);
    XCTAssertTrue(CKComponentContext<NSObject>::get() == nil);
    {
      NSObject *inner = [[NSObject alloc] init];
      CKComponentContext<NSObject> context(inner);
      XCTAssertTrue(CKComponentContext<NSObject>::get() == inner);
    }
  }
  XCTAssertTrue(CKComponentContext<NSObject>::get() == outer);
}

@end
