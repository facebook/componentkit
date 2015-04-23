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

#import "CKComponentScopeFrame.h"
#import "CKThreadLocalComponentScope.h"

@interface CKComponentScopeTests : XCTestCase
@end

@implementation CKComponentScopeTests

- (void)testThreadLocalStateIsEmptyByDefault
{
  XCTAssertTrue(CKThreadLocalComponentScope::cursor() != nullptr);
  XCTAssertTrue(CKThreadLocalComponentScope::cursor()->empty());
}

- (void)testThreadLocalStateIsNotNullAfterCreatingThreadStateScope
{
  CKComponentScopeFrame *frame = [CKComponentScopeFrame rootFrameWithListener:nil globalIdentifier:0];
  CKThreadLocalComponentScope threadScope(frame);
  XCTAssertTrue(CKThreadLocalComponentScope::cursor() != nullptr);
}

- (void)testThreadLocalStateStoresPassedInFrameAsEquivalentPreviousFrame
{
  CKComponentScopeFrame *frame = [CKComponentScopeFrame rootFrameWithListener:nil globalIdentifier:0];
  CKThreadLocalComponentScope threadScope(frame);
  XCTAssertEqualObjects(CKThreadLocalComponentScope::cursor()->equivalentPreviousFrame(), frame);
}

- (void)testThreadLocalStateBeginsWithRootCurrentFrame
{
  CKComponentScopeFrame *frame = [CKComponentScopeFrame rootFrameWithListener:nil globalIdentifier:0];
  CKThreadLocalComponentScope threadScope(frame);

  CKComponentScopeFrame *currentFrame = CKThreadLocalComponentScope::cursor()->currentFrame();
  XCTAssertTrue(currentFrame != NULL);
}

- (void)testThreadLocalStatePushesChildScope
{
  CKComponentScopeFrame *frame = [CKComponentScopeFrame rootFrameWithListener:nil globalIdentifier:0];
  CKThreadLocalComponentScope threadScope(frame);

  CKComponentScopeFrame *rootFrame = CKThreadLocalComponentScope::cursor()->currentFrame();

  CKComponentScope scope([CKCompositeComponent class]);

  CKComponentScopeFrame *currentFrame = CKThreadLocalComponentScope::cursor()->currentFrame();
  XCTAssertTrue(currentFrame != rootFrame);
}

- (void)testCreatingThreadLocalStateScopeThrowsIfScopeAlreadyExists
{
  CKComponentScopeFrame *frame = [CKComponentScopeFrame rootFrameWithListener:nil globalIdentifier:0];

  CKThreadLocalComponentScope threadScope(frame);
  XCTAssertThrows(CKThreadLocalComponentScope(frame));
}

#pragma mark - Scope Frame

- (void)testHasChildScopeIsCreatedWithCorrectKeys
{
  CKComponentScopeFrame *frame = [CKComponentScopeFrame rootFrameWithListener:nil globalIdentifier:0];
  CKComponentScopeFrame *childFrame = [frame childFrameWithComponentClass:[CKCompositeComponent class]
                                                               identifier:@"moose"
                                                                    state:@123
                                                               controller:nil
                                                         globalIdentifier:1];

  XCTAssertEqual(childFrame.componentClass, [CKCompositeComponent class]);
  XCTAssertEqualObjects(childFrame.identifier, @"moose");
  XCTAssertEqualObjects(childFrame.state, @123);
}

- (void)testHasChildScopeReturnsTrueWhenTheScopeMatches
{
  CKComponentScopeFrame *frame = [CKComponentScopeFrame rootFrameWithListener:nil globalIdentifier:0];
  CKComponentScopeFrame __unused *childFrame = [frame childFrameWithComponentClass:[CKCompositeComponent class]
                                                                        identifier:@"moose"
                                                                             state:@123
                                                                        controller:nil
                                                                  globalIdentifier:1];

  XCTAssertNotNil([frame existingChildFrameWithClass:[CKCompositeComponent class] identifier:@"moose"]);
  XCTAssertNil([frame existingChildFrameWithClass:[CKCompositeComponent class] identifier:@"meese"]);
  XCTAssertNil([frame existingChildFrameWithClass:[CKCompositeComponent class] identifier:nil]);

  XCTAssertNil([frame existingChildFrameWithClass:[NSArray class] identifier:@"moose"]);
  XCTAssertNil([frame existingChildFrameWithClass:[NSArray class] identifier:nil]);
}

