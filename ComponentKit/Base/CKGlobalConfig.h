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

struct CKGlobalConfig {
  /** Can be used to trigger asserts for Render components even if there is no Render component in the tree */
  BOOL forceBuildRenderTreeInDebug = NO;
  int64_t yogaMeasureCacheSize = INT64_MAX;
  /** Used for testing performance implication of calling `invalidateController` between component generations */
  BOOL shouldInvalidateControllerBetweenComponentGenerationsInDataSource = NO;
  BOOL shouldInvalidateControllerBetweenComponentGenerationsInHostingView = NO;
};

CKGlobalConfig CKReadGlobalConfig();
