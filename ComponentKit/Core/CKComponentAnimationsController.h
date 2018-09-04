/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <Foundation/Foundation.h>

#import <ComponentKit/CKComponentAnimationData.h>
#import <ComponentKit/CKComponentAnimations.h>

namespace CK {
  struct CATransactionProvider
  {
    // Even though these lambdas are supposed to have identical signatures, formally speaking, actual
    // anonymous function object types will be different hence separate type parameters
    template <typename VoidLambda1, typename VoidLambda2>
    auto inTransaction(VoidLambda1 t, VoidLambda2 c) const
    {
      [CATransaction begin];
      [CATransaction setCompletionBlock:^{ c(); }];
      t();
      [CATransaction commit];
    }
  };

  class ComponentAnimationsController final {
  public:
    ComponentAnimationsController(CKComponentAnimations animations)
    : _animations(std::move(animations)),
    _appliedAnimationsOnInitialMount(std::make_shared<AppliedAnimationsByComponentMap>()),
    _appliedAnimationsFromPreviousComponent(std::make_shared<AppliedAnimationsByComponentMap>()),
    _appliedAnimationsOnFinalUnmount(std::make_shared<AppliedAnimationsByComponentMap>()) {};

    void collectPendingAnimations();

    template <typename TransactionProvider>
    void applyPendingAnimations(TransactionProvider& transactionProvider)
    {
      applyPendingAnimations(_pendingAnimationsOnInitialMount,
                             _appliedAnimationsOnInitialMount,
                             transactionProvider);
      applyPendingAnimations(_pendingAnimationsFromPreviousComponent,
                             _appliedAnimationsFromPreviousComponent,
                             transactionProvider);
      applyPendingAnimations(_pendingAnimationsOnFinalUnmount,
                             _appliedAnimationsOnFinalUnmount,
                             transactionProvider);
    }

    void cleanupAppliedAnimationsForComponent(CKComponent *const c);

  private:
    using PendingAnimationsByComponentMap = std::unordered_map<CKComponent *, std::vector<CKPendingComponentAnimation>, CK::hash<CKComponent *>, CK::is_equal<CKComponent *>>;
    using AppliedAnimationsByComponentMap = std::unordered_map<CKComponent *, CKAppliedComponentAnimationMap, CK::hash<CKComponent *>, CK::is_equal<CKComponent *>>;

    template <typename TransactionProvider>
    auto applyPendingAnimations(const PendingAnimationsByComponentMap &pendingAnimations,
                                const std::shared_ptr<AppliedAnimationsByComponentMap> &appliedAnimations,
                                TransactionProvider& transactionProvider)
    {
      for (const auto &kv : pendingAnimations) {
        for (const auto &pa : kv.second) {
          applyPendingAnimationForComponent(appliedAnimations,
                                            pa,
                                            kv.first,
                                            transactionProvider);
        }
      }
    }

    template <typename TransactionProvider>
    auto applyPendingAnimationForComponent(const std::shared_ptr<AppliedAnimationsByComponentMap> &animations,
                                           const CKPendingComponentAnimation &pa,
                                           CKComponent *const c,
                                           TransactionProvider& transactionProvider)
    {
      const auto animationID = _animationID++;
      transactionProvider.inTransaction([pa, c, animationID, animations](){
        const auto animation = pa.animation;
        auto &animationsForComponent = (*animations)[c];
        const auto appliedAnimation = CKAppliedComponentAnimation {animation, animation.didRemount(pa.context)};
        animationsForComponent.insert({animationID, appliedAnimation});
      }, [pa, c, animationID, animations](){
        auto &animationsForComponent = (*animations)[c];
        const auto it = animationsForComponent.find(animationID);
        if (it == animationsForComponent.end()) { return; }
        pa.animation.cleanup(it->second.context);
        animationsForComponent.erase(it);
      });
    }

    static auto cleanupAppliedAnimationsForComponent(AppliedAnimationsByComponentMap &aas,
                                                     CKComponent *const c);

    const CKComponentAnimations _animations;
    PendingAnimationsByComponentMap _pendingAnimationsOnInitialMount = {};
    PendingAnimationsByComponentMap _pendingAnimationsFromPreviousComponent = {};
    PendingAnimationsByComponentMap _pendingAnimationsOnFinalUnmount = {};
    // Ownership will be shared with transaction completions which can outlive the controller
    std::shared_ptr<AppliedAnimationsByComponentMap> _appliedAnimationsOnInitialMount;
    std::shared_ptr<AppliedAnimationsByComponentMap> _appliedAnimationsFromPreviousComponent;
    std::shared_ptr<AppliedAnimationsByComponentMap> _appliedAnimationsOnFinalUnmount;
    int _animationID = 0;
  };
}
