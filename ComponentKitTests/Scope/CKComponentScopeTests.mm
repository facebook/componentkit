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

#import <ComponentKit/CKCompositeComponent.h>

#import <ComponentKit/CKComponentScope.h>
#import <ComponentKit/CKComponentScopeFrame.h>
#import <ComponentKit/CKComponentScopeHandle.h>
#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKComponentScopeRootFactory.h>
#import <ComponentKit/CKScopedComponent.h>
#import <ComponentKit/CKScopedComponentController.h>
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKThreadLocalComponentScope.h>

@protocol TestScopedProtocol <NSObject>
@end

@interface TestComponentWithScopedProtocol : NSObject <CKScopedComponent, TestScopedProtocol>
@end
@implementation TestComponentWithScopedProtocol
+ (id)initialState { return nil; }
+ (Class<CKScopedComponentController>)controllerClass { return nil; };
@end

@interface TestComponentWithoutScopedProtocol : NSObject <CKScopedComponent>
@end
@implementation TestComponentWithoutScopedProtocol
+ (id)initialState { return nil; }
+ (Class<CKScopedComponentController>)controllerClass { return nil; };
@end

@interface TestComponentControllerWithScopedProtocol : NSObject <CKScopedComponentController, TestScopedProtocol>
@end
@implementation TestComponentControllerWithScopedProtocol
- (instancetype)initWithComponent:(id<CKScopedComponent>)component
{
  return [super init];
}
@end

@interface CKComponentScopeTests : XCTestCase
@end

@implementation CKComponentScopeTests

#pragma mark - Thread Local Component Scope

- (void)testThreadLocalComponentScopeIsEmptyWhenNoScopeExists
{
  XCTAssertTrue(CKThreadLocalComponentScope::currentScope() == nullptr);
}

- (void)testThreadLocalComponentScopeIsNotEmptyWhenTheScopeExists
{
  CKThreadLocalComponentScope threadScope(CKComponentScopeRootWithDefaultPredicates(nil), {});
  XCTAssertTrue(CKThreadLocalComponentScope::currentScope() != nullptr);
}

- (void)testThreadLocalComponentScopeStoresTheProvidedFrameAsTheEquivalentPreviousFrame
{
  CKComponentScopeRoot *root = CKComponentScopeRootWithDefaultPredicates(nil);
  CKThreadLocalComponentScope threadScope(root, {});
  XCTAssertEqualObjects(CKThreadLocalComponentScope::currentScope()->stack.top().equivalentPreviousFrame, root.rootFrame);
}

- (void)testThreadLocalComponentScopePushesChildComponentScope
{
  CKComponentScopeRoot *root = CKComponentScopeRootWithDefaultPredicates(nil);
  CKThreadLocalComponentScope threadScope(root, {});
  CKComponentScopeFrame *rootFrame = CKThreadLocalComponentScope::currentScope()->stack.top().frame;
  CKComponentScope scope([CKCompositeComponent class]);
  CKComponentScopeFrame *currentFrame = CKThreadLocalComponentScope::currentScope()->stack.top().frame;
  XCTAssertTrue(currentFrame != rootFrame);
}

- (void)testThreadLocalComponentScopeCanBeOverridden
{
  CKComponentScopeRoot *root = CKComponentScopeRootWithDefaultPredicates(nil);
  CKThreadLocalComponentScope threadScope(root, {});
  CKThreadLocalComponentScope *threadScopePtr = &threadScope;

  dispatch_semaphore_t sema = dispatch_semaphore_create(0);
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    XCTAssertTrue(CKThreadLocalComponentScope::currentScope() == nullptr);
    {
      CKThreadLocalComponentScopeOverride scopeOverride(threadScopePtr);
      XCTAssertEqual(CKThreadLocalComponentScope::currentScope(), threadScopePtr);
    }
    XCTAssertTrue(CKThreadLocalComponentScope::currentScope() == nullptr);
    dispatch_semaphore_signal(sema);
  });
  dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC));
  dispatch_semaphore_wait(sema, timeout);

  XCTAssertEqual(CKThreadLocalComponentScope::currentScope(), threadScopePtr);
}

#pragma mark - Component Scope Frame

- (void)testComponentScopeFrameIsPoppedWhenComponentScopeCloses
{
  CKComponentScopeRoot *root = CKComponentScopeRootWithDefaultPredicates(nil);
  CKThreadLocalComponentScope threadScope(root, {});
  CKComponentScopeFrame *rootFrame = CKThreadLocalComponentScope::currentScope()->stack.top().frame;
  {
    CKComponentScope scope([CKCompositeComponent class], @"moose");
    XCTAssertTrue(CKThreadLocalComponentScope::currentScope()->stack.top().frame != rootFrame);
  }
  XCTAssertEqual(CKThreadLocalComponentScope::currentScope()->stack.top().frame, rootFrame);
}

