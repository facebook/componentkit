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

#import <ComponentKit/CKAssert.h>

#import "CKComponentAttachControllerInternal.h"

@implementation CKComponentRootView {
  BOOL _allowTapPassthrough;
}

static NSMutableArray *hitTestHooks;

- (void)setAllowTapPassthrough:(BOOL)allowTapPassthrough
{
  CKAssertMainThread();
  _allowTapPassthrough = allowTapPassthrough;
}

- (void)willEnterViewPool
{
  // Subclass should override this to release resource.
}

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
      superHitView = hitView;
      break;
    }
  }

  if (_allowTapPassthrough) {
    if (superHitView == self) {
      superHitView = nil;
    }
  }

  return superHitView;
}

- (CKComponentLayout)mountedLayout
{
  // It's weird to reach into ck_attachState here. ck_attachState should probably be refactored
  // to simply be a concrete method on this class, instead of a category.
  CKComponentAttachState *const attachState = CKGetAttachStateForView(self);
  return attachState ? CKComponentAttachStateRootLayout(attachState).layout() : CKComponentLayout();
}

- (id<NSObject>)uniqueIdentifier
{
  auto const scopeRootIdentifier = CKGetAttachStateForView(self).scopeIdentifier;
  return scopeRootIdentifier > 0 ? @(scopeRootIdentifier) : nil;
}

@end
