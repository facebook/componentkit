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

#import <ComponentKit/CKCollection.h>
#import <ComponentKit/CKComponentScope.h>
#import <ComponentKit/CKComponentScopeFrame.h>
#import <ComponentKit/CKComponentScopeHandle.h>
#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKComponentScopeRootFactory.h>
#import <ComponentKit/CKComponentProtocol.h>
#import <ComponentKit/CKComponentControllerProtocol.h>
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKRenderComponent.h>
#import <ComponentKit/CKRootTreeNode.h>
#import <ComponentKit/CKThreadLocalComponentScope.h>

#import <ComponentKit/CKTreeNode.h>

@protocol TestScopedProtocol <NSObject>
@end

@interface TestComponentWithScopedProtocol : NSObject <CKComponentProtocol, TestScopedProtocol>
@end
@implementation TestComponentWithScopedProtocol
+ (id)initialState { return nil; }
+ (Class<CKComponentControllerProtocol>)controllerClass
{ return nil; };
- (id<CKComponentControllerProtocol>)buildController
{ return nil; }
- (NSString *)className
{ return @""; }
@end

@interface TestComponentWithoutScopedProtocol : NSObject <CKComponentProtocol>
@end
@implementation TestComponentWithoutScopedProtocol
+ (id)initialState { return nil; }
+ (Class<CKComponentControllerProtocol>)controllerClass
{ return nil; };
- (id<CKComponentControllerProtocol>)buildController
{ return nil; }
- (NSString *)className
{ return @""; }
@end

@interface TestComponentControllerWithScopedProtocol : NSObject <CKComponentControllerProtocol, TestScopedProtocol>
@end
@implementation TestComponentControllerWithScopedProtocol
- (instancetype)initWithComponent:(id<CKComponentProtocol>)component
{
  return [super init];
}
- (id<CKComponentProtocol>)component { return [CKComponent new]; }
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
  CKThreadLocalComponentScope threadScope(CKComponentScopeRootWithDefaultPredicates(nil, nil), {});
  XCTAssertTrue(CKThreadLocalComponentScope::currentScope() != nullptr);
}

- (void)testThreadLocalComponentScopeStoresTheProvidedFrameAsTheEquivalentPreviousFrame
{
  CKComponentScopeRoot *root = CKComponentScopeRootWithDefaultPredicates(nil, nil);
  CKThreadLocalComponentScope threadScope(root, {});
  XCTAssertEqualObjects(CKThreadLocalComponentScope::currentScope()->stack.top().previousFrame, root.rootNode.node());
}

- (void)testThreadLocalComponentScopePushesChildComponentScope
{
  CKComponentScopeRoot *root = CKComponentScopeRootWithDefaultPredicates(nil, nil);
  CKThreadLocalComponentScope threadScope(root, {});
  id<CKComponentScopeFrameProtocol> rootFrame = CKThreadLocalComponentScope::currentScope()->stack.top().frame;
  CKComponentScope scope([CKCompositeComponent class]);
  id<CKComponentScopeFrameProtocol> currentFrame = CKThreadLocalComponentScope::currentScope()->stack.top().frame;
  XCTAssertTrue(currentFrame != rootFrame);
}

- (void)testThreadLocalComponentScopeCanBeNested
{
  {
    CKComponentScopeRoot *root = CKComponentScopeRootWithDefaultPredicates(nil, nil);
    CKThreadLocalComponentScope threadScope(root, {});

    {
      CKComponentScopeRoot *root2 = CKComponentScopeRootWithDefaultPredicates(nil, nil);
      CKThreadLocalComponentScope threadScope2(root2, {});
      XCTAssertEqual(CKThreadLocalComponentScope::currentScope(), &threadScope2);
    }

    XCTAssertEqual(CKThreadLocalComponentScope::currentScope(), &threadScope);
  }

  XCTAssertEqual(CKThreadLocalComponentScope::currentScope(), nullptr);
}

#pragma mark - Component Scope Frame

