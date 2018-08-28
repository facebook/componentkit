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

#import <ComponentKit/CKFlexboxComponent.h>
#import <ComponentKitTestHelpers/CKEmbeddedTestComponent.h>
#import <ComponentKitTestHelpers/CKLifecycleTestComponent.h>

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

- (instancetype)initWithColor:(UIColor *)color
                         size:(const CKComponentSize &)size
               embedInFlexbox:(BOOL)embedInFlexbox
         embedInTestComponent:(BOOL)embedInTestComponent
{
  if (self = [super init]) {
    _color = color;
    _size = size;
    _embedInFlexbox = embedInFlexbox;
    _embedInTestComponent = embedInTestComponent;
  }
  return self;
}

@end

CKComponent *CKComponentWithHostingViewTestModel(CKComponentHostingViewTestModel *model)
{
  if (model.embedInTestComponent) {
    return [CKEmbeddedTestComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [model color]}}} size:[model size]];
  }
  
  if (model.embedInFlexbox) {
    return [CKFlexboxComponent
            newWithView:{}
            size:{}
            style:{}
            children:{
              {
                .component = [CKLifecycleTestComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [model color]}}}
                                                              size:[model size]],
                .sizeConstraints = model.size
              }
            }];
  } else {
    return [CKLifecycleTestComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [model color]}}}
                                            size:[model size]];
  }
}
