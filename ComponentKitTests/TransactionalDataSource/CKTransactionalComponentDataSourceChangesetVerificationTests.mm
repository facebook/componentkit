/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <Foundation/Foundation.h>

#import <XCTest/XCTest.h>

#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKTransactionalComponentDataSourceChangeset.h>
#import <ComponentKit/CKTransactionalComponentDataSourceChangesetModification.h>
#import <ComponentKit/CKTransactionalComponentDataSourceItemInternal.h>
#import <ComponentKit/CKTransactionalComponentDataSourceStateInternal.h>

#import "CKTransactionalComponentDataSourceChangesetVerification.h"

@interface CKTransactionalComponentDataSourceChangesetVerificationTests : XCTestCase
@end

@implementation CKTransactionalComponentDataSourceChangesetVerificationTests

#pragma mark - Valid changesets

- (void)test_emptyChangesetEmptySections
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeNone);
}

- (void)test_emptyChangesetNonEmptySections
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"A"),
                                                                             itemWithModel(@"B"),
                                                                             ],
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeNone);
}

- (void)test_nonEmptyChangesetEmptySections
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
     withInsertedSections:[NSIndexSet indexSetWithIndex:0]]
    withInsertedItems:@{
                       [NSIndexPath indexPathForItem:0 inSection:0]: @"A",
                       [NSIndexPath indexPathForItem:1 inSection:0]: @"B",
                       }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeNone);
}

- (void)test_validInsertionIntoEmptySection
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withInsertedItems:@{
                        [NSIndexPath indexPathForItem:0 inSection:0]: @"A",
                        [NSIndexPath indexPathForItem:1 inSection:0]: @"B",
                        }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeNone);
}

- (void)test_validInsertionIntoBeginningOfNonEmptySection
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withInsertedItems:@{
                        [NSIndexPath indexPathForItem:0 inSection:0]: @"A",
                        [NSIndexPath indexPathForItem:1 inSection:0]: @"B",
                        }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeNone);
}

- (void)test_validInsertionIntoMiddleOfNonEmptySection
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withInsertedItems:@{
                        [NSIndexPath indexPathForItem:1 inSection:0]: @"A",
                        [NSIndexPath indexPathForItem:2 inSection:0]: @"B",
                        }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeNone);
}

- (void)test_validInsertionAtEndOfNonEmptySection
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withInsertedItems:@{
                        [NSIndexPath indexPathForItem:2 inSection:0]: @"A",
                        [NSIndexPath indexPathForItem:3 inSection:0]: @"B",
                        }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeNone);
}

- (void)test_validRemovalAtBeginningOfSection
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             itemWithModel(@"E"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withRemovedItems:[NSSet setWithArray:@[
                                           [NSIndexPath indexPathForItem:0 inSection:0],
                                           ]]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeNone);
}

- (void)test_validRemovalAtMiddleOfSection
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             itemWithModel(@"E"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withRemovedItems:[NSSet setWithArray:@[
                                           [NSIndexPath indexPathForItem:1 inSection:0],
                                           ]]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeNone);
}

- (void)test_validRemovalAtEndOfSection
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             itemWithModel(@"E"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withRemovedItems:[NSSet setWithArray:@[
                                           [NSIndexPath indexPathForItem:2 inSection:0],
                                           ]]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeNone);
}

- (void)test_validRemovalOfAllItems
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             itemWithModel(@"E"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withRemovedItems:[NSSet setWithArray:@[
                                           [NSIndexPath indexPathForItem:2 inSection:0],
                                           [NSIndexPath indexPathForItem:1 inSection:0],
                                           [NSIndexPath indexPathForItem:0 inSection:0],
                                           ]]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeNone);
}

- (void)test_validInsertionOfSectionInEmptySections
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withInsertedSections:[NSIndexSet indexSetWithIndex:0]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeNone);
}

- (void)test_validInsertionOfSectionAtBeginningOfNonEmptySections
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           @[
                                                                             itemWithModel(@"E"),
                                                                             itemWithModel(@"F"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withInsertedSections:[NSIndexSet indexSetWithIndex:0]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeNone);
}

- (void)test_validInsertionOfSectionInMiddleOfNonEmptySections
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           @[
                                                                             itemWithModel(@"E"),
                                                                             itemWithModel(@"F"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withInsertedSections:[NSIndexSet indexSetWithIndex:1]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeNone);
}

