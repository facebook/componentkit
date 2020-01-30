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

#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKMountable.h>

@class CKDataSourceState;

/**
 A predicate that identifies if a component implements bounds animations. This predicate is passed to the scope root
 and is checked on the initialization of components and cached. This allows us to rapidly identify which components
 require animating.
 */
BOOL CKComponentBoundsAnimationPredicate(id<CKComponentProtocol> component);

auto CKComponentHasAnimationsOnInitialMountPredicate(id<CKMountable> const c) -> BOOL;
auto CKComponentHasAnimationsFromPreviousComponentPredicate(id<CKMountable> const c) -> BOOL;
auto CKComponentHasAnimationsOnFinalUnmountPredicate(id<CKMountable> const c) -> BOOL;

/**
 A predicate that identifies a component that it's controller overrides the 'didPrepareLayout:forComponent:' method.
 */
BOOL CKComponentDidPrepareLayoutForComponentToControllerPredicate(id<CKComponentProtocol> component);

/**
 Iterates over the components that their controller overrides 'didPrepareLayout:ForComponent:' and send the callback.
 */
void CKComponentSendDidPrepareLayoutForComponent(CKComponentScopeRoot *scopeRoot, const CKComponentRootLayout &layout);

/**
 Call 'CKComponentSendDidPrepareLayoutForComponent' with objects in indexPaths of CKDataSourceState
 */
void CKComponentSendDidPrepareLayoutForComponentsWithIndexPaths(id<NSFastEnumeration> indexPaths,
                                                                CKDataSourceState *state);

/**
 Update component of component controller in component trees of `indexPaths`of CKDataSourceState
 */
void CKComponentUpdateComponentForComponentControllerWithIndexPaths(id<NSFastEnumeration> indexPaths,
                                                                    CKDataSourceState *state,
                                                                    BOOL shouldUpdateComponentOverride);

#endif