#pragma mark - Component Scope State

- (void)testComponentScopeStateIsAcquiredFromPreviousComponentScopeStateOneLevelDown
{
  CKComponentScopeRoot *root1 = CKComponentScopeRootWithDefaultPredicates(nil);
  CKComponentScopeRoot *root2;
  {
    CKThreadLocalComponentScope threadScope(root1, {});
    {
      CKComponentScope scope([CKCompositeComponent class], @"macaque", ^{ return @42; });
    }
    root2 = CKThreadLocalComponentScope::currentScope()->newScopeRoot;
  }
  {
    CKThreadLocalComponentScope threadScope(root2, {});
    {
      // This block should never be called. We should inherit the previous scope.
      BOOL __block blockCalled = NO;
      CKComponentScope scope([CKCompositeComponent class], @"macaque", ^{
        blockCalled = YES;
        return @365;
      });
      id state = scope.state();
      XCTAssertFalse(blockCalled);
      XCTAssertEqualObjects(state, @42);
    }
  }
}

- (void)testComponentScopeStateIsAcquiredFromPreviousComponentScopeStateOneLevelDownWithSibling
{
  CKComponentScopeRoot *root1 = CKComponentScopeRootWithDefaultPredicates(nil);
  CKComponentScopeRoot *root2;
  {
    CKThreadLocalComponentScope threadScope(root1, {});
    {
      CKComponentScope scope([CKCompositeComponent class], @"spongebob", ^{ return @"FUN"; });
      id __unused state = scope.state();
    }
    {
      CKComponentScope scope([CKCompositeComponent class], @"patrick", ^{ return @"HAHA"; });
      id __unused state = scope.state();
    }
    root2 = CKThreadLocalComponentScope::currentScope()->newScopeRoot;
  }
  {
    CKThreadLocalComponentScope threadScope(root2, {});
    {
      // This block should never be called. We should inherit the previous scope.
      CKComponentScope scope([CKCompositeComponent class], @"spongebob", ^{ return @"rotlf-nope!"; });
      id state = scope.state();
      XCTAssertEqualObjects(state, @"FUN");
    }
    {
      // This block should never be called. We should inherit the previous scope.
      CKComponentScope scope([CKCompositeComponent class], @"patrick", ^{ return @"rotlf-nope!"; });
      id state = scope.state();
      XCTAssertEqualObjects(state, @"HAHA");
    }
  }
}

- (void)testComponentScopeStateIsAcquiredFromPreviousComponentScopeStateOneLevelDownWithSiblingThatDoesNotAcquire
{
  CKComponentScopeRoot *root1 = CKComponentScopeRootWithDefaultPredicates(nil);
  CKComponentScopeRoot *root2;
  {
    CKThreadLocalComponentScope threadScope(root1, {});
    {
      CKComponentScope scope([CKCompositeComponent class], @"Quoth", ^{ return @"nevermore"; });
      id __unused state = scope.state();
    }
    {
      CKComponentScope scope([CKCompositeComponent class], @"perched", ^{ return @"raven"; });
      id __unused state = scope.state();
    }
    root2 = CKThreadLocalComponentScope::currentScope()->newScopeRoot;
  }
  {
    CKThreadLocalComponentScope threadScope(root2, {});
    {
      // This block should never be called. We should inherit the previous scope.
      CKComponentScope scope([CKCompositeComponent class], @"Quoth", ^{ return @"Lenore"; });
      id state = scope.state();
      XCTAssertEqualObjects(state, @"nevermore");
    }
    {
      CKComponentScope scope([CKCompositeComponent class], @"chamber", ^{ return @"door"; });
      id state = scope.state();
      XCTAssertEqualObjects(state, @"door");
    }
  }
}

#pragma mark - Component Scope Handle Global Identifier

- (void)testComponentScopeHandleGlobalIdentifierIsAcquiredFromPreviousComponentScopeOneLevelDown
{
  CKComponentScopeRoot *root1 = CKComponentScopeRootWithDefaultPredicates(nil);
  CKComponentScopeRoot *root2;
  int32_t globalIdentifier;
  {
    CKThreadLocalComponentScope threadScope(root1, {});
    {
      CKComponentScope scope([CKCompositeComponent class], @"macaque");
      globalIdentifier = CKThreadLocalComponentScope::currentScope()->stack.top().frame.handle.globalIdentifier;
    }
    root2 = CKThreadLocalComponentScope::currentScope()->newScopeRoot;
  }
  {
    CKThreadLocalComponentScope threadScope(root2, {});
    {
      CKComponentScope scope([CKCompositeComponent class], @"macaque");
      XCTAssertEqual(globalIdentifier, CKThreadLocalComponentScope::currentScope()->stack.top().frame.handle.globalIdentifier);
    }
  }
}

