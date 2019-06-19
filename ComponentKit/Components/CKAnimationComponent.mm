// Copyright 2004-present Facebook. All Rights Reserved.

#import "CKAnimationComponent.h"
#import "CKAnimationComponent+Internal.h"

#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKComponentSubclass.h>

@interface CKAnimationComponentPassthroughView: UIView
@end

@implementation CKAnimationComponent {
  CAAnimation * _animationOnInitialMount;
  CAAnimation * _animationOnFinalUnmount;
}

+ (instancetype)newWithComponent:(CKComponent *)component
                  onInitialMount:(CK::Animation::Initial)initial
{
  return [self newWithComponent:component
        animationOnInitialMount:initial.toCA()
        animationOnFinalUnmount:nil];
}

+ (instancetype)newWithComponent:(CKComponent *)component
                  onFinalUnmount:(CK::Animation::Final)final
{
  return [self newWithComponent:component
        animationOnInitialMount:nil
        animationOnFinalUnmount:final.toCA()];
}

+ (instancetype)newWithComponent:(CKComponent *)component
                  onInitialMount:(CK::Animation::Initial)initial
                  onFinalUnmount:(CK::Animation::Final)final
{
  return [self newWithComponent:component
        animationOnInitialMount:initial.toCA()
        animationOnFinalUnmount:final.toCA()];
}

+ (instancetype)newWithComponent:(CKComponent *)component
         animationOnInitialMount:(CAAnimation *)animationOnInitialMount
         animationOnFinalUnmount:(CAAnimation *)animationOnFinalUnmount
{
  if (component == nil) {
    return nil;
  }

  CKComponentScope s(self);
  auto const c = component.viewConfiguration.viewClass().hasView()
                     ? [super newWithComponent:component]
                     : [super newWithView:{[CKAnimationComponentPassthroughView class]} component:component];
  c->_animationOnInitialMount = animationOnInitialMount;
  c->_animationOnFinalUnmount = animationOnFinalUnmount;
  return c;
}

- (std::vector<CKComponentAnimation>)animationsOnInitialMount
{
  if (auto const a = _animationOnInitialMount) {
    return {
      {self, a}
    };
  }
  return {};
}

- (std::vector<CKComponentFinalUnmountAnimation>)animationsOnFinalUnmount
{
  if (auto const a = _animationOnFinalUnmount) {
    return {
      {self, a}
    };
  }
  return {};
}

@end

@implementation CKAnimationComponentPassthroughView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
  auto const v = [super hitTest:point withEvent:event];
  return v == self ? nil : v;
}

@end