- (void)testComponentScopeFrameIsPoppedWhenComponentScopeCloses
{
  CKComponentScopeRoot *root = CKComponentScopeRootWithDefaultPredicates(nil, nil);
  CKThreadLocalComponentScope threadScope(root, {});
  id<CKComponentScopeFrameProtocol> rootFrame = CKThreadLocalComponentScope::currentScope()->stack.top().frame;
  {
    CKComponentScope scope([CKCompositeComponent class], @"moose");
    XCTAssertTrue(CKThreadLocalComponentScope::currentScope()->stack.top().frame != rootFrame);
  }
  XCTAssertEqual(CKThreadLocalComponentScope::currentScope()->stack.top().frame, rootFrame);
}

#pragma mark - Component Scope State

- (void)testComponentScopeStateIsAcquiredFromPreviousComponentScopeStateOneLevelDown
{
  CKComponentScopeRoot *root1 = CKComponentScopeRootWithDefaultPredicates(nil, nil);
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

- (void)testComponentScopeReplaceStatePropagatesStateToNextComponentScopeState
{
  CKComponentScopeRoot *root1 = CKComponentScopeRootWithDefaultPredicates(nil, nil);
  CKComponentScopeRoot *root2;
  {
    CKThreadLocalComponentScope threadScope(root1, {});
    {
      CKComponentScope scope([CKCompositeComponent class], @"macaque", ^{ return @42; });
      CKComponentScope::replaceState(scope, @100);
      XCTAssertEqualObjects(scope.state(), @100);
    }
    root2 = CKThreadLocalComponentScope::currentScope()->newScopeRoot;
  }
  {
    CKThreadLocalComponentScope threadScope(root2, {});
    {
      CKComponentScope scope([CKCompositeComponent class], @"macaque", ^{ return @365; });
      XCTAssertEqualObjects(scope.state(), @100);
    }
  }
}

- (void)testComponentScopeStateIsAcquiredFromPreviousComponentScopeStateOneLevelDownWithSibling
{
  CKComponentScopeRoot *root1 = CKComponentScopeRootWithDefaultPredicates(nil, nil);
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
  CKComponentScopeRoot *root1 = CKComponentScopeRootWithDefaultPredicates(nil, nil);
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

#pragma mark - Test Component Scope Identifier

- (void)testComponentScopeIdentifierIsSameAsScopeHandleGlobalIdentifier
{
  CKComponentScopeRoot *root1 = CKComponentScopeRootWithDefaultPredicates(nil, nil);
  {
    CKThreadLocalComponentScope threadScope(root1, {});
    {
      CKComponentScope scope([CKCompositeComponent class], @"macaque");
      int32_t globalIdentifier = CKThreadLocalComponentScope::currentScope()->stack.top().frame.scopeHandle.globalIdentifier;
      XCTAssertEqual(globalIdentifier, scope.identifier());
    }
  }
}

#pragma mark - Component Scope Handle Global Identifier

- (void)testComponentScopeHandleGlobalIdentifierIsAcquiredFromPreviousComponentScopeOneLevelDown
{
  CKComponentScopeRoot *root1 = CKComponentScopeRootWithDefaultPredicates(nil, nil);
  CKComponentScopeRoot *root2;
  int32_t globalIdentifier;
  {
    CKThreadLocalComponentScope threadScope(root1, {});
    {
      CKComponentScope scope([CKCompositeComponent class], @"macaque");
      globalIdentifier = CKThreadLocalComponentScope::currentScope()->stack.top().frame.scopeHandle.globalIdentifier;
    }
    root2 = CKThreadLocalComponentScope::currentScope()->newScopeRoot;
  }
  {
    CKThreadLocalComponentScope threadScope(root2, {});
    {
      CKComponentScope scope([CKCompositeComponent class], @"macaque");
      XCTAssertEqual(globalIdentifier, CKThreadLocalComponentScope::currentScope()->stack.top().frame.scopeHandle.globalIdentifier);
    }
  }
}

- (void)testComponentScopeHandleGlobalIdentifierIsNotTheSameBetweenSiblings
{
  CKComponentScopeRoot *root = CKComponentScopeRootWithDefaultPredicates(nil, nil);
  {
    CKThreadLocalComponentScope threadScope(root, {});
    int32_t globalIdentifier;
    {
      CKComponentScope scope([CKCompositeComponent class], @"moose");
      globalIdentifier = CKThreadLocalComponentScope::currentScope()->stack.top().frame.scopeHandle.globalIdentifier;
    }
    {
      CKComponentScope scope([CKCompositeComponent class], @"macaque");
      XCTAssertNotEqual(globalIdentifier, CKThreadLocalComponentScope::currentScope()->stack.top().frame.scopeHandle.globalIdentifier);
    }
  }
}

- (void)testComponentScopeHandleGlobalIdentifierIsNotTheSameBetweenSiblingsWithComponentScopeCollision
{
  CKComponentScopeRoot *root = CKComponentScopeRootWithDefaultPredicates(nil, nil);
  {
    CKThreadLocalComponentScope threadScope(root, {});
    int32_t globalIdentifier;
    {
      CKComponentScope scope([CKCompositeComponent class], @"macaque");
      globalIdentifier = CKThreadLocalComponentScope::currentScope()->stack.top().frame.scopeHandle.globalIdentifier;
    }
    {
      CKComponentScope scope([CKCompositeComponent class], @"macaque");
      XCTAssertNotEqual(globalIdentifier, CKThreadLocalComponentScope::currentScope()->stack.top().frame.scopeHandle.globalIdentifier);
    }
  }
}

- (void)testComponentScopeHandleGlobalIdentifierIsNotTheSameBetweenDescendantsWithComponentScopeCollision
{
  CKComponentScopeRoot *root = CKComponentScopeRootWithDefaultPredicates(nil, nil);
  {
    CKThreadLocalComponentScope threadScope(root, {});
    int32_t globalIdentifier;
    {
      CKComponentScope scope1([CKCompositeComponent class], @"macaque");
      {
        CKComponentScope scope2([CKCompositeComponent class], @"moose");
        globalIdentifier = CKThreadLocalComponentScope::currentScope()->stack.top().frame.scopeHandle.globalIdentifier;
      }
    }
    {
      CKComponentScope scope1([CKCompositeComponent class], @"macaque");
      {
        CKComponentScope scope2([CKCompositeComponent class], @"moose");
        XCTAssertNotEqual(globalIdentifier, CKThreadLocalComponentScope::currentScope()->stack.top().frame.scopeHandle.globalIdentifier);
      }
    }
  }
}

- (void)testComponentScopeHandleGlobalIdentifierIsTheSameBetweenDescendantsWithComponentScopeCollisionAcrossComponentScopeRoots
{
  CKComponentScopeRoot *root1 = CKComponentScopeRootWithDefaultPredicates(nil, nil);
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
        globalIdentifier = CKThreadLocalComponentScope::currentScope()->stack.top().frame.scopeHandle.globalIdentifier;
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
        XCTAssertEqual(globalIdentifier, CKThreadLocalComponentScope::currentScope()->stack.top().frame.scopeHandle.globalIdentifier);
      }
    }
  }
}