- (void)test_validInsertionOfSectionAtEndOfNonEmptySections
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           @[
                                                                             itemWithModel(@"E"),
                                                                             itemWithModel(@"F"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withInsertedSections:[NSIndexSet indexSetWithIndex:2]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeNone);
}

- (void)test_validInsertionOfMultipleSections
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           @[
                                                                             itemWithModel(@"E"),
                                                                             itemWithModel(@"F"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withInsertedSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeNone);
}

- (void)test_removalOfSectionAtBeginningOfSections
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           @[
                                                                             itemWithModel(@"E"),
                                                                             itemWithModel(@"F"),
                                                                             ],
                                                                           @[
                                                                             itemWithModel(@"G"),
                                                                             itemWithModel(@"H"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withRemovedSections:[NSIndexSet indexSetWithIndex:0]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeNone);
}

- (void)test_removalOfSectionAtMiddleOfSections
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           @[
                                                                             itemWithModel(@"E"),
                                                                             itemWithModel(@"F"),
                                                                             ],
                                                                           @[
                                                                             itemWithModel(@"G"),
                                                                             itemWithModel(@"H"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withRemovedSections:[NSIndexSet indexSetWithIndex:1]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeNone);
}

- (void)test_removalOfSectionAtEndOfSections
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           @[
                                                                             itemWithModel(@"E"),
                                                                             itemWithModel(@"F"),
                                                                             ],
                                                                           @[
                                                                             itemWithModel(@"G"),
                                                                             itemWithModel(@"H"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withRemovedSections:[NSIndexSet indexSetWithIndex:2]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeNone);
}

- (void)test_removeMultipleSectionsAtBeginningOfSections
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           @[
                                                                             itemWithModel(@"E"),
                                                                             itemWithModel(@"F"),
                                                                             ],
                                                                           @[
                                                                             itemWithModel(@"G"),
                                                                             itemWithModel(@"H"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withRemovedSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeNone);
}

- (void)test_removeMultipleSectionsAtEndOfSections
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           @[
                                                                             itemWithModel(@"E"),
                                                                             itemWithModel(@"F"),
                                                                             ],
                                                                           @[
                                                                             itemWithModel(@"G"),
                                                                             itemWithModel(@"H"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withRemovedSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeNone);
}

- (void)test_validUpdate
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withUpdatedItems:@{
                       [NSIndexPath indexPathForItem:0 inSection:0]: @"A",
                       }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeNone);
}

- (void)test_validMoveForwardInsideOneSection
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withMovedItems:@{
                     [NSIndexPath indexPathForItem:0 inSection:0]: [NSIndexPath indexPathForItem:1 inSection:0],
                     }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeNone);
}

- (void)test_validMoveBackwardInsideOneSection
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withMovedItems:@{
                     [NSIndexPath indexPathForItem:1 inSection:0]: [NSIndexPath indexPathForItem:0 inSection:0],
                     }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeNone);
}

- (void)test_validMoveForwardBetweenSections
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           @[
                                                                             itemWithModel(@"E"),
                                                                             itemWithModel(@"F"),
                                                                             ],
                                                                           @[
                                                                             itemWithModel(@"G"),
                                                                             itemWithModel(@"H"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withMovedItems:@{
                     [NSIndexPath indexPathForItem:0 inSection:0]: [NSIndexPath indexPathForItem:2 inSection:1],
                     }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeNone);
}

- (void)test_validMoveBackwardBetweenSections
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           @[
                                                                             itemWithModel(@"E"),
                                                                             itemWithModel(@"F"),
                                                                             ],
                                                                           @[
                                                                             itemWithModel(@"G"),
                                                                             itemWithModel(@"H"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withMovedItems:@{
                     [NSIndexPath indexPathForItem:0 inSection:1]: [NSIndexPath indexPathForItem:2 inSection:0],
                     }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeNone);
}

- (void)test_validMoveBackwardWithOriginalIndexRemoved
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"A"),
                                                                             itemWithModel(@"B"),
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                            ]];
  // Changeset for transition from [A, B, C, D] to [D, A]
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
     withMovedItems:@{
                      [NSIndexPath indexPathForItem:3 inSection:0] : [NSIndexPath indexPathForItem:0 inSection:0],
                      }]
    withRemovedItems:[NSSet setWithArray:@[
                                           [NSIndexPath indexPathForItem:1 inSection:0],
                                           [NSIndexPath indexPathForItem:2 inSection:0],
                                           ]]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeNone);
}

