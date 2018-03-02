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

#if !defined(NO_PROTOCOLS_IN_OBJCPP)
BOOL CKComponentBoundsAnimationPredicate(id<CKComponentProtocol> component)
#else
BOOL CKComponentBoundsAnimationPredicate(id component)
#endif
{
  return CKSubclassOverridesSelector([CKComponent class], [component class], @selector(boundsAnimationFromPreviousComponent:));
}

/** Filter components that their controllers override the 'didPrepareLayout:ForComponent:' method. */
#if !defined(NO_PROTOCOLS_IN_OBJCPP)
BOOL CKComponentDidPrepareLayoutForComponentToControllerPredicate(id<CKComponentProtocol> component)
#else
BOOL CKComponentDidPrepareLayoutForComponentToControllerPredicate(id component)
#endif
{
#if !defined(NO_PROTOCOLS_IN_OBJCPP)
  const Class<CKComponentControllerProtocol> controllerClass = [[component class] controllerClass];
#else
  const Class controllerClass = [[component class] controllerClass];
#endif
  return
  controllerClass
  && CKSubclassOverridesSelector([CKComponentController class],
                                 controllerClass,
                                 @selector(didPrepareLayout:forComponent:));
}

CKComponentBoundsAnimation CKComponentBoundsAnimationFromPreviousScopeRoot(CKComponentScopeRoot *newRoot, CKComponentScopeRoot *previousRoot)
{
  NSMapTable *const scopeFrameTokenToOldComponent = [NSMapTable strongToStrongObjectsMapTable];
  [previousRoot
   enumerateComponentsMatchingPredicate:&CKComponentBoundsAnimationPredicate
   block:^(id<CKComponentProtocol> component) {
     CKComponent *oldComponent = (CKComponent *)component;
     id scopeFrameToken = [oldComponent scopeFrameToken];
     if (scopeFrameToken) {
       [scopeFrameTokenToOldComponent setObject:oldComponent forKey:scopeFrameToken];
     }
   }];

  __block CKComponentBoundsAnimation boundsAnimation {};
  [newRoot
   enumerateComponentsMatchingPredicate:&CKComponentBoundsAnimationPredicate
   block:^(id<CKComponentProtocol> component) {
     CKComponent *newComponent = (CKComponent *)component;
     id scopeFrameToken = [newComponent scopeFrameToken];
     if (scopeFrameToken) {
       CKComponent *oldComponent = [scopeFrameTokenToOldComponent objectForKey:scopeFrameToken];
       if (oldComponent) {
         const CKComponentBoundsAnimation ba = [newComponent boundsAnimationFromPreviousComponent:oldComponent];
         if (ba.duration != 0) {
           boundsAnimation = ba;
         }
       }
     }
   }];
  return boundsAnimation;
}

void CKComponentSendDidPrepareLayoutForComponent(CKComponentScopeRoot *scopeRoot, const CKComponentLayout layout) {
  // Iterate over the components that their controllers override the 'didPrepareLayoutForComponent' method.
  [scopeRoot enumerateComponentsMatchingPredicate:&CKComponentDidPrepareLayoutForComponentToControllerPredicate
                                            block:^(id<CKComponentProtocol> c) {
                                              CKComponent *component = (CKComponent *)c;
                                              const CKComponentLayout componentLayout = layout.cachedLayoutForScopedComponent(c);
                                              [component.controller didPrepareLayout:componentLayout forComponent:component];
                                            }];
}
