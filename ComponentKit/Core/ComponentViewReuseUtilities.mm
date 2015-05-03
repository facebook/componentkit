/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "ComponentViewReuseUtilities.h"

#import <objc/runtime.h>
#import <unordered_map>

#import "CKAssert.h"
#import "CKComponentViewConfiguration.h"

using namespace CK::Component;

static char const kViewReuseInfoKey = ' ';

@interface CKComponentViewReuseInfo : NSObject
- (instancetype)initWithView:(UIView *)view
      didEnterReusePoolBlock:(void (^)(UIView *))didEnterReusePoolBlock
     willLeaveReusePoolBlock:(void (^)(UIView *))willLeaveReusePoolBlock;
- (void)registerChildViewInfo:(CKComponentViewReuseInfo *)info;
- (void)didHide;
- (void)willUnhide;
- (void)ancestorDidHide;
- (void)ancestorWillUnhide;
@end

void ViewReuseUtilities::mountingInRootView(UIView *rootView)
{
  // If we already mounted in this root view, it will already have a reuse info struct.
  if (objc_getAssociatedObject(rootView, &kViewReuseInfoKey)) {
    return;
  }

  CKComponentViewReuseInfo *info = [[CKComponentViewReuseInfo alloc] initWithView:rootView
                                                           didEnterReusePoolBlock:nil
                                                          willLeaveReusePoolBlock:nil];
  objc_setAssociatedObject(rootView, &kViewReuseInfoKey, info, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

void ViewReuseUtilities::createdView(UIView *view, const CKComponentViewClass &viewClass, UIView *parent)
{
  CKCAssertNil(objc_getAssociatedObject(view, &kViewReuseInfoKey),
               @"Didn't expect reuse info on just-created view %@", view);

  CKComponentViewReuseInfo *info = [[CKComponentViewReuseInfo alloc] initWithView:view
                                                           didEnterReusePoolBlock:viewClass.didEnterReusePool
                                                          willLeaveReusePoolBlock:viewClass.willLeaveReusePool];
  objc_setAssociatedObject(view, &kViewReuseInfoKey, info, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

  CKComponentViewReuseInfo *parentInfo = objc_getAssociatedObject(parent, &kViewReuseInfoKey);
  CKCAssertNotNil(parentInfo, @"Expected parentInfo but found none on %@", parent);
  [parentInfo registerChildViewInfo:info];
}

void ViewReuseUtilities::mountingInChildContext(UIView *view, UIView *parent)
{
  // If this view was created by the components infrastructure, or if we've
  // mounted in it before, it will already have a reuse info struct.
  if (objc_getAssociatedObject(view, &kViewReuseInfoKey)) {
    return;
  }

  CKComponentViewReuseInfo *info = [[CKComponentViewReuseInfo alloc] initWithView:view
                                                           didEnterReusePoolBlock:nil
                                                          willLeaveReusePoolBlock:nil];
  objc_setAssociatedObject(view, &kViewReuseInfoKey, info, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

  CKComponentViewReuseInfo *parentInfo = objc_getAssociatedObject(parent, &kViewReuseInfoKey);
  CKCAssertNotNil(parentInfo, @"Expected parentInfo but found none on %@", parent);
  [parentInfo registerChildViewInfo:info];
}

void ViewReuseUtilities::didHide(UIView *view)
{
  CKComponentViewReuseInfo *info = objc_getAssociatedObject(view, &kViewReuseInfoKey);
  CKCAssertNotNil(info, @"Expect to find reuse info on all components-managed views but found none on %@", view);
  [info didHide];
}

void ViewReuseUtilities::willUnhide(UIView *view)
{
  CKComponentViewReuseInfo *info = objc_getAssociatedObject(view, &kViewReuseInfoKey);
  CKCAssertNotNil(info, @"Expect to find reuse info on all components-managed views but found none on %@", view);
  [info willUnhide];
}

@implementation CKComponentViewReuseInfo
{
  // Weak to prevent a retain cycle since the view holds the info strongly via associated objects
  UIView *__weak _view;
  void (^_didEnterReusePoolBlock)(UIView *);
  void (^_willLeaveReusePoolBlock)(UIView *);
  NSMutableArray *_childViewInfos;
  BOOL _hidden;
  BOOL _ancestorHidden;
}

- (instancetype)initWithView:(UIView *)view
      didEnterReusePoolBlock:(void (^)(UIView *))didEnterReusePoolBlock
     willLeaveReusePoolBlock:(void (^)(UIView *))willLeaveReusePoolBlock
{
  if (self = [super init]) {
    _view = view;
    _didEnterReusePoolBlock = didEnterReusePoolBlock;
    _willLeaveReusePoolBlock = willLeaveReusePoolBlock;
  }
  return self;
}

- (void)registerChildViewInfo:(CKComponentViewReuseInfo *)info
{
  if (_childViewInfos == nil) {
    _childViewInfos = [[NSMutableArray alloc] init];
  }
  [_childViewInfos addObject:info];
}

- (void)didHide
{
  if (_hidden) {
    return;
  }
  if (_ancestorHidden == NO && _didEnterReusePoolBlock) {
    _didEnterReusePoolBlock(_view);
  }
  _hidden = YES;

  for (CKComponentViewReuseInfo *descendantInfo in _childViewInfos) {
    [descendantInfo ancestorDidHide];
  }
}

- (void)willUnhide
{
  if (!_hidden) {
    return;
  }
  if (_ancestorHidden == NO && _willLeaveReusePoolBlock) {
    _willLeaveReusePoolBlock(_view);
  }
  _hidden = NO;

  for (CKComponentViewReuseInfo *descendantInfo in _childViewInfos) {
    [descendantInfo ancestorWillUnhide];
  }
}

- (void)ancestorDidHide
{
  if (_ancestorHidden) {
    return;
  }
  if (_hidden == NO && _didEnterReusePoolBlock) {
    _didEnterReusePoolBlock(_view);
  }
  _ancestorHidden = YES;

  if (_hidden) {
    // Since this view is itself already hidden, no need to notify children. They already have _ancestorHidden = YES.
    return;
  }

  for (CKComponentViewReuseInfo *descendantInfo in _childViewInfos) {
    [descendantInfo ancestorDidHide];
  }
}

- (void)ancestorWillUnhide
{
  if (!_ancestorHidden) {
    return;
  }
  if (_hidden == NO && _willLeaveReusePoolBlock) {
    _willLeaveReusePoolBlock(_view);
  }
  _ancestorHidden = NO;

  if (_hidden) {
    // If this view is itself still hidden, the unhiding of an ancestor changes nothing for children.
    return;
  }

  for (CKComponentViewReuseInfo *descendantInfo in _childViewInfos) {
    [descendantInfo ancestorWillUnhide];
  }
}

@end
