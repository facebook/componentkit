/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentHostingViewTestModel.h"

#import <ComponentKit/CKComponent.h>

@implementation CKComponentHostingViewTestModel

- (instancetype)initWithColor:(UIColor *)color
                         size:(const CKComponentSize &)size
{
  if (self = [super init]) {
    _color = color;
    _size = size;
  }
  return self;
}

@end

CKComponent *CKComponentWithHostingViewTestModel(CKComponentHostingViewTestModel *model)
{
  return [CKComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [model color]}}}
                             size:[model size]];
}