- (void)testComponentScopeHandleGlobalIdentifierIsNotTheSameBetweenSiblings
{
  CKComponentScopeRoot *root = CKComponentScopeRootWithDefaultPredicates(nil);
  {
    CKThreadLocalComponentScope threadScope(root, {});
    int32_t globalIdentifier;
    {
      CKComponentScope scope([CKCompositeComponent class], @"moose");
      globalIdentifier = CKThreadLocalComponentScope::currentScope()->stack.top().frame.handle.globalIdentifier;
    }
    {
      CKComponentScope scope([CKCompositeComponent class], @"macaque");
      XCTAssertNotEqual(globalIdentifier, CKThreadLocalComponentScope::currentScope()->stack.top().frame.handle.globalIdentifier);
    }
  }
}

- (void)testComponentScopeHandleGlobalIdentifierIsTheSameBetweenSiblingsWithComponentScopeCollision
{
  CKComponentScopeRoot *root = CKComponentScopeRootWithDefaultPredicates(nil);
  {
    CKThreadLocalComponentScope threadScope(root, {});
    int32_t globalIdentifier;
    {
      CKComponentScope scope([CKCompositeComponent class], @"macaque");
      globalIdentifier = CKThreadLocalComponentScope::currentScope()->stack.top().frame.handle.globalIdentifier;
    }
    {
      CKComponentScope scope([CKCompositeComponent class], @"macaque");
      XCTAssertEqual(globalIdentifier, CKThreadLocalComponentScope::currentScope()->stack.top().frame.handle.globalIdentifier);
    }
  }
}

- (void)testComponentScopeHandleGlobalIdentifierIsTheSameBetweenDescendantsWithComponentScopeCollision
{
  CKComponentScopeRoot *root = CKComponentScopeRootWithDefaultPredicates(nil);
  {
    CKThreadLocalComponentScope threadScope(root, {});
    int32_t globalIdentifier;
    {
      CKComponentScope scope1([CKCompositeComponent class], @"macaque");
      {
        CKComponentScope scope2([CKCompositeComponent class], @"moose");
        globalIdentifier = CKThreadLocalComponentScope::currentScope()->stack.top().frame.handle.globalIdentifier;
      }
    }
    {
      CKComponentScope scope1([CKCompositeComponent class], @"macaque");
      {
        CKComponentScope scope2([CKCompositeComponent class], @"moose");
        XCTAssertEqual(globalIdentifier, CKThreadLocalComponentScope::currentScope()->stack.top().frame.handle.globalIdentifier);
      }
    }
  }
}

- (void)testComponentScopeHandleGlobalIdentifierIsTheSameBetweenDescendantsWithComponentScopeCollisionAcrossComponentScopeRoots
{
  CKComponentScopeRoot *root1 = CKComponentScopeRootWithDefaultPredicates(nil);
  CKComponentScopeRoot *root2;
  int32_t globalIdentifier;
  {
    CKThreadLocalComponentScope threadScope(root1, {});
    {
      CKComponentScope scope1([CKCompositeComponent class], @"macaque");
      {
        CKComponentScope scope2([CKCompositeComponent class], @"moose");
      }
    }
    {
      CKComponentScope scope1([CKCompositeComponent class], @"macaque");
      {
        CKComponentScope scope2([CKCompositeComponent class], @"moose");
        globalIdentifier = CKThreadLocalComponentScope::currentScope()->stack.top().frame.handle.globalIdentifier;
      }
    }
    root2 = threadScope.newScopeRoot;
  }
  {
    CKThreadLocalComponentScope threadScope(root2, {});
    {
      CKComponentScope scope1([CKCompositeComponent class], @"macaque");
      {
        CKComponentScope scope2([CKCompositeComponent class], @"moose");
      }
    }
    {
      CKComponentScope scope1([CKCompositeComponent class], @"macaque");
      {
        CKComponentScope scope2([CKCompositeComponent class], @"moose");
        XCTAssertEqual(globalIdentifier, CKThreadLocalComponentScope::currentScope()->stack.top().frame.handle.globalIdentifier);
      }
    }
  }
}

static BOOL testComponentProtocolPredicate(id<CKScopedComponent> component)
{
  return [component conformsToProtocol:@protocol(TestScopedProtocol)];
}

