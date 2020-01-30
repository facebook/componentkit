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
      // Setting `nil` explicitly here is necessary in order to avoid timing function of component animation
      // being overidden by outer level animation, bounds animation for example.
      [CATransaction setAnimationTimingFunction:nil];
      [CATransaction setCompletionBlock:^{ c(); }];
      t();
      [CATransaction commit];
    }
  };

  using PendingAnimationsByComponentMap = std::unordered_map<CKComponent *, std::vector<CKPendingComponentAnimation>, CK::hash<CKComponent *>, CK::is_equal<CKComponent *>>;

  struct PendingAnimations final {
    PendingAnimations(PendingAnimationsByComponentMap animationsOnInitialMount,
                      PendingAnimationsByComponentMap animationsFromPreviousComponent,
                      PendingAnimationsByComponentMap animationsOnFinalUnmount):
    _animationsOnInitialMount(std::move(animationsOnInitialMount)),
    _animationsFromPreviousComponent(std::move(animationsFromPreviousComponent)),
    _animationsOnFinalUnmount(std::move(animationsOnFinalUnmount)) {}

    const auto &animationsOnInitialMount() const { return _animationsOnInitialMount; }
    const auto &animationsFromPreviousComponent() const { return _animationsFromPreviousComponent; }
    const auto &animationsOnFinalUnmount() const { return _animationsOnFinalUnmount; }

  private:
    PendingAnimationsByComponentMap _animationsOnInitialMount = {};
    PendingAnimationsByComponentMap _animationsFromPreviousComponent = {};
    PendingAnimationsByComponentMap _animationsOnFinalUnmount = {};
  };

  auto collectPendingAnimations(const CKComponentAnimations &animations) -> PendingAnimations;

  class ComponentAnimationsController final {
  public:
    ComponentAnimationsController() :
    _appliedAnimationsOnInitialMount(std::make_shared<AppliedAnimationsByComponentMap>()),
    _appliedAnimationsFromPreviousComponent(std::make_shared<AppliedAnimationsByComponentMap>()),
    _appliedAnimationsOnFinalUnmount(std::make_shared<AppliedAnimationsByComponentMap>()) {};

    template <typename TransactionProvider>
    void applyPendingAnimations(const PendingAnimations &pendingAnimations, TransactionProvider& transactionProvider)
    {
      applyPendingAnimations(pendingAnimations.animationsOnInitialMount(),
                             _appliedAnimationsOnInitialMount,
                             transactionProvider);
      applyPendingAnimations(pendingAnimations.animationsFromPreviousComponent(),
                             _appliedAnimationsFromPreviousComponent,
                             transactionProvider);
      applyPendingAnimations(pendingAnimations.animationsOnFinalUnmount(),
                             _appliedAnimationsOnFinalUnmount,
                             transactionProvider);
    }

    void cleanupAppliedAnimationsForComponent(CKComponent *const c);

  private:
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
        const auto animationsForComponentIt = animations->find(c);
        if (animationsForComponentIt == animations->end()) {
          // If we wound up here, this means the animation was cleaned up already via
          // cleanupAppliedAnimationsForComponent()
          return;
        }
        auto &animationsForComponent = animationsForComponentIt->second;
        const auto it = animationsForComponent.find(animationID);
        if (it == animationsForComponent.end()) { return; }
        pa.animation.cleanup(it->second.context);
        animationsForComponent.erase(it);
        if (animationsForComponent.empty()) {
          animations->erase(c);
        }
      });
    }

    static auto cleanupAppliedAnimationsForComponent(AppliedAnimationsByComponentMap &aas,
                                                     CKComponent *const c);

    // Ownership will be shared with transaction completions which can outlive the controller
    std::shared_ptr<AppliedAnimationsByComponentMap> _appliedAnimationsOnInitialMount;
    std::shared_ptr<AppliedAnimationsByComponentMap> _appliedAnimationsFromPreviousComponent;
    std::shared_ptr<AppliedAnimationsByComponentMap> _appliedAnimationsOnFinalUnmount;
    int _animationID = 0;
  };
}

#endif
