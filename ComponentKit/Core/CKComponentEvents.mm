/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentEvents.h"

#import <ComponentKit/CKInternalHelpers.h>

#import "CKComponentInternal.h"
#import "CKComponentControllerInternal.h"
#import "CKComponentSubclass.h"
#import "CKComponentProtocol.h"
#import "CKDataSourceItem.h"
#import "CKDataSourceState.h"

BOOL CKComponentBoundsAnimationPredicate(id<CKComponentProtocol> component)
{
  if ([component.class isSubclassOfClass:[CKComponent class]]) {
    return [(CKComponent *)component hasBoundsAnimations];
  } else {
    return NO;
  }
}

/** Filter components that their controllers override the 'didPrepareLayout:ForComponent:' method. */
BOOL CKComponentDidPrepareLayoutForComponentToControllerPredicate(id<CKComponentProtocol> component)
{
  if ([component.class isSubclassOfClass:[CKComponent class]]) {
    return [(CKComponent *)component controllerOverridesDidPrepareLayout];
  } else {
    return NO;
  }
}

auto CKComponentHasAnimationsOnInitialMountPredicate(id<CKMountable> const c) -> BOOL
{
  if ([c.class isSubclassOfClass:[CKComponent class]]) {
    return [(CKComponent *)c hasInitialMountAnimations];
  } else {
    return NO;
  }
}

auto CKComponentHasAnimationsFromPreviousComponentPredicate(id<CKMountable> const c) -> BOOL
{
  if ([c.class isSubclassOfClass:[CKComponent class]]) {
    return [(CKComponent *)c hasAnimations];
  } else {
    return NO;
  }
}

auto CKComponentHasAnimationsOnFinalUnmountPredicate(id<CKMountable> const c) -> BOOL
{
  if ([c.class isSubclassOfClass:[CKComponent class]]) {
    return [(CKComponent *)c hasFinalUnmountAnimations];
  } else {
    return NO;
  }
}

void CKComponentSendDidPrepareLayoutForComponent(id<CKComponentScopeEnumeratorProvider> scopeEnumeratorProvider, const CKComponentRootLayout &layout)
{
  // Iterate over the components that their controllers override the 'didPrepareLayoutForComponent' method.
  [scopeEnumeratorProvider enumerateComponentsMatchingPredicate:&CKComponentDidPrepareLayoutForComponentToControllerPredicate
                                                          block:^(id<CKComponentProtocol> c) {
    CKComponent *component = (CKComponent *)c;
    const RCLayout componentLayout = layout.cachedLayoutForComponent(component);
    [component.controller didPrepareLayout:componentLayout forComponent:component];
  }];
}

void CKComponentSendDidPrepareLayoutForComponentsWithIndexPaths(id<NSFastEnumeration> indexPaths,
                                                                CKDataSourceState *state)
{
  for (NSIndexPath *indexPath in indexPaths) {
    CKDataSourceItem *item = [state objectAtIndexPath:indexPath];
    CKComponentSendDidPrepareLayoutForComponent(item.scopeRoot, item.rootLayout);
  }
}

void CKComponentUpdateComponentForComponentControllerWithIndexPaths(id<NSFastEnumeration> indexPaths,
                                                                    CKDataSourceState *state)
{
  for (NSIndexPath *indexPath in indexPaths) {
    CKDataSourceItem *item = [state objectAtIndexPath:indexPath];
    item.rootLayout.enumerateCachedLayout(^(const RCLayout &layout) {
      const auto component = (CKComponent *)layout.component;
      component.controller.latestComponent = component;
    });
  }
}
