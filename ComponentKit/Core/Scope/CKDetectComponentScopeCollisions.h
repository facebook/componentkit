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
@class CKComponent;

/** Represents a component scope collision. contains the component with the collision, the lowest common ancestor of the colliding components and the backtrace description */
struct CKComponentCollision {
  CKComponent *component;
  CKComponent *lowestCommonAncestor;
  NSString *backtraceDescription;
  
  bool hasCollision() const {
    return (component != nil);
  }
};

/**
 Helper function to detect component scope collisions found in the given component layout.
 @param layout The top-level component layout of the component hierarchy.
 @return struct that contains the component with collision, the lowest common ancestor and the backtrace description
 */
CKComponentCollision CKFindComponentScopeCollision(const CKComponentLayout &layout);

/**
 Detects, and reports, component scope collisions found in the given component layout.
 @param layout The top-level component layout of the component hierarchy.
 */
void CKDetectComponentScopeCollisions(const CKComponentLayout &layout);
