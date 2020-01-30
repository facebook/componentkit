/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKDefines.h>

#if CK_NOT_SWIFT

#import <Foundation/Foundation.h>

#import <vector>

#import <ComponentKit/CKComponentScopeTypes.h>

@class CKComponentController;
@class CKComponentScopeRoot;

namespace CKComponentControllerHelper {
  /**
   Return component controllers, which match the predicate, were just added in the new scope root.
   */
  auto addedControllersFromPreviousScopeRootMatchingPredicate(CKComponentScopeRoot *newRoot,
                                                              CKComponentScopeRoot *previousRoot,
                                                              CKComponentControllerPredicate predicate) -> std::vector<CKComponentController *>;

  /**
   Return component controllers, which match the predicate, that are not presented in the new scope root.
   */
  auto removedControllersFromPreviousScopeRootMatchingPredicate(CKComponentScopeRoot *newRoot,
                                                                CKComponentScopeRoot *previousRoot,
                                                                CKComponentControllerPredicate predicate) -> std::vector<CKComponentController *>;
};

#endif
