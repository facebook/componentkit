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
#import <RenderCore/CKComponentDescriptionHelper.h>
#import <RenderCore/CKMountable.h>
#import <RenderCore/CKMountableHelpers.h>
#import <RenderCore/CKMountedObjectForView.h>
#import <RenderCore/CKViewConfiguration.h>

static void relinquishMountedView(std::unique_ptr<CKMountInfo> &mountInfo,
                                  id<CKMountable> mountable,
                                  CKMountCallbackBlock willRelinquishViewBlock)
{
  CKCAssertMainThread();
  CKCAssert(mountInfo, @"mountInfo should not be null");
  if (mountInfo) {
    UIView *view = mountInfo->view;
    if (view) {
      if (willRelinquishViewBlock) {
        willRelinquishViewBlock(view);
      }
      CKCAssert(CKMountedObjectForView(view) == mountable, @"");
      CKSetMountedObjectForView(view, nil);
      mountInfo->view = nil;
    }
  }
}

CK::Component::MountResult CKPerformMount(std::unique_ptr<CKMountInfo> &mountInfo,
                                          const id<CKMountable> mountable,
                                          const CKViewConfiguration &viewConfiguration,
                                          const CK::Component::MountContext &context,
                                          const CGSize size,
                                          const std::shared_ptr<const std::vector<CKLayoutChild>> &children,
                                          const id<CKMountable> supercomponent,
                                          const CKMountCallbackBlock didAcquireViewBlock,
                                          const CKMountCallbackBlock willRelinquishViewBlock)
{
  CKCAssertMainThread();

  if (!mountInfo) {
    mountInfo.reset(new CKMountInfo());
  }
  mountInfo->supercomponent = supercomponent;

  UIView *v = context.viewManager->viewForConfiguration(mountable.class, viewConfiguration);
  if (v) {
    auto const currentMountedComponent = (id<CKMountable>)CKMountedObjectForView(v);
    if (mountInfo->view != v) {
      relinquishMountedView(mountInfo, mountable, willRelinquishViewBlock); // First release our old view
      [currentMountedComponent unmount]; // Then unmount old component (if any) from the new view
      CKSetMountedObjectForView(v, mountable);
      CK::Component::AttributeApplicator::apply(v, viewConfiguration);
      if (didAcquireViewBlock) {
        didAcquireViewBlock(v);
      }
      mountInfo->view = v;
    } else {
      CKCAssert(currentMountedComponent == mountable, @"");
    }

    @try {
      CKSetViewPositionAndBounds(v, context, size);
    } @catch (NSException *exception) {
      NSString *const componentBacktraceDescription =
        CKComponentBacktraceDescription(CKComponentGenerateBacktrace(supercomponent));
      NSString *const componentChildrenDescription = CKComponentChildrenDescription(children);
      [NSException
       raise:exception.name
       format:@"%@ raised %@ during mount: %@\n backtrace:%@ children:%@",
       mountable.class, exception.name, exception.reason,
       componentBacktraceDescription, componentChildrenDescription];
    }

    mountInfo->viewContext = {v, {{0,0}, v.bounds.size}};
    return {.mountChildren = YES, .contextForChildren = context.childContextForSubview(v, NO)};
  } else {
    CKCAssertWithCategory(mountInfo->view == nil, mountable.class,
                          @"%@ should not have a mounted %@ after previously being mounted without a view.\n%@",
                          mountable.class,
                          [mountInfo->view class],
                          CKComponentBacktraceDescription(CKComponentGenerateBacktrace(mountable)));
    mountInfo->viewContext = {context.viewManager->view, {context.position, size}};
    return {.mountChildren = YES, .contextForChildren = context};
  }
}

void CKPerformUnmount(std::unique_ptr<CKMountInfo> &mountInfo,
                      const id<CKMountable> mountable,
                      const CKMountCallbackBlock willRelinquishViewBlock)
{
  CKCAssertMainThread();
  if (mountInfo) {
    relinquishMountedView(mountInfo, mountable, willRelinquishViewBlock);
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
