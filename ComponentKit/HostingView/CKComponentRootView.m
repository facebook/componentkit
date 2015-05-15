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

@implementation CKComponentRootView

static NSMutableArray *hitTestHooks;

#if !TARGET_OS_IPHONE
- (instancetype)initWithFrame:(CGRect)frameRect
{
  self = [super initWithFrame:frameRect];
  if (!self) return nil;

  self.wantsLayer = YES;

  return self;
}

- (BOOL)isFlipped
{
  return YES;
}
#endif


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


#if TARGET_OS_IPHONE

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
  for (CKComponentRootViewHitTestHook hook in hitTestHooks) {
    UIView *hitView = hook(self, point, event);
    if (hitView) {
      return hitView;
    }
  }
  return [super hitTest:point withEvent:event];
}

#else

- (NSView *)hitTest:(NSPoint)point
{
  NSEvent *event = [NSApp currentEvent];
  for (CKComponentRootViewHitTestHook hook in hitTestHooks) {
    UIView *hitView = hook(self, point, event);
    if (hitView) {
      return hitView;
    }
  }
  return [super hitTest:point];
}

#endif

@end
