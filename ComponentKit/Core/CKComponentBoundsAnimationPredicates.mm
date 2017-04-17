/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentBoundsAnimationPredicates.h"

#import "CKComponentInternal.h"
#import "CKComponentSubclass.h"
#import "CKInternalHelpers.h"

BOOL CKComponentBoundsAnimationPredicate(id<CKScopedComponent> component)
{
  return CKSubclassOverridesSelector([CKComponent class], [component class], @selector(boundsAnimationFromPreviousComponent:));
}