static BOOL testComponentProtocolPredicate(id<CKComponentProtocol> component)
{
  return [component conformsToProtocol:@protocol(TestScopedProtocol)];
}

- (void)testComponentScopeRootRegisteringProtocolComponentFindsThatComponentWhenEnumerating
{
  CKComponentScopeRoot *root = [CKComponentScopeRoot
                                rootWithListener:nil
                                analyticsListener:nil
                                componentPredicates:{&testComponentProtocolPredicate}
                                componentControllerPredicates:{}];
  CKThreadLocalComponentScope threadScope(root, {});

  TestComponentWithScopedProtocol *c = [TestComponentWithScopedProtocol new];
  [root registerComponent:c];

  __block BOOL foundComponent = NO;
  [root
   enumerateComponentsMatchingPredicate:&testComponentProtocolPredicate
   block:^(id<CKComponentProtocol> component) {
     if (c == component) {
       foundComponent = YES;
     }
   }];

  XCTAssert(foundComponent, @"Should have enumerated and found the input component");
}

- (void)testComponentScopeRootFactoryRegisteringProtocolComponentFindsThatComponentWhenEnumerating
{
  CKComponentScopeRoot *root = CKComponentScopeRootWithPredicates(nil, nil, {&testComponentProtocolPredicate}, {});

  CKThreadLocalComponentScope threadScope(root, {});

  TestComponentWithScopedProtocol *c = [TestComponentWithScopedProtocol new];
  [root registerComponent:c];

  __block BOOL foundComponent = NO;
  [root
   enumerateComponentsMatchingPredicate:&testComponentProtocolPredicate
   block:^(id<CKComponentProtocol> component) {
     if (c == component) {
       foundComponent = YES;
     }
   }];

  XCTAssert(foundComponent, @"Should have enumerated and found the input component");
}