- (void)testComponentScopeRootRegisteringProtocolComponentFindsThatComponentWhenEnumerating
{
  CKComponentScopeRoot *root = [CKComponentScopeRoot
                                rootWithListener:nil
                                componentPredicates:{&testComponentProtocolPredicate}
                                componentControllerPredicates:{}];
  CKThreadLocalComponentScope threadScope(root, {});

  TestComponentWithScopedProtocol *c = [TestComponentWithScopedProtocol new];
  [root registerComponent:c];

  __block BOOL foundComponent = NO;
  [root
   enumerateComponentsMatchingPredicate:&testComponentProtocolPredicate
   block:^(id<CKScopedComponent> component) {
     if (c == component) {
       foundComponent = YES;
     }
   }];

  XCTAssert(foundComponent, @"Should have enumerated and found the input component");
}

- (void)testComponentScopeRootRegisteringMultipleProtocolComponentFindsBothComponentsWhenEnumerating
{
  CKComponentScopeRoot *root = [CKComponentScopeRoot
                                rootWithListener:nil
                                componentPredicates:{&testComponentProtocolPredicate}
                                componentControllerPredicates:{}];
  CKThreadLocalComponentScope threadScope(root, {});

  TestComponentWithScopedProtocol *c1 = [TestComponentWithScopedProtocol new];
  [root registerComponent:c1];
  TestComponentWithScopedProtocol *c2 = [TestComponentWithScopedProtocol new];
  [root registerComponent:c2];

  __block BOOL foundC1 = NO;
  __block BOOL foundC2 = NO;
  [root
   enumerateComponentsMatchingPredicate:&testComponentProtocolPredicate
   block:^(id<CKScopedComponent> component) {
     if (c1 == component) {
       foundC1 = YES;
     }
     if (c2 == component) {
       foundC2 = YES;
     }
   }];

  XCTAssert(foundC1 && foundC2, @"Should have enumerated and found the input components");
}

- (void)testComponentScopeRootRegisteringNonProtocolComponentFindsNoComponentsWhenEnumerating
{
  CKComponentScopeRoot *root = [CKComponentScopeRoot
                                rootWithListener:nil
                                componentPredicates:{&testComponentProtocolPredicate}
                                componentControllerPredicates:{}];
  CKThreadLocalComponentScope threadScope(root, {});

  TestComponentWithoutScopedProtocol *c = [TestComponentWithoutScopedProtocol new];
  [root registerComponent:c];

  [root
   enumerateComponentsMatchingPredicate:&testComponentProtocolPredicate
   block:^(id<CKScopedComponent> component) {
     XCTFail(@"Should not have found any components");
   }];
}

static BOOL testComponentControllerProtocolPredicate(id<CKScopedComponentController> component)
{
  return [component conformsToProtocol:@protocol(TestScopedProtocol)];
}

- (void)testComponentScopeRootRegisteringProtocolComponentControllerFindsThatControllerWhenEnumerating
{
  CKComponentScopeRoot *root = [CKComponentScopeRoot
                                rootWithListener:nil
                                componentPredicates:{}
                                componentControllerPredicates:{&testComponentControllerProtocolPredicate}];
  CKThreadLocalComponentScope threadScope(root, {});

  TestComponentControllerWithScopedProtocol *c = [TestComponentControllerWithScopedProtocol new];
  [root registerComponentController:c];

  __block BOOL foundController = NO;
  [root
   enumerateComponentControllersMatchingPredicate:&testComponentControllerProtocolPredicate
   block:^(id<CKScopedComponentController> componentController) {
     if (c == componentController) {
       foundController = YES;
     }
   }];

  XCTAssert(foundController, @"Should have enumerated and found the input controller");
}

- (void)testComponentScopeRootRegisteringMultipleProtocolComponentControllersFindsBothControllersWhenEnumerating
{
  CKComponentScopeRoot *root = [CKComponentScopeRoot
                                rootWithListener:nil
                                componentPredicates:{}
                                componentControllerPredicates:{&testComponentControllerProtocolPredicate}];
  CKThreadLocalComponentScope threadScope(root, {});

  TestComponentControllerWithScopedProtocol *c1 = [TestComponentControllerWithScopedProtocol new];
  [root registerComponentController:c1];
  TestComponentControllerWithScopedProtocol *c2 = [TestComponentControllerWithScopedProtocol new];
  [root registerComponentController:c2];

  __block BOOL foundC1 = NO;
  __block BOOL foundC2 = NO;
  [root
   enumerateComponentControllersMatchingPredicate:&testComponentControllerProtocolPredicate
   block:^(id<CKScopedComponentController> componentController) {
     if (c1 == componentController) {
       foundC1 = YES;
     }
     if (c2 == componentController) {
       foundC2 = YES;
     }
   }];

  XCTAssert(foundC1 && foundC2, @"Should have enumerated and found the input controllers");
}

@end
