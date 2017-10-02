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
#import <ComponentKit/CKDataSourceChangeset.h>
#import <ComponentKit/CKDataSourceChangesetModification.h>
#import <ComponentKit/CKDataSourceItemInternal.h>
#import <ComponentKit/CKDataSourceStateInternal.h>

#import "CKDataSourceChangesetVerification.h"

@interface CKDataSourceChangesetVerificationTests : XCTestCase
@end

@implementation CKDataSourceChangesetVerificationTests

#pragma mark - Valid changesets

- (void)test_emptyChangesetEmptySections
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[]];
  CKDataSourceChangeset *changeset =
  [[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeNone);
}

- (void)test_emptyChangesetNonEmptySections
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
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
  CKDataSourceChangeset *changeset =
  [[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeNone);
}

- (void)test_nonEmptyChangesetEmptySections
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[]];
  CKDataSourceChangeset *changeset =
  [[[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
     withInsertedSections:[NSIndexSet indexSetWithIndex:0]]
    withInsertedItems:@{
                       [NSIndexPath indexPathForItem:0 inSection:0]: @"A",
                       [NSIndexPath indexPathForItem:1 inSection:0]: @"B",
                       }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeNone);
}

- (void)test_validInsertionIntoEmptySection
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[],
                                                                           ]];
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withInsertedItems:@{
                        [NSIndexPath indexPathForItem:0 inSection:0]: @"A",
                        [NSIndexPath indexPathForItem:1 inSection:0]: @"B",
                        }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeNone);
}

- (void)test_validInsertionIntoBeginningOfNonEmptySection
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withInsertedItems:@{
                        [NSIndexPath indexPathForItem:0 inSection:0]: @"A",
                        [NSIndexPath indexPathForItem:1 inSection:0]: @"B",
                        }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeNone);
}

- (void)test_validInsertionIntoMiddleOfNonEmptySection
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withInsertedItems:@{
                        [NSIndexPath indexPathForItem:1 inSection:0]: @"A",
                        [NSIndexPath indexPathForItem:2 inSection:0]: @"B",
                        }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeNone);
}

- (void)test_validInsertionAtEndOfNonEmptySection
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withInsertedItems:@{
                        [NSIndexPath indexPathForItem:2 inSection:0]: @"A",
                        [NSIndexPath indexPathForItem:3 inSection:0]: @"B",
                        }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeNone);
}

- (void)test_validRemovalAtBeginningOfSection
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             itemWithModel(@"E"),
                                                                             ],
                                                                           ]];
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withRemovedItems:[NSSet setWithArray:@[
                                           [NSIndexPath indexPathForItem:0 inSection:0],
                                           ]]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeNone);
}

- (void)test_validRemovalAtMiddleOfSection
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             itemWithModel(@"E"),
                                                                             ],
                                                                           ]];
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withRemovedItems:[NSSet setWithArray:@[
                                           [NSIndexPath indexPathForItem:1 inSection:0],
                                           ]]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeNone);
}

- (void)test_validRemovalAtEndOfSection
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             itemWithModel(@"E"),
                                                                             ],
                                                                           ]];
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withRemovedItems:[NSSet setWithArray:@[
                                           [NSIndexPath indexPathForItem:2 inSection:0],
                                           ]]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeNone);
}

- (void)test_validRemovalOfAllItems
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             itemWithModel(@"E"),
                                                                             ],
                                                                           ]];
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withRemovedItems:[NSSet setWithArray:@[
                                           [NSIndexPath indexPathForItem:2 inSection:0],
                                           [NSIndexPath indexPathForItem:1 inSection:0],
                                           [NSIndexPath indexPathForItem:0 inSection:0],
                                           ]]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeNone);
}

- (void)test_validInsertionOfSectionInEmptySections
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[]];
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withInsertedSections:[NSIndexSet indexSetWithIndex:0]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeNone);
}

