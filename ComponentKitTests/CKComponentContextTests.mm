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

@interface CKTestDynamicLookup : NSObject <CKComponentContextDynamicLookup>
- (instancetype)initWithObjects:(NSArray *)objects;
@end

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
  CKComponentContext<NSObject> outerContext(outer);
  {
    NSObject *inner = [[NSObject alloc] init];
    CKComponentContext<NSObject> innerContext(inner);
    XCTAssertTrue(CKComponentContext<NSObject>::get() == inner);
  }
  XCTAssertTrue(CKComponentContext<NSObject>::get() == outer);
}

- (void)testTriplyNestedComponentContextWithNilMiddleValueCorrectlyRestoresOuterValue
{
  // This tests an obscure edge case with restoring values for context as we pop scopes.
  NSObject *outer = [[NSObject alloc] init];
  CKComponentContext<NSObject> outerContext(outer);
  {
    CKComponentContext<NSObject> middleContext(nil);
    XCTAssertTrue(CKComponentContext<NSObject>::get() == nil);
    {
      NSObject *inner = [[NSObject alloc] init];
      CKComponentContext<NSObject> innerContext(inner);
      XCTAssertTrue(CKComponentContext<NSObject>::get() == inner);
    }
  }
  XCTAssertTrue(CKComponentContext<NSObject>::get() == outer);
}

- (void)testFetchingAllComponentContextItemsReturnsObjects
{
  NSObject *o = [[NSObject alloc] init];
  CKComponentContext<NSObject> context(o);
  const CKComponentContextContents contents = CKComponentContextHelper::fetchAll();
  XCTAssertEqualObjects(contents.objects, @{[NSObject class]: o});
}

- (void)testFetchingAllComponentContextItemsTwiceReturnsEqualContents
{
  CKComponentContext<NSObject> context([[NSObject alloc] init]);
  const CKComponentContextContents contents1 = CKComponentContextHelper::fetchAll();
  const CKComponentContextContents contents2 = CKComponentContextHelper::fetchAll();
  XCTAssertTrue(contents1 == contents2);
}

- (void)testFetchingAllComponentContextItemsBeforeAndAfterModificationReturnsUnequalContents
{
  CKComponentContext<NSObject> context1([[NSObject alloc] init]);
  const CKComponentContextContents contents1 = CKComponentContextHelper::fetchAll();
  CKComponentContext<NSObject> context2([[NSObject alloc] init]);
  const CKComponentContextContents contents2 = CKComponentContextHelper::fetchAll();
  XCTAssertTrue(contents1 != contents2);
}

- (void)testDynamicLookupIsConsultedOnFetch
{
  NSObject *const objectInDynamicLookup = [[NSObject alloc] init];
  const CKComponentContextPreviousDynamicLookupState previousState =
  CKComponentContextHelper::setDynamicLookup([[CKTestDynamicLookup alloc] initWithObjects:@[objectInDynamicLookup]]);
  // Even though we didn't put objectInDynamicLookup in context, it will be found on fetch.
  XCTAssertTrue(CKComponentContext<NSObject>::get() == objectInDynamicLookup);
  CKComponentContextHelper::restoreDynamicLookup(previousState);
}

- (void)testDynamicLookupIsNotConsultedOnFetchForObjectSetInContextAfterSettingDynamicLookup
{
  NSObject *const objectInDynamicLookup = [[NSObject alloc] init];
  const CKComponentContextPreviousDynamicLookupState previousState =
  CKComponentContextHelper::setDynamicLookup([[CKTestDynamicLookup alloc] initWithObjects:@[objectInDynamicLookup]]);
  {
    NSObject *const objectInRegularContext = [[NSObject alloc] init];
    CKComponentContext<NSObject> c(objectInRegularContext);
    // CKComponentContext should override the dynamic lookup.
    XCTAssertTrue(CKComponentContext<NSObject>::get() == objectInRegularContext);
  }
  CKComponentContextHelper::restoreDynamicLookup(previousState);
}

- (void)testDynamicLookupClearsPreviousContextContentsOnSet
{
  NSObject *const o = [[NSObject alloc] init];
  CKComponentContext<NSObject> context(o);
  const CKComponentContextPreviousDynamicLookupState previousState =
  CKComponentContextHelper::setDynamicLookup([[CKTestDynamicLookup alloc] initWithObjects:@[]]);
  XCTAssertNil(CKComponentContext<NSObject>::get());
  CKComponentContextHelper::restoreDynamicLookup(previousState);
}

- (void)testDynamicLookupRestoresPreviousContextContentsOnRestore
{
  NSObject *const o = [[NSObject alloc] init];
  CKComponentContext<NSObject> context(o);
  const CKComponentContextPreviousDynamicLookupState previousState =
  CKComponentContextHelper::setDynamicLookup([[CKTestDynamicLookup alloc] initWithObjects:@[]]);
  CKComponentContextHelper::restoreDynamicLookup(previousState);
  XCTAssertTrue(CKComponentContext<NSObject>::get() == o);
}

@end

@implementation CKTestDynamicLookup
{
  NSArray *_objects;
}

- (instancetype)initWithObjects:(NSArray *)objects
{
  if (self = [super init]) {
    _objects = [objects copy];
  }
  return self;
}

- (id)contextValueForClass:(Class)c
{
  for (id object : _objects) {
    if ([object isKindOfClass:c]) {
      return object;
    }
  }
  return nil;
}

@end
