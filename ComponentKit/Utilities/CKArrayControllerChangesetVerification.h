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

#import <ComponentKit/CKArrayControllerChangeset.h>

typedef NS_ENUM(NSUInteger, CKBadChangesetOperationType) {
  CKBadChangesetOperationTypeNone,
  CKBadChangesetOperationTypeUpdate,
  CKBadChangesetOperationTypeInsertSection,
  CKBadChangesetOperationTypeInsertRow,
  CKBadChangesetOperationTypeRemoveSection,
  CKBadChangesetOperationTypeRemoveRow,
  CKBadChangesetOperationTypeMoveSection,
  CKBadChangesetOperationTypeMoveRow
};

/**
 This function determines whether a given changeset is valid for a particular data source state.
 In particular, if this function returns true, the caller is guaranteed that for the given
 data source state (sections parameter), applying the changeset will not cause an index out of
 bounds crash.

 @param changeset the changeset in question
 @param sections the current sections (or state) of the data source
 @return which section is causing an issue, if any. If there's no issue, this function will return CKBadChangesetOperationTypeNone
 */
CKBadChangesetOperationType CKIsValidChangesetForSections(CKArrayControllerInputChangeset changeset, NSArray<NSArray *> *sections);

/** This function takes a CKBadChangesetOperationType and returns a human readable string for it */
NSString *CKHumanReadableBadChangesetOperation(CKBadChangesetOperationType type);
