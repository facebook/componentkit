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

#import <ComponentKit/CKDataSourceQOS.h>

qos_class_t qosClassFromDataSourceQOS(CKDataSourceQOS qos);
dispatch_block_t blockUsingDataSourceQOS(dispatch_block_t block, CKDataSourceQOS qos);
