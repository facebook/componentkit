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

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

#import <unordered_set>

#import <ComponentKit/CKBuildComponentResult.h>
#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/CKComponentScopeTypes.h>
#import <ComponentKit/CKMacros.h>
#import <ComponentKit/CKNonNull.h>
#import <ComponentKit/CKUpdateMode.h>

@class CKComponentGenerator;
@class CKComponentScopeRoot;
@protocol CKAnalyticsListener;

@protocol CKComponentGeneratorDelegate <NSObject>

/**
 This is called on the affined queue before applying result from asynchronous generation.
 It gives a chance to discard the result by returning `NO`.
 */
- (BOOL)componentGeneratorShouldApplyAsynchronousGenerationResult:(CKComponentGenerator *)componentGenerator;

/**
 This is called on the affined queue when asynchronous component generation is finished.
 */
- (void)componentGenerator:(CKComponentGenerator *)componentGenerator didAsynchronouslyGenerateComponentResult:(CKBuildComponentResult)result;

/**
 This is called on the affined queue when a component state update is received.
 You should normally call either `generateComponentSynchronously` or `generateComponentAsynchronously` after this delegate method is called.
 */
- (void)componentGenerator:(CKComponentGenerator *)componentGenerator didReceiveComponentStateUpdateWithMode:(CKUpdateMode)mode;

@end

struct CKComponentGeneratorOptions {
  /**
   A required option that makes sure callsite reacts to important events from `CKComponentGenerator`.
   */
  CK::NonNull<id<CKComponentGeneratorDelegate>> delegate;

  /**
   A `componentProvider` block that is called when generate component.
   */
  CK::NonNull<CKComponentProviderBlock> componentProvider;

  /**
   Optional `componentPredicates` that is used for creating `CKComponentScopeRoot`.
   @see `CKComponentPredicate`
   */
  std::unordered_set<CKComponentPredicate> componentPredicates = {};

  /**
   Optional `componentControllerPredicates` that is used for creating `CKComponentScopeRoot`.
   @see `CKComponentControllerPredicate`
   */
  std::unordered_set<CKComponentControllerPredicate> componentControllerPredicates = {};

  /**
   Specify if you would like to override the default `CKAnalyticsListener`.
   */
  id<CKAnalyticsListener> analyticsListener = nil;

  /**
   A queue that is used to perform all majors tasks in `CKComponentGenerator`.
   All public APIs of `CKComponentGenerator` must be called on this queue.
   Defaults to main queue.
   */
  dispatch_queue_t affinedQueue = dispatch_get_main_queue();
};

/**
 `CKComponentGenerator` is responsibile for maintaining scope root, generating component and listening to component state update.
 It exposes methods to generate component synchronously and asynchronously.
 All APIs should be called on the `affinedQueue` that is passed in from `CKComponentGeneratorOptions`.
 */
@interface CKComponentGenerator : NSObject

- (instancetype)initWithOptions:(const CKComponentGeneratorOptions &)options NS_DESIGNATED_INITIALIZER;
- (instancetype)init CK_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE;

/**
 Updates the model used to render the component.
 */
- (void)updateModel:(id<NSObject>)model;

/**
 Updates the context used to render the component.
 */
- (void)updateContext:(id<NSObject>)context;

/**
 Generate component synchronously on affined queue and return the result.
 */
- (CKBuildComponentResult)generateComponentSynchronously;

/**
 Generate component asynchronously on a global background queue.
 `CKComponentGeneratorDelegate.componentGenerator:didAsynchronouslyGenerateComponentResult:` will be called once it
 finishes generation.
 */
- (void)generateComponentAsynchronously;

/**
 Ignore component reuse in next component generation.
 This should be used if you are going to update `CKComponentContext` in the hierarchy.
 */
- (void)ignoreComponentReuseInNextGeneration;

/**
 The underlying scope root that is maintained by `CKComponentGenerator`.
 */
- (CKComponentScopeRoot *)scopeRoot;

/**
 This is a temporary API for code migration. DO NOT USE.
 */
- (void)setScopeRoot:(CKComponentScopeRoot *)scopeRoot;

@end

#endif
