//
//  CKComponentBoundsAnimationPredicates.m
//  ComponentKit
//
//  Created by Oliver Rickard on 3/28/17.
//
//

#import "CKComponentBoundsAnimationPredicates.h"

#import "CKComponentInternal.h"
#import "CKComponentSubclass.h"
#import "CKInternalHelpers.h"

BOOL CKComponentBoundsAnimationPredicate(id<CKScopedComponent> component)
{
  return CKSubclassOverridesSelector([CKComponent class], [component class], @selector(boundsAnimationFromPreviousComponent:));
}