- (void)testComponentScopeRootRegisteringDuplicateProtocolComponent
{
  CKComponentScopeRoot *root = [CKComponentScopeRoot
                                rootWithListener:nil
                                analyticsListener:nil
                                componentPredicates:{&testComponentProtocolPredicate}
                                componentControllerPredicates:{}];
  CKThreadLocalComponentScope threadScope(root, {});

  TestComponentWithScopedProtocol *c = [TestComponentWithScopedProtocol new];
  [root registerComponent:c];
  [root registerComponent:c];

  __block NSInteger numberOfComponents = 0;
  [root
   enumerateComponentsMatchingPredicate:&testComponentProtocolPredicate
   block:^(id<CKComponentProtocol> component) {
     ++numberOfComponents;
   }];

  XCTAssert(numberOfComponents == 1, @"Should have deduplicate the component");
}

- (void)testComponentScopeRootFactoryRegisteringDuplicateProtocolComponent
{
  CKComponentScopeRoot *root = CKComponentScopeRootWithPredicates(nil, nil, {&testComponentProtocolPredicate}, {});
  CKThreadLocalComponentScope threadScope(root, {});

  TestComponentWithScopedProtocol *c = [TestComponentWithScopedProtocol new];
  [root registerComponent:c];
  [root registerComponent:c];

  __block NSInteger numberOfComponents = 0;
  [root
   enumerateComponentsMatchingPredicate:&testComponentProtocolPredicate
   block:^(id<CKComponentProtocol> component) {
     ++numberOfComponents;
   }];

  XCTAssert(numberOfComponents == 1, @"Should have deduplicate the component");
}

- (void)testComponentScopeRootRegisteringMultipleProtocolComponentFindsBothComponentsWhenEnumerating
{
  CKComponentScopeRoot *root = [CKComponentScopeRoot
                                rootWithListener:nil
                                analyticsListener:nil
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
   block:^(id<CKComponentProtocol> component) {
     if (c1 == component) {
       foundC1 = YES;
     }
     if (c2 == component) {
       foundC2 = YES;
     }
   }];

  XCTAssert(foundC1 && foundC2, @"Should have enumerated and found the input components");
}