- (void)testFrameIsPoppedWhenScopeCloses
{
  CKComponentScopeFrame *frame = [CKComponentScopeFrame rootFrameWithListener:nil globalIdentifier:0];
  CKThreadLocalComponentScope threadScope(frame);

  CKComponentScopeFrame *rootFrame = CKThreadLocalComponentScope::cursor()->currentFrame();
  {
    CKComponentScope scope([CKCompositeComponent class], @"moose");
    XCTAssertTrue(CKThreadLocalComponentScope::cursor()->currentFrame() != rootFrame);
  }
  XCTAssertEqual(CKThreadLocalComponentScope::cursor()->currentFrame(), rootFrame);
}

- (void)testHasChildScopeIsTrueEvenAfterScopeClosesAndPopsAFrame
{
  CKComponentScopeFrame *frame = [CKComponentScopeFrame rootFrameWithListener:nil globalIdentifier:0];
  CKThreadLocalComponentScope threadScope(frame);

  CKComponentScopeFrame *rootFrame = CKThreadLocalComponentScope::cursor()->currentFrame();
  {
    CKComponentScope scope([CKCompositeComponent class], @"moose");
  }
  XCTAssertEqual(CKThreadLocalComponentScope::cursor()->currentFrame(), rootFrame);
}

- (void)testThreadStateScopeAcquiringPreviousScopeStateOneLevelDown
{
  CKComponentScopeFrame *frame = [CKComponentScopeFrame rootFrameWithListener:nil globalIdentifier:0];
  CKComponentScopeFrame *createdFrame = NULL;
  {
    CKThreadLocalComponentScope threadScope(frame);
    {
      CKComponentScope scope([CKCompositeComponent class], @"macaque", ^{ return @42; });
      id __unused state = scope.state();
    }

    createdFrame = CKThreadLocalComponentScope::cursor()->currentFrame();
  }

  CKComponentScopeFrame *createdFrame2 = NULL;
  {
    CKThreadLocalComponentScope threadScope(createdFrame);
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

    createdFrame2 = CKThreadLocalComponentScope::cursor()->currentFrame();
  }
}

- (void)testThreadStateScopeAcquiringPreviousScopeGlobalIdentifierOneLevelDown
{
  CKComponentScopeFrame *frame = [CKComponentScopeFrame rootFrameWithListener:nil globalIdentifier:0];
  CKComponentScopeFrame *createdFrame;
  int32_t childGlobalIdentifier;
  {
    CKThreadLocalComponentScope threadScope(frame);
    {
      CKComponentScope scope([CKCompositeComponent class], @"macaque");
      childGlobalIdentifier = CKThreadLocalComponentScope::cursor()->currentFrame().globalIdentifier;
    }
    createdFrame = CKThreadLocalComponentScope::cursor()->currentFrame();
  }

  {
    CKThreadLocalComponentScope threadScope(createdFrame);
    {
      CKComponentScope scope([CKCompositeComponent class], @"macaque");
      XCTAssertEqual(childGlobalIdentifier, CKThreadLocalComponentScope::cursor()->currentFrame().globalIdentifier);
    }
  }
}

