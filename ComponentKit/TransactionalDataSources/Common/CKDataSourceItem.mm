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

#import "CKComponent.h"
#import "CKComponentLayout.h"

@implementation CKDataSourceItem
{
  BOOL _hasRootLayoutAndBoundsAnimation;
  CKComponentRootLayout _rootLayout;
  id _model;
  CKComponentScopeRoot *_scopeRoot;
}

@synthesize boundsAnimation = _boundsAnimation;

- (instancetype)initWithModel:(id)model
                    scopeRoot:(CKComponentScopeRoot *)scopeRoot
{
  if (self = [super init]) {
    _model = model;
    _scopeRoot = scopeRoot;
    _hasRootLayoutAndBoundsAnimation = NO;
  }
  return self;
}

- (instancetype)initWithRootLayout:(const CKComponentRootLayout &)rootLayout
                             model:(id)model
                         scopeRoot:(CKComponentScopeRoot *)scopeRoot
                   boundsAnimation:(CKComponentBoundsAnimation)boundsAnimation
{
  if (self = [self initWithModel:model scopeRoot:scopeRoot]) {
    _boundsAnimation = boundsAnimation;
    _rootLayout = rootLayout;
    _hasRootLayoutAndBoundsAnimation = YES;
  }
  return self;
}

- (CKComponentBoundsAnimation)boundsAnimation
{
  CKAssert(_hasRootLayoutAndBoundsAnimation, @"When using the initializer without giving a layout you must override this method");
  return _boundsAnimation;
}

- (const CKComponentRootLayout &)rootLayout
{
  CKAssert(_hasRootLayoutAndBoundsAnimation, @"When using the initializer without giving a layout you must override this method");
  return _rootLayout;
}

- (NSString *)description
{
  return [_model description];
}

#pragma mark - CKCategorizable

- (CK::NonNull<NSString *>)ck_category
{
  const auto component = self.rootLayout.component();
  if (!component) {
    return CKDefaultCategory;
  }
  NSString *modelCategory = nil;
  // In the case where `model` is generic, we delegate categorization to `model` if it implements `CKCategorizable`.
  if ([_model respondsToSelector:@selector(ck_category)]) {
    modelCategory = ((id<CKCategorizable>)_model).ck_category;
  } else if (_model) {
    modelCategory = NSStringFromClass([_model class]);
  }
  return CK::makeNonNull([NSString stringWithFormat:@"%@-%@", modelCategory, NSStringFromClass(component.class)]);
}

@end
