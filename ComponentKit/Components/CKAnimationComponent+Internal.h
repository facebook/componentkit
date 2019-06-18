// Copyright 2004-present Facebook. All Rights Reserved.

#import <ComponentKit/CKAnimationComponent.h>

@interface CKAnimationComponent (Internal)

/**
 @param component Component to animate.
 @param animationOnInitialMount Animation that will be applied to the component when it is first mounted.
 @param animationOnFinalUnmount Animation that will be applied to the component when it is no longer in the mounted hierarchy.
 @note This is for internal use only - the use of stongly typed variant is preferred.
*/
+ (instancetype)newWithComponent:(CKComponent *)component
         animationOnInitialMount:(CAAnimation *)animationOnInitialMount
         animationOnFinalUnmount:(CAAnimation *)animationOnFinalUnmount;

@end