#pragma mark - Invalid changesets

- (void)test_invalidUpdateInNegativeSection
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withUpdatedItems:@{
                       [NSIndexPath indexPathForItem:1 inSection:-1]: @"A",
                       }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeUpdate);
}

- (void)test_invalidUpdateInNegativeItem
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withUpdatedItems:@{
                       [NSIndexPath indexPathForItem:-1 inSection:0]: @"A",
                       }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeUpdate);
}

- (void)test_invalidInsertionAtEndOfSection
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withInsertedItems:@{
                        [NSIndexPath indexPathForItem:3 inSection:0]: @"A",
                        }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeInsertRow);
}

- (void)test_invalidMultipleInsertionAtEndOfSection
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withInsertedItems:@{
                        [NSIndexPath indexPathForItem:2 inSection:0]: @"A",
                        [NSIndexPath indexPathForItem:4 inSection:0]: @"B",
                        [NSIndexPath indexPathForItem:5 inSection:0]: @"E",
                        }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeInsertRow);
}

- (void)test_invalidInsertionInNonExistentSection
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withInsertedItems:@{
                        [NSIndexPath indexPathForItem:0 inSection:1]: @"A",
                        }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeInsertRow);
}

- (void)test_invalidRemovalInValidSection
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withRemovedItems:[NSSet setWithArray:@[
                                           [NSIndexPath indexPathForItem:2 inSection:0],
                                           ]]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeRemoveRow);
}

- (void)test_invalidRemovalInNonExistentSection
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withRemovedItems:[NSSet setWithArray:@[
                                           [NSIndexPath indexPathForItem:0 inSection:1],
                                           ]]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeRemoveRow);
}

- (void)test_invalidInsertionOfSection
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withInsertedSections:[NSIndexSet indexSetWithIndex:2]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeInsertSection);
}

- (void)test_invalidRemovalOfSection
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withRemovedSections:[NSIndexSet indexSetWithIndex:2]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeRemoveSection);
}

- (void)test_invalidUpdateWithinExistingSection
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withUpdatedItems:@{
                       [NSIndexPath indexPathForItem:2 inSection:0]: @"A",
                       }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeUpdate);
}

- (void)test_invalidUpdateWithinNonExistentSection
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withUpdatedItems:@{
                       [NSIndexPath indexPathForItem:0 inSection:1]: @"A",
                       }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeUpdate);
}

- (void)test_moveWithInvalidOriginIndexPathInExistingSection
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withMovedItems:@{
                     [NSIndexPath indexPathForItem:2 inSection:0]: [NSIndexPath indexPathForItem:0 inSection:0],
                     }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeMoveRow);
}

- (void)test_moveWithInvalidDestinationIndexPathInExistingSection
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withMovedItems:@{
                     [NSIndexPath indexPathForItem:0 inSection:0]: [NSIndexPath indexPathForItem:2 inSection:0],
                     }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeMoveRow);
}

- (void)test_moveWithInvalidOriginSection
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withMovedItems:@{
                     [NSIndexPath indexPathForItem:0 inSection:1]: [NSIndexPath indexPathForItem:0 inSection:0],
                     }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeMoveRow);
}

- (void)test_moveWithInvalidDestinationSection
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withMovedItems:@{
                     [NSIndexPath indexPathForItem:0 inSection:0]: [NSIndexPath indexPathForItem:0 inSection:1],
                     }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeMoveRow);
}

#pragma mark - More complicated situations

- (void)test_validInitialSectionInsertionsWithItemInsertions
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[]];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
     withInsertedSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]]
    withInsertedItems:@{
                        [NSIndexPath indexPathForItem:0 inSection:0]: @"A1",
                        [NSIndexPath indexPathForItem:1 inSection:0]: @"B1",
                        [NSIndexPath indexPathForItem:0 inSection:1]: @"A2",
                        [NSIndexPath indexPathForItem:1 inSection:1]: @"B2",
                        }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKBadChangesetOperationTypeNone);
}

