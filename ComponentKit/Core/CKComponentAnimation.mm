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

#import "CKComponentInternal.h"

@interface CKAppliedAnimationContext : NSObject
- (instancetype)initWithTargetLayer:(CALayer *)layer key:(NSString *)key;
@property (nonatomic, strong, readonly) CALayer *targetLayer;
@property (nonatomic, copy, readonly) NSString *key;
@end

static CKComponentAnimationHooks hooksForCAAnimation(CKComponent *component, CAAnimation *originalAnimation, NSString *layerPath)
{
  CKCAssertNotNil(component, @"Component being animated must be non-nil");
  CKCAssertNotNil(originalAnimation, @"Animation being added must be non-nil");

  // Don't mutate the animation the component returned, in case it is a static or otherwise reused. (Also copy
  // immediately to protect against the *caller* mutating the animation after this point but before it's used.)
  CAAnimation *copiedAnimation = [originalAnimation copy];
  return {
    .didRemount = ^(id context){
      CALayer *layer = layerPath ? [component.viewForAnimation valueForKeyPath:layerPath] : component.viewForAnimation.layer;
      CKCAssertNotNil(layer, @"%@ has no mounted layer at key path %@, so it cannot be animated", [component class], layerPath);
      NSString *key = [[NSUUID UUID] UUIDString];

      // CAMediaTiming beginTime is specified in the time space of the superlayer. Since the component has no way to
      // access the superlayer when constructing the animation, we document that beginTime should be specified in
      // absolute time and perform the adjustment here.
      if (copiedAnimation.beginTime != 0.0) {
        copiedAnimation.beginTime = [layer.superlayer convertTime:copiedAnimation.beginTime fromLayer:nil];
      }
      [layer addAnimation:copiedAnimation forKey:key];
      return [[CKAppliedAnimationContext alloc] initWithTargetLayer:layer key:key];
    },
    .cleanup = ^(CKAppliedAnimationContext *context){
      [context.targetLayer removeAnimationForKey:context.key];
    }
  };
}

CKComponentAnimation::CKComponentAnimation(CKComponent *component, CAAnimation *animation, NSString *layerPath)
: hooks(hooksForCAAnimation(component, animation, layerPath)) {}

CKComponentAnimation::CKComponentAnimation(const CKComponentAnimationHooks &h) : hooks(h) {}

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
