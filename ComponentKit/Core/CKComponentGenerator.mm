/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentGenerator.h"

#import <ComponentKit/CKAssert.h>
#import <ComponentKit/CKBuildComponent.h>
#import <ComponentKit/CKComponentController.h>
#import <ComponentKit/CKComponentControllerEvents.h>
#import <ComponentKit/CKComponentControllerHelper.h>
#import <ComponentKit/CKComponentScopeRoot.h>
#import <ComponentKit/CKComponentScopeRootFactory.h>
#import <ComponentKit/CKGlobalConfig.h>
#import <ComponentKit/CKSystraceScope.h>

static void *kAffinedQueueKey = &kAffinedQueueKey;

#define CKAssertAffinedQueue() CKAssert([self _isRunningOnAffinedQueue], @"This method must only be called on the affined queue")

struct CKComponentGeneratorInputs {
  CKComponentScopeRoot *scopeRoot;
  id<NSObject> model;
  id<NSObject> context;
  CKComponentStateUpdateMap stateUpdates;
  BOOL enableComponentReuse;

  bool operator==(const CKComponentGeneratorInputs &i) const {
    return scopeRoot == i.scopeRoot && model == i.model && context == i.context && stateUpdates == i.stateUpdates && enableComponentReuse == i.enableComponentReuse;
  };
};

@interface CKComponentGenerator () <CKComponentStateListener>

@end

@implementation CKComponentGenerator
{
  CKComponentProviderBlock _componentProvider;
  CKComponentGeneratorInputs _pendingInputs;
  __weak id<CKComponentGeneratorDelegate> _delegate;
  dispatch_queue_t _affinedQueue;
}

- (instancetype)initWithOptions:(const CKComponentGeneratorOptions &)options
{
  if (self = [super init]) {
    _delegate = options.delegate;
    _componentProvider = options.componentProvider;
    _pendingInputs = {
      .scopeRoot =
      CKComponentScopeRootWithPredicates(self,
                                         options.analyticsListener ?: CKReadGlobalConfig().defaultAnalyticsListener,
                                         options.componentPredicates,
                                         options.componentControllerPredicates)
    };
    _affinedQueue = options.affinedQueue;
    if (_affinedQueue != dispatch_get_main_queue()) {
      dispatch_queue_set_specific(_affinedQueue, kAffinedQueueKey, kAffinedQueueKey, NULL);
    }
  }
  return self;
}

- (void)dealloc
{
  const auto scopeRoot = _pendingInputs.scopeRoot;
  const auto invalidateController = ^{
    CKComponentScopeRootAnnounceControllerInvalidation(scopeRoot);
  };
  if ([NSThread isMainThread]) {
    invalidateController();
  } else {
    dispatch_async(dispatch_get_main_queue(), invalidateController);
  }
}

- (void)updateModel:(id<NSObject>)model
{
  CKAssertAffinedQueue();
  _pendingInputs.model = model;
}

- (void)updateContext:(id<NSObject>)context
{
  CKAssertAffinedQueue();
  _pendingInputs.context = context;
}

- (CKBuildComponentResult)generateComponentSynchronously
{
  CKAssertAffinedQueue();

  const auto enableComponentReuse = _pendingInputs.enableComponentReuse;
  _pendingInputs.enableComponentReuse = YES;
  const auto result = CKBuildComponent(_pendingInputs.scopeRoot, _pendingInputs.stateUpdates, ^{
    return _componentProvider(_pendingInputs.model, _pendingInputs.context);
  }, enableComponentReuse);
  [self _applyResult:result
addedComponentControllers:_addedComponentControllersBetweenScopeRoots(result.scopeRoot, _pendingInputs.scopeRoot)
invalidComponentControllers:_invalidComponentControllersBetweenScopeRoots(result.scopeRoot, _pendingInputs.scopeRoot)];
  return result;
}

- (void)generateComponentAsynchronously
{
  CKAssertAffinedQueue();

  const auto inputs = std::make_shared<const CKComponentGeneratorInputs>(_pendingInputs);
  const auto asyncGeneration = CK::Analytics::willStartAsyncBlock(CK::Analytics::BlockName::ComponentGeneratorWillGenerate);

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    CKSystraceScope generationScope(asyncGeneration);
    const auto result =
    std::make_shared<const CKBuildComponentResult>(CKBuildComponent(
                                                                    inputs->scopeRoot,
                                                                    inputs->stateUpdates,
                                                                    ^{
                                                                      return _componentProvider(inputs->model, inputs->context);
                                                                    },
                                                                    inputs->enableComponentReuse));
    const auto addedComponentControllers =
    std::make_shared<const std::vector<CKComponentController *>>(_addedComponentControllersBetweenScopeRoots(result->scopeRoot, inputs->scopeRoot));
    const auto invalidComponentControllers =
    std::make_shared<const std::vector<CKComponentController *>>(_invalidComponentControllersBetweenScopeRoots(result->scopeRoot, inputs->scopeRoot));
    const auto asyncApplication = CK::Analytics::willStartAsyncBlock(CK::Analytics::BlockName::ComponentGeneratorWillApply);

    dispatch_async(_affinedQueue, ^{
      CKSystraceScope applicationScope(asyncApplication);
      if (![_delegate componentGeneratorShouldApplyAsynchronousGenerationResult:self]) {
        return;
      }
      // If the inputs haven't changed, apply the result; otherwise, retry.
      if (_pendingInputs == *inputs) {
        _pendingInputs.enableComponentReuse = YES;
        [self _applyResult:*result
 addedComponentControllers:addedComponentControllers != nullptr ? *addedComponentControllers : std::vector<CKComponentController *>{}
invalidComponentControllers:invalidComponentControllers != nullptr ? *invalidComponentControllers : std::vector<CKComponentController *>{}];
        [_delegate componentGenerator:self didAsynchronouslyGenerateComponentResult:*result];
      } else {
        [self generateComponentAsynchronously];
      }
    });
  });
}

