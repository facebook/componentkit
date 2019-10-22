/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKMountable+UIView.h"

#import <objc/runtime.h>

#import "CKComponentDescriptionHelper.h"

static char const kViewComponentKey = ' ';

/** Strong reference back to the associated CKMountable while the component is mounted. */
id<CKMountable> CKMountableForView(UIView *view)
{
  return objc_getAssociatedObject(view, &kViewComponentKey);
}

/** This is for internal use by the framework only. */
void CKSetMountableForView(UIView *view, id<CKMountable> component)
{
  objc_setAssociatedObject(view, &kViewComponentKey, component, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


void CKSetViewPositionAndBounds(UIView *v,
                                const CK::Component::MountContext &context,
                                const CGSize size,
                                std::shared_ptr<const std::vector<CKComponentLayoutChild> > children,
                                id<CKMountable> supercomponent,
                                Class<CKMountable> klass)
{
  @try {
    const CGPoint anchorPoint = v.layer.anchorPoint;
    [v setCenter:context.position + CGPoint({size.width * anchorPoint.x, size.height * anchorPoint.y})];
    [v setBounds:{v.bounds.origin, size}];
  } @catch (NSException *exception) {
    NSString *const componentBacktraceDescription =
      CKComponentBacktraceDescription(generateComponentBacktrace(supercomponent));
    NSString *const componentChildrenDescription = CKComponentChildrenDescription(children);
    [NSException raise:exception.name
                format:@"%@ raised %@ during mount: %@\n backtrace:%@ children:%@", klass, exception.name, exception.reason, componentBacktraceDescription, componentChildrenDescription];
  }
}
