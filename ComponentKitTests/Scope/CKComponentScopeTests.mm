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

#import "CKComponentScope.h"
#import "CKComponentScopeFrame.h"
#import "CKComponentScopeHandle.h"
#import "CKComponentScopeRoot.h"
#import "CKThreadLocalComponentScope.h"

@interface CKComponentScopeTests : XCTestCase
@end

@implementation CKComponentScopeTests

- (void)testThreadLocalStateIsEmptyByDefault
{
  XCTAssertTrue(CKThreadLocalComponentScope::currentScope() == nullptr);
}

- (void)testThreadLocalStateIsNotNullAfterCreatingThreadStateScope
{
  CKThreadLocalComponentScope threadScope([CKComponentScopeRoot rootWithListener:nil], {});
  XCTAssertTrue(CKThreadLocalComponentScope::currentScope() != nullptr);
}

- (void)testThreadLocalStateStoresPassedInFrameAsEquivalentPreviousFrame
{
  CKComponentScopeRoot *root = [CKComponentScopeRoot rootWithListener:nil];
  CKThreadLocalComponentScope threadScope(root, {});
  XCTAssertEqualObjects(CKThreadLocalComponentScope::currentScope()->stack.top().equivalentPreviousFrame, root.rootFrame);
}

- (void)testThreadLocalStatePushesChildScope
{
  CKComponentScopeRoot *root = [CKComponentScopeRoot rootWithListener:nil];
  CKThreadLocalComponentScope threadScope(root, {});

  CKComponentScopeFrame *rootFrame = CKThreadLocalComponentScope::currentScope()->stack.top().frame;

  CKComponentScope scope([CKCompositeComponent class]);

  CKComponentScopeFrame *currentFrame = CKThreadLocalComponentScope::currentScope()->stack.top().frame;
  XCTAssertTrue(currentFrame != rootFrame);
}

#pragma mark - Scope Frame

- (void)testFrameIsPoppedWhenScopeCloses
{
  CKComponentScopeRoot *root = [CKComponentScopeRoot rootWithListener:nil];
  CKThreadLocalComponentScope threadScope(root, {});

  CKComponentScopeFrame *rootFrame = CKThreadLocalComponentScope::currentScope()->stack.top().frame;
  {
    CKComponentScope scope([CKCompositeComponent class], @"moose");
    XCTAssertTrue(CKThreadLocalComponentScope::currentScope()->stack.top().frame != rootFrame);
  }
  XCTAssertEqual(CKThreadLocalComponentScope::currentScope()->stack.top().frame, rootFrame);
}

- (void)testHasChildScopeIsTrueEvenAfterScopeClosesAndPopsAFrame
{
  CKComponentScopeRoot *root = [CKComponentScopeRoot rootWithListener:nil];
  CKThreadLocalComponentScope threadScope(root, {});

  CKComponentScopeFrame *rootFrame = CKThreadLocalComponentScope::currentScope()->stack.top().frame;
  {
    CKComponentScope scope([CKCompositeComponent class], @"moose");
  }
  XCTAssertEqual(CKThreadLocalComponentScope::currentScope()->stack.top().frame, rootFrame);
}

- (void)testThreadStateScopeAcquiringPreviousScopeStateOneLevelDown
{
  CKComponentScopeRoot *root1 = [CKComponentScopeRoot rootWithListener:nil];
  CKComponentScopeRoot *root2;
  {
    CKThreadLocalComponentScope threadScope(root1, {});
    {
      CKComponentScope scope([CKCompositeComponent class], @"macaque", ^{ return @42; });
      id __unused state = scope.state();
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

- (void)testThreadStateScopeAcquiringPreviousScopeGlobalIdentifierOneLevelDown
{
  CKComponentScopeRoot *root1 = [CKComponentScopeRoot rootWithListener:nil];
  CKComponentScopeRoot *root2;
  int32_t childGlobalIdentifier;
  {
    CKThreadLocalComponentScope threadScope(root1, {});
    {
      CKComponentScope scope([CKCompositeComponent class], @"macaque");
      childGlobalIdentifier = CKThreadLocalComponentScope::currentScope()->stack.top().frame.handle.globalIdentifier;
    }
    root2 = CKThreadLocalComponentScope::currentScope()->newScopeRoot;
  }

  {
    CKThreadLocalComponentScope threadScope(root2, {});
    {
      CKComponentScope scope([CKCompositeComponent class], @"macaque");
      XCTAssertEqual(childGlobalIdentifier, CKThreadLocalComponentScope::currentScope()->stack.top().frame.handle.globalIdentifier);
    }
  }
}

- (void)testThreadStateScopeAcquiringPreviousScopeStateOneLevelDownWithSibling
{
  CKComponentScopeRoot *root1 = [CKComponentScopeRoot rootWithListener:nil];
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

- (void)testThreadStateScopeAcquiringPreviousScopeStateOneLevelDownWithSiblingThatDoesNotAcquire
{
  CKComponentScopeRoot *root1 = [CKComponentScopeRoot rootWithListener:nil];
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

@end
