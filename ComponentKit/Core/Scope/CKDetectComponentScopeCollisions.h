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

struct CKComponentLayout;

/**
 Detects, and reports, component scope collisions found in the given component layout.
 @param layout The top-level component layout of the component hierarchy.
 */
void CKDetectComponentScopeCollisions(const CKComponentLayout &layout);
