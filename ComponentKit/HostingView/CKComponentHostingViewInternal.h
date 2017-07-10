/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKComponentHostingView.h>
#import <ComponentKit/CKDimension.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentScopeTypes.h>

#import <unordered_set>

@interface CKComponentHostingView ()

/**
 @param componentProvider See @protocol(CKComponentProvider).
 @param sizeRangeProvider See @protocol(CKComponentSizeRangeProviding).
 @param componentPredicates A vector of C functions that are executed on each component constructed within the scope
                            root. By passing in the predicates on initialization, we are able to cache which components
                            match the predicate for rapid enumeration later.
 @param componentControllerPredicates Same as componentPredicates above, but for component controllers.
 */
- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider
                        sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider
                      componentPredicates:(const std::unordered_set<CKComponentScopePredicate> &)componentPredicates
            componentControllerPredicates:(const std::unordered_set<CKComponentControllerScopePredicate> &)componentControllerPredicates;

@property (nonatomic, strong, readonly) UIView *containerView;

/** Returns the layout that's currently mounted. Main thread only. */
- (const CKComponentLayout &)mountedLayout;

/** Returns the current scope enumerator provider. Main thread only. */
- (id<CKComponentScopeEnumeratorProvider>)scopeEnumeratorProvider;

@end
