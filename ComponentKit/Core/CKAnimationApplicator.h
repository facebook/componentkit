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

#ifndef CKAnimationApplicator_h
#define CKAnimationApplicator_h

#import <ComponentKit/CKComponentAnimationsController.h>

namespace CK {
  template <typename TransactionProvider = CATransactionProvider>
  class AnimationApplicator final {
  public:
    using MountPerformerBlock = NSSet<CKComponent *> *(^)(void);

    AnimationApplicator(std::unique_ptr<TransactionProvider> transactionProvider = std::make_unique<TransactionProvider>())
    : _transactionProvider(std::move(transactionProvider)){}

    auto runAnimationsWhenMounting(const CKComponentAnimations &animations, const MountPerformerBlock mountPerformer)
    {
      if (animations.isEmpty()) {
        mountPerformer();
        return;
      }

      const auto pendingAnimations = collectPendingAnimations(animations);

      const auto unmountedComponents = mountPerformer();

      for (CKComponent *c in unmountedComponents) {
        _animationsController.cleanupAppliedAnimationsForComponent(c);
      }

      _animationsController = ComponentAnimationsController{};
      _animationsController.applyPendingAnimations(pendingAnimations, *_transactionProvider);
    }

  private:
    ComponentAnimationsController _animationsController;
    std::unique_ptr<TransactionProvider> _transactionProvider;
  };

  struct AnimationApplicatorFactory final {
    static auto make()
    {
      return std::make_unique<AnimationApplicator<>>();
    }
  };
}

#endif /* CKAnimationApplicator_h */

#endif
