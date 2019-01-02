/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKBuildComponent.h>
#import <ComponentKit/CKComponentHostingView.h>
#import <ComponentKit/CKDimension.h>
#import <ComponentKit/CKComponentLayout.h>
#import <ComponentKit/CKComponentScopeHandle.h>
#import <ComponentKit/CKComponentScopeTypes.h>
#import <ComponentKit/CKComponentScopeEnumeratorProvider.h>
#import <ComponentKit/CKInspectableView.h>

#import <unordered_set>

struct CKComponentHostingViewOptions {
  /// Build and layout components in a unified pass. It's meant to be used only if buildComponentTree == YES; please DO NOT use it yet, it's in a testing stage. Default NO.
  BOOL unifyBuildAndLayout;
  /// If set to YES, allows taps to pass though this hosting view to views behind it. Default NO.
  BOOL allowTapPassthrough;
  /// If set to YES, value from global config will be overridden. Default NO.
  BOOL forceSizeCacheEnabled;
  // If set to YES, invalidates controllers that are removed whilst the hosting view remains alive. Default NO.
  BOOL invalidateRemovedControllers;
  /// Previously constructed scope root. This is specified in the case where component generation occurs before
  /// the component hosting view is created.
  ///
  /// The initial scope root must have been constructed using a proxy for the state listener that can be redirected
  /// to the component hosting view once it is constructed. Otherwise, the hosting view will not be able to receive and
  /// process state updates.
  CKComponentScopeRoot *previousScopeRoot;
  /// Previously constructed component corresponding to `previousScopeRoot`. If this is specified, the component
  /// hosting view will not trigger an update when it is initialized unless pending state updates are specified
  /// via the `pendingStateUpdates` option.
  CKComponent *previousComponent;
  /// If `initialScopeRoot` is specified, this can also be specified to give the hosting view a map of pending state
  /// updates that should be processed in the next update.
  CKComponentStateUpdateMap pendingStateUpdates;
};

@interface CKComponentHostingView () <CKInspectableView>

/**
 @param componentProvider  provider conforming to CKComponentProvider protocol.
 @param sizeRangeProvider sizing range provider conforming to CKComponentSizeRangeProviding.
 @param componentPredicates A vector of C functions that are executed on each component constructed within the scope
                            root. By passing in the predicates on initialization, we are able to cache which components
                            match the predicate for rapid enumeration later.
 @param componentControllerPredicates Same as componentPredicates above, but for component controllers.
 @param analyticsListener listener conforming to AnalyticsListener will be used to get component lifecycle callbacks for logging
 @param options Set of CKComponentHostingViewOptions
 @see CKComponentProvider
 @see CKComponentSizeRangeProviding
 */
- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider
                        sizeRangeProvider:(id<CKComponentSizeRangeProviding>)sizeRangeProvider
                      componentPredicates:(const std::unordered_set<CKComponentPredicate> &)componentPredicates
            componentControllerPredicates:(const std::unordered_set<CKComponentControllerPredicate> &)componentControllerPredicates
                        analyticsListener:(id<CKAnalyticsListener>)analyticsListener
                                  options:(const CKComponentHostingViewOptions &)options;

@property (nonatomic, strong, readonly) UIView *containerView;

/** Returns the current scope enumerator provider. Main thread only. */
- (id<CKComponentScopeEnumeratorProvider>)scopeEnumeratorProvider;

/** Applies a result from a component built outside the hosting view. Main thread only. */
- (void)applyResult:(const CKBuildComponentResult &)result;

/**
 Function for setting default analytics listener that will be used if CKComponentHostingView doesn't have one

 @param defaultListener Analytics listener to be used if CKComponentHostingView don't inject one

 @warning This method is affined to the main thread and should only be called from it.
          You shouldn't set analytics listener more then once - this will cause a confusion on which one is used.
          If you want to pass a custom analytics listener to a particular hosting view, please use
           initWithComponentProvider:sizeRangeProvider:analyticsListener: to create it
 */

+ (void)setDefaultAnalyticsListener:(id<CKAnalyticsListener>)defaultListener;

@end