- (void)ignoreComponentReuseInNextGeneration
{
  CKAssertAffinedQueue();
  _pendingInputs.enableComponentReuse = NO;
}

- (CKComponentScopeRoot *)scopeRoot
{
  CKAssertAffinedQueue();
  return _pendingInputs.scopeRoot;
}

- (void)setScopeRoot:(CKComponentScopeRoot *)scopeRoot
{
  CKAssertAffinedQueue();
  _notifyInitializationControllerEvents(_addedComponentControllersBetweenScopeRoots(scopeRoot, _pendingInputs.scopeRoot));
  _notifyInvalidateControllerEvents(_invalidComponentControllersBetweenScopeRoots(scopeRoot, _pendingInputs.scopeRoot));
  _pendingInputs.scopeRoot = scopeRoot;
}

#pragma mark - Private

- (void)_applyResult:(const CKBuildComponentResult &)result
addedComponentControllers:(const std::vector<CKComponentController *>&)addedComponentControllers
invalidComponentControllers:(const std::vector<CKComponentController *> &)invalidComponentControllers
{
  CKAssertAffinedQueue();

  _notifyInitializationControllerEvents(addedComponentControllers);
  _notifyInvalidateControllerEvents(invalidComponentControllers);
  _pendingInputs.scopeRoot = result.scopeRoot;
  _pendingInputs.stateUpdates = {};
}

- (BOOL)_isRunningOnAffinedQueue
{
  if (_affinedQueue == dispatch_get_main_queue()) {
    return [NSThread isMainThread];
  } else {
    return (dispatch_get_specific(kAffinedQueueKey) == kAffinedQueueKey);
  }
}

static void _notifyInvalidateControllerEvents(const std::vector<CKComponentController *> &invalidComponentControllers)
{
  const auto componentControllers = std::make_shared<std::vector<CKComponentController *>>(invalidComponentControllers);
  const auto invalidateControllers = ^{
    for (auto componentController : *componentControllers) {
      [componentController invalidateController];
    }
  };
  if ([NSThread isMainThread]) {
    invalidateControllers();
  } else {
    dispatch_async(dispatch_get_main_queue(), invalidateControllers);
  }
}

static void _notifyInitializationControllerEvents(const std::vector<CKComponentController *> &addedComponentControllers)
{
  const auto componentControllers = std::make_shared<std::vector<CKComponentController *>>(addedComponentControllers);
  const auto didInitControllers = ^{
    for (auto componentController : *componentControllers) {
      [componentController didInit];
    }
  };
  if ([NSThread isMainThread]) {
    didInitControllers();
  } else {
    dispatch_async(dispatch_get_main_queue(), didInitControllers);
  }
}

static std::vector<CKComponentController *> _invalidComponentControllersBetweenScopeRoots(CKComponentScopeRoot *newRoot,
                                                                                          CKComponentScopeRoot *previousRoot)
{
  if (!previousRoot) {
    return {};
  }
  return
  CKComponentControllerHelper::removedControllersFromPreviousScopeRootMatchingPredicate(newRoot,
                                                                                        previousRoot,
                                                                                        &CKComponentControllerInvalidateEventPredicate);
}

static std::vector<CKComponentController *> _addedComponentControllersBetweenScopeRoots(CKComponentScopeRoot *newRoot,
                                                                                        CKComponentScopeRoot *previousRoot)
{
  return CKComponentControllerHelper::addedControllersFromPreviousScopeRootMatchingPredicate(newRoot,
                                                                                             previousRoot,
                                                                                             &CKComponentControllerInitializeEventPredicate);
}

#pragma mark - CKComponentStateListener

- (void)componentScopeHandle:(CKComponentScopeHandle *)handle
              rootIdentifier:(CKComponentScopeRootIdentifier)rootIdentifier
       didReceiveStateUpdate:(id (^)(id))stateUpdate
                    metadata:(const CKStateUpdateMetadata &)metadata
                        mode:(CKUpdateMode)mode
{
  CKAssertMainThread();

  const auto enqueueStateUpdate = ^{
    _pendingInputs.stateUpdates[handle].push_back(stateUpdate);
    [_delegate componentGenerator:self didReceiveComponentStateUpdateWithMode:mode];
  };
  if ([self _isRunningOnAffinedQueue]) {
    enqueueStateUpdate();
  } else {
    dispatch_async(_affinedQueue, enqueueStateUpdate);
  }
}

@end
