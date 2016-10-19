/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKBadChangesetOperationType.h"

NSString *CKHumanReadableBadChangesetOperationType(CKBadChangesetOperationType type)
{
  switch (type) {
    case CKBadChangesetOperationTypeUpdate:
      return @"Bad Update";
    case CKBadChangesetOperationTypeRemoveRow:
      return @"Bad Row Removal";
    case CKBadChangesetOperationTypeRemoveSection:
      return @"Bad Section Removal";
    case CKBadChangesetOperationTypeInsertSection:
      return @"Bad Section Insertion";
    case CKBadChangesetOperationTypeMoveSection:
      return @"Bad Section Move";
    case CKBadChangesetOperationTypeInsertRow:
      return @"Bad Row Insertion";
    case CKBadChangesetOperationTypeMoveRow:
      return @"Bad Row Move";
    case CKBadChangesetOperationTypeNone:
      return @"No Issue";
  }
}
