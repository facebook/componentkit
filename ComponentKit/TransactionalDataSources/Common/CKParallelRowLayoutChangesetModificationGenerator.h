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

#import <ComponentKit/CKDataSource.h>

/**
 This object can be used to generate changeset modifications which are not yet
 complete, but instead are scheduled concurrently on a row by row basis, and
 immediately passed on to the UI. This will enable a speedup in latency at the
 potential cost of scroll performance.
 
 NOTE: This is still highly experimental and likely should not yet be used in
 production unless you know what you're doing.
 */
@interface CKParallelRowLayoutChangesetModificationGenerator : NSObject <CKDataSourceChangesetModificationGenerator>

@end
