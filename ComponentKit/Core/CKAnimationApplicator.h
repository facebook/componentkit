/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#ifndef CKAnimationApplicator_h
#define CKAnimationApplicator_h

#import <ComponentKit/CKComponentAnimationsController.h>

namespace CK {
  template <typename AnimationsController>
  class AnimationApplicator final {
  public:
    // Ownership is shared with the test code
    using ControllerFactoryFunction = std::function<std::shared_ptr<AnimationsController>(const CKComponentAnimations &)>;
    using MountPerformerBlock = NSSet<CKComponent *> *(^)(void);

    AnimationApplicator(ControllerFactoryFunction controllerFactory)
    :_controllerFactory(std::move(controllerFactory)) {}

    auto runAnimationsWhenMounting(const CKComponentAnimations &as, const MountPerformerBlock p)
    {
      if (as.isEmpty()) {
        p();
        return;
      }

      auto previousController = _animationsController;
      _animationsController = _controllerFactory(as);
      _animationsController->collectPendingAnimations();

      const auto unmountedComponents = p();

      if (previousController != nil) {
        for (CKComponent *c in unmountedComponents) {
          previousController->cleanupAppliedAnimationsForComponent(c);
        }
      }

      const auto tp = CATransactionProvider();
      _animationsController->applyPendingAnimations(tp);
    }

  private:
    std::shared_ptr<AnimationsController> _animationsController;
    ControllerFactoryFunction _controllerFactory;
  };

  struct AnimationApplicatorFactory final {
    static auto make()
    {
      return std::make_unique<AnimationApplicator<ComponentAnimationsController>>([](const CKComponentAnimations &as){
        return std::make_unique<ComponentAnimationsController>(as);
      });
    }
  };
}

#endif /* CKAnimationApplicator_h */
