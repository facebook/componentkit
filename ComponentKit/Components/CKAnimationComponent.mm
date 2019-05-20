// Copyright 2004-present Facebook. All Rights Reserved.

#import "CKAnimationComponent.h"

#import <ComponentKit/CKComponentInternal.h>
#import <ComponentKit/CKComponentSubclass.h>

auto CK::AnimationComponentFor::build() const -> CKAnimationComponent * {
  return
  [CKAnimationComponent
   newWithComponent:_component
   options:{
     .animationOnInitialMount = _animationOnInitialMount,
     .animationOnFinalUnmount = _animationOnFinalUnmount
   }];
}

@implementation CKAnimationComponent {
  CKAnimationComponentOptions _options;
}

+ (instancetype)newWithComponent:(CKComponent *)component
                         options:(CKAnimationComponentOptions)options
{
  if (component == nil) {
    return nil;
  }

  CKComponentScope s(self);
  auto const c = component.viewConfiguration.viewClass().hasView()
                     ? [super newWithComponent:component]
                     : [super newWithView:{[UIView class]} component:component];
  c->_options = std::move(options);
  return c;
}

- (std::vector<CKComponentAnimation>)animationsOnInitialMount
{
  if (auto const a = _options.animationOnInitialMount) {
    return {
      {self, a}
    };
  }
  return {};
}

- (std::vector<CKComponentFinalUnmountAnimation>)animationsOnFinalUnmount
{
  if (auto const a = _options.animationOnFinalUnmount) {
    return {
      {self, a}
    };
  }
  return {};
}

@end
