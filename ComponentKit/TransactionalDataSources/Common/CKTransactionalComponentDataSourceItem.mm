/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKTransactionalComponentDataSourceItem.h"
#import "CKTransactionalComponentDataSourceItem+Internal.h"

#import "CKComponentLayout.h"

@implementation CKTransactionalComponentDataSourceItem
{
  CKComponentLayout _layout;
  id _model;
  CKComponentScopeFrame *_scopeFrame;
}

- (instancetype)initWithLayout:(const CKComponentLayout &)layout
                         model:(id)model
                    scopeFrame:(CKComponentScopeFrame *)scopeFrame
{
  if (self = [super init]) {
    _layout = layout;
    _model = model;
    _scopeFrame = scopeFrame;
  }
  return self;
}

- (const CKComponentLayout &)layout
{
  return _layout;
}

- (id)model
{
  return _model;
}

- (CKComponentScopeFrame *)scopeFrame
{
  return _scopeFrame;
}

- (void)announceEventToControllers:(CKComponentAnnouncedEvent)event
{
  [_scopeFrame announceEventToControllers:event];
}

- (CKComponentBoundsAnimation)boundsAnimationFromPreviousItem:(CKTransactionalComponentDataSourceItem *)previousItem
{
  return [_scopeFrame boundsAnimationFromPreviousRootScopeFrame:[previousItem scopeFrame]];
}

@end
