/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentRootView.h"
#import "CKComponentRootViewInternal.h"

#import "CKAssert.h"
#import "CKComponentDataSourceAttachControllerInternal.h"

@implementation CKComponentRootView

static NSMutableArray *hitTestHooks;

+ (void)addHitTestHook:(CKComponentRootViewHitTestHook)hook
{
  CKAssertMainThread();
  if (hitTestHooks == nil) {
    hitTestHooks = [NSMutableArray array];
  }
  [hitTestHooks addObject:hook];
}

+ (NSArray *)hitTestHooks
{
  CKAssertMainThread();
  return [NSArray arrayWithArray:hitTestHooks];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
  UIView *superHitView = [super hitTest:point withEvent:event];
  for (CKComponentRootViewHitTestHook hook in hitTestHooks) {
    UIView *hitView = hook(self, point, event, superHitView);
    if (hitView) {
      return hitView;
    }
  }
  return superHitView;
}

- (CKComponentLayout)mountedLayout
{
  // It's weird to reach into ck_attachState here. ck_attachState should probably be refactored
  // to simply be a concrete method on this class, instead of a category.
  CKComponentDataSourceAttachState *const attachState = self.ck_attachState;
  return attachState ? attachState.layout : CKComponentLayout();
}

@end
