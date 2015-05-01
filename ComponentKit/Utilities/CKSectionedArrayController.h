/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <memory>

#import <Foundation/Foundation.h>

#import <ComponentKit/CKArrayControllerChangeset.h>

/**
 Manages an array of objects bucketed into sections. Suitable for using to manage the backing data for a UITableView
 or UICollectionView.

 The array controller is mutated by constructing a list of commands: insert, remove, update, which are then applied in
 a single "transaction" to the array controller. In response to a mutation, the array controller reutrns a list of
 changes that can be used to mutate a UITableView or UICollectionView.

 We make only minimal attempts to ensure that the indexes (index paths) passed are at all "valid", duplicate commands
 will throw NSInvalidArgumentExceptions. Out-of-bounds access, even with commands passed to -applyChangeset: will also
 throw.

 We've wholesale copied the contract of UITableView mutations (because it's simple to implement and you might already
 know it). See -applyChangeset:

 See also CKArrayControllerChangeset.h.
*/
@interface CKSectionedArrayController : NSObject

- (NSInteger)numberOfSections;

- (NSInteger)numberOfObjectsInSection:(NSInteger)section;

- (id<NSObject>)objectAtIndexPath:(NSIndexPath *)indexPath;

typedef void (^CKSectionedArrayControllerEnumerator)(id<NSObject> object, NSIndexPath *indexPath, BOOL *stop);

/**
 Enumerates over all items in ascending order of index path.
 @param enumerator A block invoked for each item in the receiver.
 */
- (void)enumerateObjectsUsingBlock:(CKSectionedArrayControllerEnumerator)enumerator;

/**
 Enumerates over all items in the given section in ascending order of index path.
 @param enumerator A block invoked for each item in the section in the receiver.
 */
- (void)enumerateObjectsInSectionAtIndex:(NSInteger)sectionIndex usingBlock:(CKSectionedArrayControllerEnumerator)enumerator;

typedef BOOL(^CKSectionedArrayControllerPredicate)(id<NSObject>, NSIndexPath *, BOOL *);

- (std::pair<id<NSObject>, NSIndexPath *>)firstObjectPassingTest:(CKSectionedArrayControllerPredicate)predicate;

/**
 Iterates over the input commands and changes our internal sections array accordingly.

 The indexes in the input changeset are applied to the reciever in the following order:

 1) item updates
 2) item removals
 3) section removals
 4) section insertions
 5) item insertions

 To do so:
 1) index paths for updates and removals MUST be relative to the initial state of the array controller.
 2) index paths for insertions MUST be relative post-application of removal operations.

 The obvious side-effect of this:
 1) Updating an item and subsequently removing the section in which the item resides is wasteful.

 @param changeset The commands (create, update, delete) to apply to our array controller.
 @returns A changeset that describes operations that we can directly apply to a UITableView or UICollectionView.
 */
- (CKArrayControllerOutputChangeset)applyChangeset:(CKArrayControllerInputChangeset)changeset;

@end