- (void)test_validInsertionOfSectionAtBeginningOfNonEmptySections
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
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
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withInsertedSections:[NSIndexSet indexSetWithIndex:0]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeNone);
}

- (void)test_validInsertionOfSectionInMiddleOfNonEmptySections
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
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
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withInsertedSections:[NSIndexSet indexSetWithIndex:1]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeNone);
}

- (void)test_validInsertionOfSectionAtEndOfNonEmptySections
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
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
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withInsertedSections:[NSIndexSet indexSetWithIndex:2]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeNone);
}

- (void)test_validInsertionOfMultipleSections
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
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
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withInsertedSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeNone);
}

- (void)test_removalOfSectionAtBeginningOfSections
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
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
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withRemovedSections:[NSIndexSet indexSetWithIndex:0]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeNone);
}

- (void)test_removalOfSectionAtMiddleOfSections
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
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
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withRemovedSections:[NSIndexSet indexSetWithIndex:1]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeNone);
}

- (void)test_removalOfSectionAtEndOfSections
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
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
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withRemovedSections:[NSIndexSet indexSetWithIndex:2]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeNone);
}

- (void)test_removeMultipleSectionsAtBeginningOfSections
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
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
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withRemovedSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeNone);
}

- (void)test_removeMultipleSectionsAtEndOfSections
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
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
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withRemovedSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeNone);
}

- (void)test_validUpdate
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withUpdatedItems:@{
                       [NSIndexPath indexPathForItem:0 inSection:0]: @"A",
                       }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeNone);
}

- (void)test_validMoveForwardInsideOneSection
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withMovedItems:@{
                     [NSIndexPath indexPathForItem:0 inSection:0]: [NSIndexPath indexPathForItem:1 inSection:0],
                     }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeNone);
}

- (void)test_validMoveBackwardInsideOneSection
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withMovedItems:@{
                     [NSIndexPath indexPathForItem:1 inSection:0]: [NSIndexPath indexPathForItem:0 inSection:0],
                     }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeNone);
}

- (void)test_validMoveForwardBetweenSections
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
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
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withMovedItems:@{
                     [NSIndexPath indexPathForItem:0 inSection:0]: [NSIndexPath indexPathForItem:2 inSection:1],
                     }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeNone);
}

- (void)test_validMoveBackwardBetweenSections
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
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
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withMovedItems:@{
                     [NSIndexPath indexPathForItem:0 inSection:1]: [NSIndexPath indexPathForItem:2 inSection:0],
                     }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeNone);
}

- (void)test_validMoveBackwardWithOriginalIndexRemoved
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"A"),
                                                                             itemWithModel(@"B"),
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                            ]];
  // Changeset for transition from [A, B, C, D] to [D, A]
  CKDataSourceChangeset *changeset =
  [[[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
     withMovedItems:@{
                      [NSIndexPath indexPathForItem:3 inSection:0] : [NSIndexPath indexPathForItem:0 inSection:0],
                      }]
    withRemovedItems:[NSSet setWithArray:@[
                                           [NSIndexPath indexPathForItem:1 inSection:0],
                                           [NSIndexPath indexPathForItem:2 inSection:0],
                                           ]]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeNone);
}

#pragma mark - Invalid changesets

- (void)test_invalidUpdateInNegativeSection
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withUpdatedItems:@{
                       [NSIndexPath indexPathForItem:1 inSection:-1]: @"A",
                       }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeUpdate);
}

- (void)test_invalidUpdateInNegativeItem
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withUpdatedItems:@{
                       [NSIndexPath indexPathForItem:-1 inSection:0]: @"A",
                       }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeUpdate);
}

- (void)test_invalidInsertionAtEndOfSection
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withInsertedItems:@{
                        [NSIndexPath indexPathForItem:3 inSection:0]: @"A",
                        }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeInsertRow);
}

