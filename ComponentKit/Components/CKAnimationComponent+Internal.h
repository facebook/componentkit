/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKAnimationComponent.h>
#import <ComponentKit/CKDefines.h>

#if CK_NOT_SWIFT

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

#endif