- (void)test_validInitialSectionInsertionsInPendingAsynchronousModificationWithItemInsertions
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[]];
  NSArray<id<CKTransactionalComponentDataSourceStateModifying>> *pendingAsynchronousModifications =
  @[
    // Insert section 0 and section 1
    [[CKTransactionalComponentDataSourceChangesetModification alloc]
     initWithChangeset:
     [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
       withInsertedSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]]
      build]
     stateListener:nil
     userInfo:nil],
    ];
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withInsertedItems:@{
                        [NSIndexPath indexPathForItem:0 inSection:0]: @"A1",
                        [NSIndexPath indexPathForItem:1 inSection:0]: @"B1",
                        [NSIndexPath indexPathForItem:0 inSection:1]: @"A2",
                        [NSIndexPath indexPathForItem:1 inSection:1]: @"B2",
                        }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, pendingAsynchronousModifications), CKBadChangesetOperationTypeNone);
}

- (void)test_validChangesetAppliedToValidPendingAsynchronousModifications
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[]];
  NSArray<id<CKTransactionalComponentDataSourceStateModifying>> *pendingAsynchronousModifications =
  @[
    // Insert section 0
    [[CKTransactionalComponentDataSourceChangesetModification alloc]
     initWithChangeset:
     [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
       withInsertedSections:[NSIndexSet indexSetWithIndex:0]]
      build]
     stateListener:nil
     userInfo:nil],
    // Insert two items into section 0
    [[CKTransactionalComponentDataSourceChangesetModification alloc]
     initWithChangeset:
     [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
       withInsertedItems:@{
                           [NSIndexPath indexPathForItem:0 inSection:0]: @"A1",
                           [NSIndexPath indexPathForItem:1 inSection:0]: @"B1",
                           }]
      build]
     stateListener:nil
     userInfo:nil],
    // Insert section 1
    [[CKTransactionalComponentDataSourceChangesetModification alloc]
     initWithChangeset:
     [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
       withInsertedSections:[NSIndexSet indexSetWithIndex:1]]
      build]
     stateListener:nil
     userInfo:nil],
    // Insert two items into section 1
    [[CKTransactionalComponentDataSourceChangesetModification alloc]
     initWithChangeset:
     [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
       withInsertedItems:@{
                           [NSIndexPath indexPathForItem:0 inSection:1]: @"A2",
                           [NSIndexPath indexPathForItem:1 inSection:1]: @"B2",
                           }]
      build]
     stateListener:nil
     userInfo:nil],
    ];
  // Remove first item from each section
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withRemovedItems:[NSSet setWithArray:@[
                                           [NSIndexPath indexPathForItem:0 inSection:0],
                                           [NSIndexPath indexPathForItem:0 inSection:1],
                                           ]]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, pendingAsynchronousModifications), CKBadChangesetOperationTypeNone);
}

- (void)test_invalidChangesetAppliedToValidPendingAsynchronousModifications
{
  CKTransactionalComponentDataSourceState *state =
  [[CKTransactionalComponentDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[]];
  NSArray<id<CKTransactionalComponentDataSourceStateModifying>> *pendingAsynchronousModifications =
  @[
    // Insert section 0
    [[CKTransactionalComponentDataSourceChangesetModification alloc]
     initWithChangeset:
     [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
       withInsertedSections:[NSIndexSet indexSetWithIndex:0]]
      build]
     stateListener:nil
     userInfo:nil],
    // Insert two items into section 0
    [[CKTransactionalComponentDataSourceChangesetModification alloc]
     initWithChangeset:
     [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
       withInsertedItems:@{
                           [NSIndexPath indexPathForItem:0 inSection:0]: @"A1",
                           [NSIndexPath indexPathForItem:1 inSection:0]: @"B1",
                           }]
      build]
     stateListener:nil
     userInfo:nil],
    ];
  // Remove first item from section 1
  CKTransactionalComponentDataSourceChangeset *changeset =
  [[[CKTransactionalComponentDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withRemovedItems:[NSSet setWithArray:@[
                                           [NSIndexPath indexPathForItem:0 inSection:0],
                                           [NSIndexPath indexPathForItem:0 inSection:1],
                                           ]]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, pendingAsynchronousModifications), CKBadChangesetOperationTypeRemoveRow);
}

static CKTransactionalComponentDataSourceItem *itemWithModel(id model)
{
  return [[CKTransactionalComponentDataSourceItem alloc] initWithLayout:CKComponentLayout()
                                                                  model:model
                                                              scopeRoot:nil
                                                        boundsAnimation:{}];
}

@end
