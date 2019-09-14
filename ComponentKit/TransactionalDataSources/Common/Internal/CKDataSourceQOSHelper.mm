/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKDataSourceQOSHelper.h"

static qos_class_t qosClassFromDataSourceQOS(CKDataSourceQOS qos)
{
  switch (qos) {
    case CKDataSourceQOSUserInteractive:
      return QOS_CLASS_USER_INTERACTIVE;
    case CKDataSourceQOSUserInitiated:
      return QOS_CLASS_USER_INITIATED;
    case CKDataSourceQOSDefault:
      return QOS_CLASS_DEFAULT;
  }
}

dispatch_block_t blockUsingDataSourceQOS(dispatch_block_t block, CKDataSourceQOS qos, BOOL isBackgroundMode)
{
  switch (qos) {
    case CKDataSourceQOSUserInteractive:
    case CKDataSourceQOSUserInitiated:
      return dispatch_block_create_with_qos_class(DISPATCH_BLOCK_ENFORCE_QOS_CLASS, qosClassFromDataSourceQOS(qos), 0, block);
    case CKDataSourceQOSDefault:
      if (isBackgroundMode) {
        /// We should enforce the block to be executed with `QOS_CLASS_BACKGROUND` if background mode is on.
        return dispatch_block_create_with_qos_class(DISPATCH_BLOCK_ENFORCE_QOS_CLASS, QOS_CLASS_BACKGROUND, 0, block);
      } else {
        /// If the desired QOS is the default there is no need to enforce it by dispatching async on the _workQueue defined QOS.
        return block;
      }
  }
}
