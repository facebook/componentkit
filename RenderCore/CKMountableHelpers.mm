/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKMountableHelpers.h"

#import <RenderCore/CKAssert.h>
#import <RenderCore/RCComponentDescriptionHelper.h>
#import <RenderCore/CKMountable.h>
#import <RenderCore/CKMountableHelpers.h>
#import <RenderCore/CKMountedObjectForView.h>
#import <RenderCore/CKViewConfiguration.h>

static void relinquishMountedView(std::unique_ptr<CKMountInfo> &mountInfo,
                                  id<CKMountable> mountable,
                                  CKMountCallbackFunction willRelinquishViewFunction)
{
  CKCAssertMainThread();
  CKCAssert(mountInfo, @"mountInfo should not be null");
  if (mountInfo) {
    UIView *view = mountInfo->view;
    if (view) {
      if (willRelinquishViewFunction) {
        willRelinquishViewFunction(mountable, view);
      }
      CKCAssert(CKMountedObjectForView(view) == mountable, @"");
      CKSetMountedObjectForView(view, nil);
      mountInfo->view = nil;
    }
  }
}

CK::Component::MountResult CKPerformMount(std::unique_ptr<CKMountInfo> &mountInfo,
                                          const RCLayout &layout,
                                          const CKViewConfiguration &viewConfiguration,
                                          const CK::Component::MountContext &context,
                                          const id<CKMountable> supercomponent,
                                          const CKMountCallbackFunction didAcquireViewFunction,
                                          const CKMountCallbackFunction willRelinquishViewFunction)
{
  CKCAssertMainThread();

  if (!mountInfo) {
    mountInfo.reset(new CKMountInfo());
  }
  mountInfo->supercomponent = supercomponent;

  UIView *v = context.viewManager->viewForConfiguration(layout.component.class, viewConfiguration);
  if (v) {
    auto const currentMountedComponent = (id<CKMountable>)CKMountedObjectForView(v);
    if (mountInfo->view != v) {
      relinquishMountedView(mountInfo, layout.component, willRelinquishViewFunction); // First release our old view
      [currentMountedComponent unmount]; // Then unmount old component (if any) from the new view
      CKSetMountedObjectForView(v, layout.component);
      CK::Component::AttributeApplicator::apply(v, viewConfiguration);
      if (didAcquireViewFunction) {
        didAcquireViewFunction(layout.component, v);
      }
      mountInfo->view = v;
    } else {
      CKCAssert(currentMountedComponent == layout.component, @"");
    }

    @try {
      CKSetViewPositionAndBounds(v, context, layout.size);
    } @catch (NSException *exception) {
      NSString *const componentBacktraceDescription =
        RCComponentBacktraceDescription(RCComponentGenerateBacktrace(supercomponent));
      NSString *const componentChildrenDescription = RCComponentChildrenDescription(layout.children);
      [NSException
       raise:exception.name
       format:@"%@ raised %@ during mount: %@\n backtrace:%@ children:%@",
       layout.component.class, exception.name, exception.reason,
       componentBacktraceDescription, componentChildrenDescription];
    }

    mountInfo->viewContext = {v, {{0,0}, v.bounds.size}};
    return {.mountChildren = YES, .contextForChildren = context.childContextForSubview(v, NO)};
  } else {
    CKCAssertWithCategory(mountInfo->view == nil, layout.component.class,
                          @"%@ should not have a mounted %@ after previously being mounted without a view.\n%@",
                          layout.component.class,
                          [mountInfo->view class],
                          RCComponentBacktraceDescription(RCComponentGenerateBacktrace(layout.component)));
    mountInfo->viewContext = {context.viewManager->view, {context.position, layout.size}};
    return {.mountChildren = YES, .contextForChildren = context};
  }
}

void CKPerformUnmount(std::unique_ptr<CKMountInfo> &mountInfo,
                      const id<CKMountable> mountable,
                      const CKMountCallbackFunction willRelinquishViewFunction)
{
  CKCAssertMainThread();
  if (mountInfo) {
    relinquishMountedView(mountInfo, mountable, willRelinquishViewFunction);
    mountInfo.reset();
  }
}

void CKSetViewPositionAndBounds(UIView *v,
                                const CK::Component::MountContext &context,
                                const CGSize size)
{
  const CGPoint anchorPoint = v.layer.anchorPoint;
  [v setCenter:context.position + CGPoint({size.width * anchorPoint.x, size.height * anchorPoint.y})];
  [v setBounds:{v.bounds.origin, size}];
}
