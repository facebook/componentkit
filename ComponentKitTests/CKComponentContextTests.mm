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

- (void)testComponentContextDoesntCleansUpWhenItGoesOutOfScopeIfThereIsRenderComponentInSubtree
{
  CKComponentContextRenderSupport contextSupport(YES);

  NSObject *o = [[NSObject alloc] init];

  {
    CKComponentContext<NSObject> context(o);
    // This makes sure that the context values will leave after the context object goes out of scope.
    CKComponentContextHelper::markRenderComponent();
  }

  NSObject *o2 = CKComponentContext<NSObject>::get();
  XCTAssertTrue(o == o2);

  CKComponentContextHelper::unmarkRenderComponent();
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

- (void)testNestedComponentContextChangesValueAndRestoresItAfterGoingOutOfStackWithRenderComponentInSubtree
{
  CKComponentContextRenderSupport contextSupport(YES);

  NSObject *outer = [[NSObject alloc] init];
  NSObject *inner = [[NSObject alloc] init];

  {
    CKComponentContext<NSObject> outerContext(outer);
    // Simulate creation of render component.
    CKComponentContextHelper::markRenderComponent();

    {
      CKComponentContext<NSObject> innerContext(inner);
      // Simulate creation of render component.
      CKComponentContextHelper::markRenderComponent();
      XCTAssertTrue(CKComponentContext<NSObject>::get() == inner);

      // Check different type of context with no render in between
      {
        NSNumber *n1 = @1;
        NSNumber *n2 = @2;
        CKComponentContext<NSNumber> innerContext1(n1);
        CKComponentContext<NSNumber> innerContext2(n2);
        {
          NSNumber *n3 = @3;
          CKComponentContext<NSNumber> innerContext3(n3);
          XCTAssertTrue(CKComponentContext<NSNumber>::get() == n3);
        }
        XCTAssertTrue(CKComponentContext<NSNumber>::get() == n2);
      }
    }

    // Make sure the context lives after it goes out of the scope (as there is a render component).
    XCTAssertTrue(CKComponentContext<NSObject>::get() == inner);

    // Simulate the end of buildComponentTree in render component.
    CKComponentContextHelper::unmarkRenderComponent();

    XCTAssertTrue(CKComponentContext<NSObject>::get() == outer);
  }

  // Make sure the context lives after it goes out of the scope (as there is a render component).
  XCTAssertTrue(CKComponentContext<NSObject>::get() == outer);

  // Simulate the end of buildComponentTree in render component.
  CKComponentContextHelper::unmarkRenderComponent();

  // Not the context should be nil as the render component has finished its comonent creation.
  XCTAssertNil(CKComponentContext<NSObject>::get(), @"Expected getting NSObject to return nil as its scope is closed");
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

- (void)testFetchingAllComponentContextWhenRenderComponentIsInTheTree
{
  CKComponentContextRenderSupport contextSupport(YES);

  NSObject *o1 = [NSObject alloc];
  NSObject *o2 = [NSObject alloc];

  {
    CKComponentContext<NSObject> context1(o1);
    XCTAssertEqualObjects(CKComponentContextHelper::fetchAll().objects, @{[NSObject class]: o1});

    // Simulate creation of render component.
    CKComponentContextHelper::markRenderComponent();
  }

  // As there is a render component in the tree, o1 still need to stay in the store.
  XCTAssertEqualObjects(CKComponentContextHelper::fetchAll().objects, @{[NSObject class]: o1});

  {
    CKComponentContext<NSObject> context1(o2);
    // Make sure we get the latest value from the current store.
    XCTAssertEqualObjects(CKComponentContextHelper::fetchAll().objects, @{[NSObject class]: o2});
  }


  XCTAssertEqualObjects(CKComponentContextHelper::fetchAll().objects, @{[NSObject class]: o1});

  CKComponentContextHelper::unmarkRenderComponent();
  XCTAssertEqualObjects(CKComponentContextHelper::fetchAll().objects, nil);
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

- (void)testMarkRenderComponentWhenEnableRenderSupportOff
{
  NSObject *const o1 = [[NSObject alloc] init];
  NSObject *const o2 = [[NSObject alloc] init];

  {
    CKComponentContext<NSObject> context1(o1);
    CKComponentContextHelper::markRenderComponent();
    XCTAssertTrue(CKComponentContext<NSObject>::get() == o1);
    {
      CKComponentContext<NSObject> context2(o2);
      CKComponentContextHelper::markRenderComponent();
      XCTAssertTrue(CKComponentContext<NSObject>::get() == o2);
    }
  }

  // As the render support is off, `markRenderComponent()` should do nothig and the context should be nil.
  XCTAssertNil(CKComponentContext<NSObject>::get(), @"Expected getting NSObject to return nil as its scope is closed");

  // Make sure `unmarkRenderComponent()` does nothing when the render support is off.
  CKComponentContextHelper::unmarkRenderComponent();
  CKComponentContextHelper::unmarkRenderComponent();
  XCTAssertNil(CKComponentContext<NSObject>::get(), @"Expected getting NSObject to return nil as its scope is closed");
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
