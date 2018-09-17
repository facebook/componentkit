/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKDataSourceItem.h"
#import "CKDataSourceItemInternal.h"

#import "CKComponentLayout.h"

@implementation CKDataSourceItem
{
  CKComponentRootLayout _rootLayout;
  id _model;
  CKComponentScopeRoot *_scopeRoot;
}

- (instancetype)initWithRootLayout:(const CKComponentRootLayout &)rootLayout
                             model:(id)model
                         scopeRoot:(CKComponentScopeRoot *)scopeRoot
                   boundsAnimation:(CKComponentBoundsAnimation)boundsAnimation
{
  if (self = [super init]) {
    _rootLayout = rootLayout;
    _model = model;
    _scopeRoot = scopeRoot;
    _boundsAnimation = boundsAnimation;
  }
  return self;
}

- (const CKComponentRootLayout &)rootLayout
{
  return _rootLayout;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"%@ - model:%@", [super description], _model];
}

@end
