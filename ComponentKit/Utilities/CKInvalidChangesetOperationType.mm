/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKInvalidChangesetOperationType.h"

NSString *CKHumanReadableInvalidChangesetOperationType(CKInvalidChangesetOperationType type)
{
  switch (type) {
    case CKInvalidChangesetOperationTypeUpdate:
      return @"Update";
    case CKInvalidChangesetOperationTypeRemoveRow:
      return @"Row Removal";
    case CKInvalidChangesetOperationTypeRemoveSection:
      return @"Section Removal";
    case CKInvalidChangesetOperationTypeInsertSection:
      return @"Section Insertion";
    case CKInvalidChangesetOperationTypeMoveSection:
      return @"Section Move";
    case CKInvalidChangesetOperationTypeInsertRow:
      return @"Row Insertion";
    case CKInvalidChangesetOperationTypeMoveRow:
      return @"Row Move";
    case CKInvalidChangesetOperationTypeNone:
      return @"No Issue";
  }
}