- (void)test_invalidMultipleInsertionAtEndOfSection
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withInsertedItems:@{
                        [NSIndexPath indexPathForItem:2 inSection:0]: @"A",
                        [NSIndexPath indexPathForItem:4 inSection:0]: @"B",
                        [NSIndexPath indexPathForItem:5 inSection:0]: @"E",
                        }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeInsertRow);
}

- (void)test_invalidInsertionInNonExistentSection
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withInsertedItems:@{
                        [NSIndexPath indexPathForItem:0 inSection:1]: @"A",
                        }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeInsertRow);
}

- (void)test_invalidRemovalInValidSection
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withRemovedItems:[NSSet setWithArray:@[
                                           [NSIndexPath indexPathForItem:2 inSection:0],
                                           ]]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeRemoveRow);
}

- (void)test_invalidRemovalInNonExistentSection
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withRemovedItems:[NSSet setWithArray:@[
                                           [NSIndexPath indexPathForItem:0 inSection:1],
                                           ]]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeRemoveRow);
}

- (void)test_invalidInsertionOfSection
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withInsertedSections:[NSIndexSet indexSetWithIndex:2]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeInsertSection);
}

- (void)test_invalidRemovalOfSection
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withRemovedSections:[NSIndexSet indexSetWithIndex:2]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeRemoveSection);
}

- (void)test_invalidUpdateWithinExistingSection
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withUpdatedItems:@{
                       [NSIndexPath indexPathForItem:2 inSection:0]: @"A",
                       }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeUpdate);
}

- (void)test_invalidUpdateWithinNonExistentSection
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withUpdatedItems:@{
                       [NSIndexPath indexPathForItem:0 inSection:1]: @"A",
                       }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeUpdate);
}

- (void)test_moveWithInvalidOriginIndexPathInExistingSection
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withMovedItems:@{
                     [NSIndexPath indexPathForItem:2 inSection:0]: [NSIndexPath indexPathForItem:0 inSection:0],
                     }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeMoveRow);
}

- (void)test_moveWithInvalidDestinationIndexPathInExistingSection
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withMovedItems:@{
                     [NSIndexPath indexPathForItem:0 inSection:0]: [NSIndexPath indexPathForItem:2 inSection:0],
                     }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeMoveRow);
}

- (void)test_moveWithInvalidOriginSection
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withMovedItems:@{
                     [NSIndexPath indexPathForItem:0 inSection:1]: [NSIndexPath indexPathForItem:0 inSection:0],
                     }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeMoveRow);
}

- (void)test_moveWithInvalidDestinationSection
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[
                                                                           @[
                                                                             itemWithModel(@"C"),
                                                                             itemWithModel(@"D"),
                                                                             ],
                                                                           ]];
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withMovedItems:@{
                     [NSIndexPath indexPathForItem:0 inSection:0]: [NSIndexPath indexPathForItem:0 inSection:1],
                     }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeMoveRow);
}

#pragma mark - More complicated situations

- (void)test_validInitialSectionInsertionsWithItemInsertions
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[]];
  CKDataSourceChangeset *changeset =
  [[[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
     withInsertedSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]]
    withInsertedItems:@{
                        [NSIndexPath indexPathForItem:0 inSection:0]: @"A1",
                        [NSIndexPath indexPathForItem:1 inSection:0]: @"B1",
                        [NSIndexPath indexPathForItem:0 inSection:1]: @"A2",
                        [NSIndexPath indexPathForItem:1 inSection:1]: @"B2",
                        }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, nil), CKInvalidChangesetOperationTypeNone);
}

- (void)test_validInitialSectionInsertionsInPendingAsynchronousModificationWithItemInsertions
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[]];
  NSArray<id<CKDataSourceStateModifying>> *pendingAsynchronousModifications =
  @[
    // Insert section 0 and section 1
    [[CKDataSourceChangesetModification alloc]
     initWithChangeset:
     [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
       withInsertedSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]]
      build]
     stateListener:nil
     userInfo:nil],
    ];
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withInsertedItems:@{
                        [NSIndexPath indexPathForItem:0 inSection:0]: @"A1",
                        [NSIndexPath indexPathForItem:1 inSection:0]: @"B1",
                        [NSIndexPath indexPathForItem:0 inSection:1]: @"A2",
                        [NSIndexPath indexPathForItem:1 inSection:1]: @"B2",
                        }]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, pendingAsynchronousModifications), CKInvalidChangesetOperationTypeNone);
}

