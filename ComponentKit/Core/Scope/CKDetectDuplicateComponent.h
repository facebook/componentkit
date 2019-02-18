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

/** Represents an info for a component that is being used more than once in a component tree */
struct CKDuplicateComponentInfo {
  /**
   The component that is being used more than once.
   @var CKComponent
   */
  CKComponent *component;

  /**
   The backtrace description starting from the component.
   @var NSString
   */
  NSString *backtraceDescription;
};

CKDuplicateComponentInfo CKFindDuplicateComponent(const CKComponentLayout &layout);

/**
 Detects, and reports, duplicate usage of a component found in the given component layout.
 @param layout The top-level component layout of the component hierarchy.
 */
 void CKDetectDuplicateComponent(const CKComponentLayout &layout);
