/*
*  Copyright (c) 2014-present, Facebook, Inc.
*  All rights reserved.
*
*  This source code is licensed under the BSD-style license found in the
*  LICENSE file in the root directory of this source tree. An additional grant
*  of patent rights can be found in the PATENTS file in the same directory.
*
*/

#import "CKTransitionComponent.h"

#import <ComponentKit/CKCasting.h>
#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKComponentSubclass.h>
#import <ComponentKit/CKCompositeComponent.h>

@interface CKTransitionComponent : CKCompositeComponent

+ (instancetype)newWithComponent:(CKComponent *)component
                  onInitialMount:(CAAnimation *)animationOnInitialMount
                  onFinalUnmount:(CAAnimation *)animationOnFinalUnmount
                    triggerValue:(id<NSObject>)trigger;

@end

static auto disappearingPreviousComponentAnimation(CAAnimation *disappearAnimation,
                                                   CKComponent *previousComponent,
                                                   CKComponent *newComponent) -> CKComponentAnimation
{
  return CKComponentAnimationHooks{
    .willRemount = ^{
      auto const childView = [previousComponent viewForAnimation];
      CKCAssertWithCategory(
                            childView != nil,
                            [previousComponent className],
                            @"Can't animate component without a view. "
                            "Check %@ is from the previousComponent tree, has a view and is mounted.",
                            [previousComponent className]
                            );

      auto const snapshotView = [childView snapshotViewAfterScreenUpdates:NO];
      snapshotView.layer.anchorPoint = childView.layer.anchorPoint;
      snapshotView.userInteractionEnabled = NO;
      return snapshotView;
    },
    .didRemount = ^UIView *(UIView *snapshotView) {
      auto const newView = [newComponent viewForAnimation];
      CKCAssertWithCategory(newView != nil, [newComponent className], @"Can't animate %@ without a view.", [newComponent className]);
      if (newView == nil || snapshotView == nil) {
        return nil; // Avoid crashing in insertSubview:aboveSubview:
      }
      auto const frame = CGRect{
        newView.frame.origin,
        snapshotView.bounds.size,
      };
      snapshotView.frame = frame;
      [newView.superview insertSubview:snapshotView aboveSubview:newView];

      [CATransaction begin];
      [CATransaction setCompletionBlock:^{
        [snapshotView removeFromSuperview];
      }];
      [snapshotView.layer addAnimation:disappearAnimation forKey:nil];
      [CATransaction commit];

      return snapshotView;
    },
    .cleanup = ^(UIView *snapshotView) {
      [snapshotView removeFromSuperview];
    },
  };
}

@implementation CKTransitionComponent
{
  CAAnimation *_animationOnInitialMount;
  CAAnimation *_animationOnFinalUnmount;
  id<NSObject> _trigger;
}

+ (instancetype)newWithComponent:(CKComponent *)component
                  onInitialMount:(CAAnimation *)animationOnInitialMount
                  onFinalUnmount:(CAAnimation *)animationOnFinalUnmount
                    triggerValue:(id<NSObject>)trigger
{
  if (component == nil) {
    return nil;
  }

  CKComponentScope s(self);
  auto const c = component.viewConfiguration.viewClass().hasView()
  ? [super newWithComponent:component]
  : [super newWithView:{[UIView class]} component:component];

  if (c != nil) {
    c->_animationOnInitialMount = animationOnInitialMount;
    c->_animationOnFinalUnmount = animationOnFinalUnmount;
    c->_trigger = trigger;
  }

  return c;
}

- (std::vector<CKComponentAnimation>)animationsFromPreviousComponent:(CKComponent *)previousComponent
{
  auto const prev = CK::objCForceCast<CKTransitionComponent>(previousComponent);
  if (CKObjectIsEqual(_trigger, prev->_trigger)) {
    return {};
  }

  return {
    {self, _animationOnInitialMount},
    disappearingPreviousComponentAnimation(_animationOnFinalUnmount, previousComponent, self)
  };
}

@end

namespace CK {

template <typename T>
static CAAnimation *toCA(const CK::Optional<T>& a) {
  return a.mapToPtr([](const T& a) { return a.toCA(); });
}

auto BuilderDetails::TransitionComponentDetails::factory(CKComponent *component, const Optional<Animation::Initial> &initialAnimation, const Optional<Animation::Final> &finalAnimation, id<NSObject> triggerValue) -> CKComponent *
{
  return
  [CKTransitionComponent
   newWithComponent:component
   onInitialMount:toCA(initialAnimation)
   onFinalUnmount:toCA(finalAnimation)
   triggerValue:triggerValue];
}

auto TransitionComponentBuilder() -> TransitionComponentBuilderEmpty
{
  return {};
}

auto TransitionComponentBuilder(const CK::ComponentSpecContext &c) -> TransitionComponentBuilderContext
{
  return {c};
}

}
