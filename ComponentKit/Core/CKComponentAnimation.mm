/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentAnimation.h"

#import "CKComponentSubclass.h"

@interface CKAppliedAnimationContext : NSObject
- (instancetype)initWithTargetLayer:(CALayer *)layer key:(NSString *)key;
@property (nonatomic, strong, readonly) CALayer *targetLayer;
@property (nonatomic, copy, readonly) NSString *key;
@end

static CKComponentAnimationHooks hooksForCAAnimation(CKComponent *component, CAAnimation *originalAnimation, NSString *layerPath) noexcept
{
  CKCAssertNotNil(component, @"Component being animated must be non-nil");
  CKCAssertNotNil(originalAnimation, @"Animation being added must be non-nil");

  // Don't mutate the animation the component returned, in case it is a static or otherwise reused. (Also copy
  // immediately to protect against the *caller* mutating the animation after this point but before it's used.)
  CAAnimation *copiedAnimation = [originalAnimation copy];
  return {
    .didRemount = [^(id context){
      CALayer *layer = layerPath ? [component.viewForAnimation valueForKeyPath:layerPath] : component.viewForAnimation.layer;
      if (auto const lp = layerPath) {
        CKCAssertWithCategory(layer != nil, [component class],
                              @"%@ has no mounted layer at key path %@, so it cannot be animated", [component class], lp);
      } else {
        CKCAssertWithCategory(layer != nil, [component class],
                              @"%@ has no mounted layer, so it cannot be animated", [component class]);
      }
      NSString *key = [[NSUUID UUID] UUIDString];
      auto const animationAddTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
      copiedAnimation.beginTime += animationAddTime;
      [layer addAnimation:copiedAnimation forKey:key];
      return [[CKAppliedAnimationContext alloc] initWithTargetLayer:layer key:key];
    } copy],
    .cleanup = ^(CKAppliedAnimationContext *context){
      [context.targetLayer removeAnimationForKey:context.key];
    }
  };
}

static CKComponentAnimationHooks hooksForFinalUnmountAnimation(const CKComponentFinalUnmountAnimation &a,
                                                               UIView *const hostView) noexcept
{
  const auto component = a.component;
  CAAnimation *const animation = [a.animation copy];
  animation.fillMode = kCAFillModeForwards;
  animation.removedOnCompletion = NO;
  return CKComponentAnimationHooks {
    .willRemount = ^() {
      const auto viewForAnimation = [component viewForAnimation];
      CKCAssertWithCategory(viewForAnimation != nil, [component class],
                            @"Can't animate component without a view. Check if %@ has a view.", [component class]);
      const auto snapshotView = [viewForAnimation snapshotViewAfterScreenUpdates:NO];
      snapshotView.frame = [viewForAnimation convertRect:viewForAnimation.bounds toView:hostView];
      snapshotView.userInteractionEnabled = NO;
      return snapshotView;
    },
    .didRemount = ^(UIView *const snapshotView){
      [hostView addSubview:snapshotView];
      auto const animationAddTime = [snapshotView.layer convertTime:CACurrentMediaTime() fromLayer:nil];
      animation.beginTime += animationAddTime;
      [snapshotView.layer addAnimation:animation forKey:nil];
      return snapshotView;
    },
    .cleanup = ^(UIView *const snapshotView){
      [snapshotView removeFromSuperview];
    }
  }.byAddingCompletion(a.completion);
}

CKComponentAnimation::CKComponentAnimation(CKComponent *component, CAAnimation *animation, NSString *layerPath, CKComponentAnimationCompletion completion) noexcept
: hooks(hooksForCAAnimation(component, animation, layerPath).byAddingCompletion(completion)) {}

CKComponentAnimation::CKComponentAnimation(const CKComponentFinalUnmountAnimation &animation, UIView *const hostView) noexcept
: hooks(hooksForFinalUnmountAnimation(animation, hostView)) {}

CKComponentAnimation::CKComponentAnimation(const CKComponentAnimationHooks &h, CKComponentAnimationCompletion completion) noexcept : hooks(h.byAddingCompletion(completion)) {}

id CKComponentAnimation::willRemount() const
{
  return hooks.willRemount ? hooks.willRemount() : nil;
}

id CKComponentAnimation::didRemount(id context) const
{
  return hooks.didRemount ? hooks.didRemount(context) : nil;
}

void CKComponentAnimation::cleanup(id context) const
{
  if (hooks.cleanup) {
    hooks.cleanup(context);
  }
}

@implementation CKAppliedAnimationContext

- (instancetype)initWithTargetLayer:(CALayer *)targetLayer key:(NSString *)key
{
  if (self = [super init]) {
    _targetLayer = targetLayer;
    _key = [key copy];
  }
  return self;
}

@end
