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
  return [self initWithColor:color
                        size:size
                 wrapperType:CKComponentHostingViewWrapperTypeNone];
}

- (instancetype)initWithColor:(UIColor *)color
                         size:(const CKComponentSize &)size
                  wrapperType:(CKComponentHostingViewWrapperType)wrapperType
{
  if (self = [super init]) {
    _color = color;
    _size = size;
    _wrapperType = wrapperType;
  }
  return self;
}

@end

static CKComponent *componentWithDeepViewHierarchy(NSInteger viewLevel)
{
  if (viewLevel == 0) {
    return nil;
  }
  return
  CK::FlexboxComponentBuilder()
      .viewClass([UIImageView class])
      .child(componentWithDeepViewHierarchy(viewLevel - 1))
      .child(componentWithDeepViewHierarchy(viewLevel - 1))
      .build();
}

CKComponent *CKComponentWithHostingViewTestModel(CKComponentHostingViewTestModel *model)
{
  switch(model.wrapperType) {
    case CKComponentHostingViewWrapperTypeTestComponent: {
      return
      [CKEmbeddedTestComponent
       newWithView:{[UIView class], {{@selector(setBackgroundColor:), [model color]}}}
       size:[model size]];
    }
    case CKComponentHostingViewWrapperTypeFlexbox: {
      return
      CK::FlexboxComponentBuilder()
          .child([CKLifecycleTestComponent
            newWithView:{[UIView class], {{@selector(setBackgroundColor:), [model color]}}}
            size:[model size]])
              .sizeConstraints(model.size)
          .build();
    }
    case CKComponentHostingViewWrapperTypeRenderComponent: {
      return [CKRenderLifecycleTestComponent new];
    }
    case CKComponentHostingViewWrapperTypeNone: {
      return
      [CKLifecycleTestComponent
       newWithView:{[UIView class], {{@selector(setBackgroundColor:), [model color]}}}
       size:[model size]];
    }
    case CKComponentHostingViewWrapperTypeDeepViewHierarchy: {
      return componentWithDeepViewHierarchy(4);
    }
  }
}
