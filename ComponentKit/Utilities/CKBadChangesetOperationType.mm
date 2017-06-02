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
      return @"Update";
    case CKBadChangesetOperationTypeRemoveRow:
      return @"Row Removal";
    case CKBadChangesetOperationTypeRemoveSection:
      return @"Section Removal";
    case CKBadChangesetOperationTypeInsertSection:
      return @"Section Insertion";
    case CKBadChangesetOperationTypeMoveSection:
      return @"Section Move";
    case CKBadChangesetOperationTypeInsertRow:
      return @"Row Insertion";
    case CKBadChangesetOperationTypeMoveRow:
      return @"Row Move";
    case CKBadChangesetOperationTypeNone:
      return @"No Issue";
  }
}
