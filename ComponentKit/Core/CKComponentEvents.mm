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


#import "CKComponentInternal.h"
#import "CKComponentControllerInternal.h"
#import "CKComponentSubclass.h"
#import "CKInternalHelpers.h"
#import "CKComponentProtocol.h"
#import "CKDataSourceItem.h"
#import "CKDataSourceState.h"

BOOL CKComponentBoundsAnimationPredicate(id<CKComponentProtocol> component)
{
  return CKSubclassOverridesInstanceMethod([CKComponent class], [component class], @selector(boundsAnimationFromPreviousComponent:));
}

/** Filter components that their controllers override the 'didPrepareLayout:ForComponent:' method. */
BOOL CKComponentDidPrepareLayoutForComponentToControllerPredicate(id<CKComponentProtocol> component)
{
  const Class<CKComponentControllerProtocol> controllerClass = [[component class] controllerClass];
  return
  controllerClass
  && CKSubclassOverridesInstanceMethod([CKComponentController class],
                                 controllerClass,
                                 @selector(didPrepareLayout:forComponent:));
}

auto CKComponentHasAnimationsOnInitialMountPredicate(id<CKMountable> const c) -> BOOL
{
  return CKSubclassOverridesInstanceMethod([CKComponent class], [c class], @selector(animationsOnInitialMount));
}

auto CKComponentHasAnimationsFromPreviousComponentPredicate(id<CKMountable> const c) -> BOOL
{
  return CKSubclassOverridesInstanceMethod([CKComponent class], [c class], @selector(animationsFromPreviousComponent:));
}

auto CKComponentHasAnimationsOnFinalUnmountPredicate(id<CKMountable> const c) -> BOOL
{
  return CKSubclassOverridesInstanceMethod([CKComponent class], [c class], @selector(animationsOnFinalUnmount));
}

void CKComponentSendDidPrepareLayoutForComponent(CKComponentScopeRoot *scopeRoot, const CKComponentRootLayout &layout)
{
  // Iterate over the components that their controllers override the 'didPrepareLayoutForComponent' method.
  [scopeRoot enumerateComponentsMatchingPredicate:&CKComponentDidPrepareLayoutForComponentToControllerPredicate
                                            block:^(id<CKComponentProtocol> c) {
                                              CKComponent *component = (CKComponent *)c;
                                              const CKComponentLayout componentLayout = layout.cachedLayoutForComponent(component);
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
    item.rootLayout.enumerateCachedLayout(^(const CKComponentLayout &layout) {
      const auto component = (CKComponent *)layout.component;
      component.controller.latestComponent = component;
    });
  }
}