- (void)testComponentScopeRootFactoryRegisteringMultipleProtocolComponentFindsBothComponentsWhenEnumerating
{
  CKComponentScopeRoot *root = CKComponentScopeRootWithPredicates(nil, nil, {&testComponentProtocolPredicate}, {});
  CKThreadLocalComponentScope threadScope(root, {});

  TestComponentWithScopedProtocol *c1 = [TestComponentWithScopedProtocol new];
  [root registerComponent:c1];
  TestComponentWithScopedProtocol *c2 = [TestComponentWithScopedProtocol new];
  [root registerComponent:c2];

  __block BOOL foundC1 = NO;
  __block BOOL foundC2 = NO;
  [root
   enumerateComponentsMatchingPredicate:&testComponentProtocolPredicate
   block:^(id<CKComponentProtocol> component) {
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
                                analyticsListener:nil
                                componentPredicates:{&testComponentProtocolPredicate}
                                componentControllerPredicates:{}];
  CKThreadLocalComponentScope threadScope(root, {});

  TestComponentWithoutScopedProtocol *c = [TestComponentWithoutScopedProtocol new];
  [root registerComponent:c];

  [root
   enumerateComponentsMatchingPredicate:&testComponentProtocolPredicate
   block:^(id<CKComponentProtocol> component) {
     XCTFail(@"Should not have found any components");
   }];
}

- (void)testComponentScopeRootFactoryRegisteringNonProtocolComponentFindsNoComponentsWhenEnumerating
{
  CKComponentScopeRoot *root = CKComponentScopeRootWithPredicates(nil, nil, {&testComponentProtocolPredicate}, {});
  CKThreadLocalComponentScope threadScope(root, {});

  TestComponentWithoutScopedProtocol *c = [TestComponentWithoutScopedProtocol new];
  [root registerComponent:c];

  [root
   enumerateComponentsMatchingPredicate:&testComponentProtocolPredicate
   block:^(id<CKComponentProtocol> component) {
     XCTFail(@"Should not have found any components");
   }];
}

static BOOL testComponentControllerProtocolPredicate(id<CKComponentControllerProtocol> component)
{
  return [component conformsToProtocol:@protocol(TestScopedProtocol)];
}

- (void)testComponentScopeRootRegisteringProtocolComponentControllerFindsThatControllerWhenEnumerating
{
  CKComponentScopeRoot *root = [CKComponentScopeRoot
                                rootWithListener:nil
                                analyticsListener:nil
                                componentPredicates:{}
                                componentControllerPredicates:{&testComponentControllerProtocolPredicate}];
  CKThreadLocalComponentScope threadScope(root, {});

  TestComponentControllerWithScopedProtocol *c = [TestComponentControllerWithScopedProtocol new];
  [root registerComponentController:c];

  __block BOOL foundController = NO;
  [root
   enumerateComponentControllersMatchingPredicate:&testComponentControllerProtocolPredicate
   block:^(id<CKComponentControllerProtocol> componentController) {
     if (c == componentController) {
       foundController = YES;
     }
   }];

  XCTAssert(foundController, @"Should have enumerated and found the input controller");
}

- (void)testComponentScopeRootFactoryRegisteringProtocolComponentControllerFindsThatControllerWhenEnumerating
{
  CKComponentScopeRoot *root = CKComponentScopeRootWithPredicates(nil, nil, {}, {&testComponentControllerProtocolPredicate});
  CKThreadLocalComponentScope threadScope(root, {});

  TestComponentControllerWithScopedProtocol *c = [TestComponentControllerWithScopedProtocol new];
  [root registerComponentController:c];

  __block BOOL foundController = NO;
  [root
   enumerateComponentControllersMatchingPredicate:&testComponentControllerProtocolPredicate
   block:^(id<CKComponentControllerProtocol> componentController) {
     if (c == componentController) {
       foundController = YES;
     }
   }];

  XCTAssert(foundController, @"Should have enumerated and found the input controller");
}

- (void)testComponentScopeRootRegisteringDuplicateProtocolComponentController
{
  CKComponentScopeRoot *root = [CKComponentScopeRoot
                                rootWithListener:nil
                                analyticsListener:nil
                                componentPredicates:{}
                                componentControllerPredicates:{&testComponentControllerProtocolPredicate}];
  CKThreadLocalComponentScope threadScope(root, {});

  TestComponentControllerWithScopedProtocol *c = [TestComponentControllerWithScopedProtocol new];
  [root registerComponentController:c];
  [root registerComponentController:c];

  __block NSInteger numberOfComponentControllers = 0;
  [root
   enumerateComponentControllersMatchingPredicate:&testComponentControllerProtocolPredicate
   block:^(id<CKComponentControllerProtocol> componentController) {
     ++numberOfComponentControllers;
   }];

  XCTAssert(numberOfComponentControllers == 1, @"Should have deduplicate the component controller");
}

- (void)testComponentScopeRootFactoryRegisteringDuplicateProtocolComponentController
{
  CKComponentScopeRoot *root = CKComponentScopeRootWithPredicates(nil, nil, {}, {&testComponentControllerProtocolPredicate});
  CKThreadLocalComponentScope threadScope(root, {});

  TestComponentControllerWithScopedProtocol *c = [TestComponentControllerWithScopedProtocol new];
  [root registerComponentController:c];
  [root registerComponentController:c];

  __block NSInteger numberOfComponentControllers = 0;
  [root
   enumerateComponentControllersMatchingPredicate:&testComponentControllerProtocolPredicate
   block:^(id<CKComponentControllerProtocol> componentController) {
     ++numberOfComponentControllers;
   }];

  XCTAssert(numberOfComponentControllers == 1, @"Should have deduplicate the component controller");
}

- (void)testComponentScopeRootRegisteringMultipleProtocolComponentControllersFindsBothControllersWhenEnumerating
{
  CKComponentScopeRoot *root = [CKComponentScopeRoot
                                rootWithListener:nil
                                analyticsListener:nil
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
   block:^(id<CKComponentControllerProtocol> componentController) {
     if (c1 == componentController) {
       foundC1 = YES;
     }
     if (c2 == componentController) {
       foundC2 = YES;
     }
   }];

  XCTAssert(foundC1 && foundC2, @"Should have enumerated and found the input controllers");
}

- (void)testComponentScopeRootFactoryRegisteringMultipleProtocolComponentControllersFindsBothControllersWhenEnumerating
{
  CKComponentScopeRoot *root = CKComponentScopeRootWithPredicates(nil, nil, {}, {&testComponentControllerProtocolPredicate});
  CKThreadLocalComponentScope threadScope(root, {});

  TestComponentControllerWithScopedProtocol *c1 = [TestComponentControllerWithScopedProtocol new];
  [root registerComponentController:c1];
  TestComponentControllerWithScopedProtocol *c2 = [TestComponentControllerWithScopedProtocol new];
  [root registerComponentController:c2];

  __block BOOL foundC1 = NO;
  __block BOOL foundC2 = NO;
  [root
   enumerateComponentControllersMatchingPredicate:&testComponentControllerProtocolPredicate
   block:^(id<CKComponentControllerProtocol> componentController) {
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

@interface CKComponentScopeRootTests_RegistrationAndEnumeration: XCTestCase
@end

@implementation CKComponentScopeRootTests_RegistrationAndEnumeration

- (void)testComponentScopeRootRegisteringProtocolComponentFindsThatComponentWhenEnumerating
{
  const auto root = makeScopeRootWithComponentPredicate(&testComponentProtocolPredicate);
  const auto threadScope = CKThreadLocalComponentScope {root, {}};
  const auto c = [TestComponentWithScopedProtocol new];

  [root registerComponent:c];

  XCTAssert(CK::Collection::contains([root componentsMatchingPredicate:&testComponentProtocolPredicate], c),
            @"Should have enumerated and found the input component");
}

- (void)testComponentScopeRootFactoryRegisteringProtocolComponentFindsThatComponentWhenEnumerating
{
  const auto root = CKComponentScopeRootWithPredicates(nil, nil, {&testComponentProtocolPredicate}, {});
  const auto threadScope = CKThreadLocalComponentScope {root, {}};
  const auto c = [TestComponentWithScopedProtocol new];

  [root registerComponent:c];

  XCTAssert(CK::Collection::contains([root componentsMatchingPredicate:&testComponentProtocolPredicate], c),
            @"Should have enumerated and found the input component");
}

- (void)testComponentScopeRootRegisteringDuplicateProtocolComponent
{
  const auto root = makeScopeRootWithComponentPredicate(&testComponentProtocolPredicate);
  const auto threadScope = CKThreadLocalComponentScope {root, {}};
  const auto c = [TestComponentWithScopedProtocol new];

  [root registerComponent:c];
  [root registerComponent:c];

  XCTAssertEqual([root componentsMatchingPredicate:&testComponentProtocolPredicate].size(), 1, @"Should have deduplicate the component");
}

- (void)testComponentScopeRootFactoryRegisteringDuplicateProtocolComponent
{
  const auto root = CKComponentScopeRootWithPredicates(nil, nil, {&testComponentProtocolPredicate}, {});
  const auto threadScope = CKThreadLocalComponentScope {root, {}};
  const auto c = [TestComponentWithScopedProtocol new];

  [root registerComponent:c];
  [root registerComponent:c];

  XCTAssert(CK::Collection::contains([root componentsMatchingPredicate:&testComponentProtocolPredicate], c),
            @"Should have enumerated and found the input component");
}

- (void)testComponentScopeRootRegisteringMultipleProtocolComponentFindsBothComponentsWhenEnumerating
{
  const auto root = makeScopeRootWithComponentPredicate(&testComponentProtocolPredicate);
  const auto threadScope = CKThreadLocalComponentScope {root, {}};
  const auto c1 = [TestComponentWithScopedProtocol new];
  const auto c2 = [TestComponentWithScopedProtocol new];

  [root registerComponent:c1];
  [root registerComponent:c2];

  const auto foundC1 = CK::Collection::contains([root componentsMatchingPredicate:&testComponentProtocolPredicate], c1);
  const auto foundC2 = CK::Collection::contains([root componentsMatchingPredicate:&testComponentProtocolPredicate], c2);
  XCTAssert(foundC1 && foundC2, @"Should have enumerated and found the input components");
}

- (void)testComponentScopeRootFactoryRegisteringMultipleProtocolComponentFindsBothComponentsWhenEnumerating
{
  const auto root = CKComponentScopeRootWithPredicates(nil, nil, {&testComponentProtocolPredicate}, {});
  const auto threadScope = CKThreadLocalComponentScope {root, {}};
  const auto c1 = [TestComponentWithScopedProtocol new];
  const auto c2 = [TestComponentWithScopedProtocol new];

  [root registerComponent:c1];
  [root registerComponent:c2];

  const auto foundC1 = CK::Collection::contains([root componentsMatchingPredicate:&testComponentProtocolPredicate], c1);
  const auto foundC2 = CK::Collection::contains([root componentsMatchingPredicate:&testComponentProtocolPredicate], c2);
  XCTAssert(foundC1 && foundC2, @"Should have enumerated and found the input components");
}

- (void)testComponentScopeRootRegisteringNonProtocolComponentFindsNoComponentsWhenEnumerating
{
  const auto root = makeScopeRootWithComponentPredicate(&testComponentProtocolPredicate);
  const auto threadScope = CKThreadLocalComponentScope {root, {}};
  const auto c = [TestComponentWithoutScopedProtocol new];

  [root registerComponent:c];

  XCTAssert([root componentsMatchingPredicate:&testComponentProtocolPredicate].empty(), @"Should not have found any components");
}

- (void)testComponentScopeRootFactoryRegisteringNonProtocolComponentFindsNoComponentsWhenEnumerating
{
  const auto root = CKComponentScopeRootWithPredicates(nil, nil, {&testComponentProtocolPredicate}, {});
  const auto threadScope = CKThreadLocalComponentScope {root, {}};
  const auto c = [TestComponentWithoutScopedProtocol new];

  [root registerComponent:c];

  XCTAssert([root componentsMatchingPredicate:&testComponentProtocolPredicate].empty(), @"Should not have found any components");
}

static auto makeScopeRootWithComponentPredicate(const CKComponentPredicate p) -> CKComponentScopeRoot *
{
  return [CKComponentScopeRoot
          rootWithListener:nil
          analyticsListener:nil
          componentPredicates:{p}
          componentControllerPredicates:{}];
}

@end
