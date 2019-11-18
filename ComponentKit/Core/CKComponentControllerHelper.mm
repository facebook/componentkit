/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentControllerHelper.h"

#import <ComponentKit/CKComponentScopeRoot.h>

namespace CKComponentControllerHelper {
  auto removedControllersFromPreviousScopeRootMatchingPredicate(CKComponentScopeRoot *newRoot,
                                                                CKComponentScopeRoot *previousRoot,
                                                                CKComponentControllerPredicate predicate) -> std::vector<CKComponentController *>
  {
    if (!previousRoot) {
      return {};
    }
    const auto oldControllers = [previousRoot componentControllersMatchingPredicate:predicate];
    const auto newControllers = [newRoot componentControllersMatchingPredicate:predicate];
    const auto removedControllers = CK::Collection::difference(oldControllers,
                                                               newControllers,
                                                               [](const auto &lhs, const auto &rhs){
                                                                 return lhs == rhs;
                                                               });
    return CK::map(removedControllers, [](const auto controller){ return (CKComponentController *)controller; });
  }

  auto addedControllersFromPreviousScopeRootMatchingPredicate(CKComponentScopeRoot *newRoot,
                                                              CKComponentScopeRoot *previousRoot,
                                                              CKComponentControllerPredicate predicate) -> std::vector<CKComponentController *>
  {
    if (!newRoot) {
      return {};
    }

    const auto newControllers = [newRoot componentControllersMatchingPredicate:predicate];

    if (!previousRoot) {
      return CK::map(newControllers, [](const auto controller){ return (CKComponentController *)controller; });
    }
    const auto oldControllers = [previousRoot componentControllersMatchingPredicate:predicate];
    const auto addedControllers = CK::Collection::difference(newControllers,
                                                             oldControllers,
                                                             [](const auto &lhs, const auto &rhs){
                                                               return lhs == rhs;
                                                             });
    return CK::map(addedControllers, [](const auto controller){ return (CKComponentController *)controller; });
  }
};