- (void)test_validChangesetAppliedToValidPendingAsynchronousModifications
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[]];
  NSArray<id<CKDataSourceStateModifying>> *pendingAsynchronousModifications =
  @[
    // Insert section 0
    [[CKDataSourceChangesetModification alloc]
     initWithChangeset:
     [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
       withInsertedSections:[NSIndexSet indexSetWithIndex:0]]
      build]
     stateListener:nil
     userInfo:nil],
    // Insert two items into section 0
    [[CKDataSourceChangesetModification alloc]
     initWithChangeset:
     [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
       withInsertedItems:@{
                           [NSIndexPath indexPathForItem:0 inSection:0]: @"A1",
                           [NSIndexPath indexPathForItem:1 inSection:0]: @"B1",
                           }]
      build]
     stateListener:nil
     userInfo:nil],
    // Insert section 1
    [[CKDataSourceChangesetModification alloc]
     initWithChangeset:
     [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
       withInsertedSections:[NSIndexSet indexSetWithIndex:1]]
      build]
     stateListener:nil
     userInfo:nil],
    // Insert two items into section 1
    [[CKDataSourceChangesetModification alloc]
     initWithChangeset:
     [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
       withInsertedItems:@{
                           [NSIndexPath indexPathForItem:0 inSection:1]: @"A2",
                           [NSIndexPath indexPathForItem:1 inSection:1]: @"B2",
                           }]
      build]
     stateListener:nil
     userInfo:nil],
    ];
  // Remove first item from each section
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withRemovedItems:[NSSet setWithArray:@[
                                           [NSIndexPath indexPathForItem:0 inSection:0],
                                           [NSIndexPath indexPathForItem:0 inSection:1],
                                           ]]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, pendingAsynchronousModifications), CKInvalidChangesetOperationTypeNone);
}

- (void)test_invalidChangesetAppliedToValidPendingAsynchronousModifications
{
  CKDataSourceState *state =
  [[CKDataSourceState alloc] initWithConfiguration:nil
                                                                sections:@[]];
  NSArray<id<CKDataSourceStateModifying>> *pendingAsynchronousModifications =
  @[
    // Insert section 0
    [[CKDataSourceChangesetModification alloc]
     initWithChangeset:
     [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
       withInsertedSections:[NSIndexSet indexSetWithIndex:0]]
      build]
     stateListener:nil
     userInfo:nil],
    // Insert two items into section 0
    [[CKDataSourceChangesetModification alloc]
     initWithChangeset:
     [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
       withInsertedItems:@{
                           [NSIndexPath indexPathForItem:0 inSection:0]: @"A1",
                           [NSIndexPath indexPathForItem:1 inSection:0]: @"B1",
                           }]
      build]
     stateListener:nil
     userInfo:nil],
    ];
  // Remove first item from section 1
  CKDataSourceChangeset *changeset =
  [[[CKDataSourceChangesetBuilder transactionalComponentDataSourceChangeset]
    withRemovedItems:[NSSet setWithArray:@[
                                           [NSIndexPath indexPathForItem:0 inSection:0],
                                           [NSIndexPath indexPathForItem:0 inSection:1],
                                           ]]]
   build];
  XCTAssertEqual(CKIsValidChangesetForState(changeset, state, pendingAsynchronousModifications), CKInvalidChangesetOperationTypeRemoveRow);
}

static CKDataSourceItem *itemWithModel(id model)
{
  return [[CKDataSourceItem alloc] initWithLayout:CKComponentLayout()
                                                                  model:model
                                                              scopeRoot:nil
                                                        boundsAnimation:{}];
}

@end
