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
#import "CKTransactionalComponentDataSourceItemInternal.h"

#import "CKComponentLayout.h"

@implementation CKTransactionalComponentDataSourceItem
{
  CKComponentLayout _layout;
  id _model;
  CKComponentScopeRoot *_scopeRoot;
}

- (instancetype)initWithLayout:(const CKComponentLayout &)layout
                         model:(id)model
                     scopeRoot:(CKComponentScopeRoot *)scopeRoot
{
  if (self = [super init]) {
    _layout = layout;
    _model = model;
    _scopeRoot = scopeRoot;
  }
  return self;
}

- (const CKComponentLayout &)layout
{
  return _layout;
}

@end