- (void)testThreadStateScopeAcquiringPreviousScopeStateOneLevelDownWithSibling
{
  CKComponentScopeFrame *frame = [CKComponentScopeFrame rootFrameWithListener:nil globalIdentifier:0];
  CKComponentScopeFrame *createdFrame = NULL;
  {
    CKThreadLocalComponentScope threadScope(frame);
    {
      CKComponentScope scope([CKCompositeComponent class], @"spongebob", ^{ return @"FUN"; });
      id __unused state = scope.state();
    }
    {
      CKComponentScope scope([CKCompositeComponent class], @"patrick", ^{ return @"HAHA"; });
      id __unused state = scope.state();
    }

    createdFrame = CKThreadLocalComponentScope::cursor()->currentFrame();
  }

  CKComponentScopeFrame *createdFrame2 = nullptr;
  {
    CKThreadLocalComponentScope threadScope(createdFrame);
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

    createdFrame2 = CKThreadLocalComponentScope::cursor()->currentFrame();
  }
}

- (void)testThreadStateScopeAcquiringPreviousScopeStateOneLevelDownWithSiblingThatDoesNotAcquire
{
  CKComponentScopeFrame *frame = [CKComponentScopeFrame rootFrameWithListener:nil globalIdentifier:0];
  CKComponentScopeFrame *createdFrame = NULL;
  {
    CKThreadLocalComponentScope threadScope(frame);
    {
      CKComponentScope scope([CKCompositeComponent class], @"Quoth", ^{ return @"nevermore"; });
      id __unused state = scope.state();
    }
    {
      CKComponentScope scope([CKCompositeComponent class], @"perched", ^{ return @"raven"; });
      id __unused state = scope.state();
    }

    createdFrame = CKThreadLocalComponentScope::cursor()->currentFrame();
  }

  CKComponentScopeFrame *createdFrame2 = nullptr;
  {
    CKThreadLocalComponentScope threadScope(createdFrame);
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

    createdFrame2 = CKThreadLocalComponentScope::cursor()->currentFrame();
  }
}

- (void)testCreatingSiblingScopeWithSameClassNameThrows
{
  CKComponentScopeFrame *frame = [CKComponentScopeFrame rootFrameWithListener:nil globalIdentifier:0];
  CKThreadLocalComponentScope threadScope(frame);
  {
    CKComponentScope scope([CKCompositeComponent class]);
  }
  {
    XCTAssertThrows(CKComponentScope([CKCompositeComponent class]));
  }
}

- (void)testCreatingSiblingScopeWithSameClassNameAndSameIdentifierThrows
{
  CKComponentScopeFrame *frame = [CKComponentScopeFrame rootFrameWithListener:nil globalIdentifier:0];
  CKThreadLocalComponentScope threadScope(frame);
  {
    CKComponentScope scope([CKCompositeComponent class], @"lasagna");
  }
  {
    XCTAssertThrows(CKComponentScope([CKCompositeComponent class], @"lasagna"));
  }
}

- (void)testCreatingSiblingScopeWithSameClassButDifferentIdenfitiferDoesNotThrow
{
  CKComponentScopeFrame *frame = [CKComponentScopeFrame rootFrameWithListener:nil globalIdentifier:0];
  CKThreadLocalComponentScope threadScope(frame);
  {
    CKComponentScope scope([CKCompositeComponent class], @"linguine");
  }
  {
    XCTAssertNoThrow(CKComponentScope([CKCompositeComponent class], @"spaghetti"));
  }
}

- (void)testTeardownThrowsIfStateScopeHasNotBeenPoppedBackToTheRoot
{
  CKComponentScopeFrame *frame = [CKComponentScopeFrame rootFrameWithListener:nil globalIdentifier:0];

  BOOL exceptionThrown = NO;
  @try {
    CKThreadLocalComponentScope threadScope(frame);

    CKComponentScopeFrame *frame2 = [CKComponentScopeFrame rootFrameWithListener:nil globalIdentifier:0];
    CKThreadLocalComponentScope::cursor()->pushFrameAndEquivalentPreviousFrame(frame2, nil);
  } @catch(...) {
    exceptionThrown = YES;
  }

  XCTAssertTrue(exceptionThrown);
  CKThreadLocalComponentScope::cursor()->popFrame();
  XCTAssertTrue(CKThreadLocalComponentScope::cursor()->empty());
}

@end
