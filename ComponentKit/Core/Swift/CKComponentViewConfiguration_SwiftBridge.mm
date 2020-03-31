/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKComponentViewConfiguration_SwiftBridge.h>
#import <ComponentKit/CKComponentViewConfiguration_SwiftBridge+Internal.h>

#import <ComponentKit/CKComponentViewAttribute_SwiftBridge+Internal.h>

@implementation CKComponentViewConfiguration_SwiftBridge {
  CKComponentViewConfiguration _viewConfig;
}

- (instancetype)init
{
  return [self initWithViewConfiguration:{}];
}

- (instancetype)initWithViewClass:(Class)viewClass
{
  return [self initWithViewConfiguration:{viewClass}];
}

static auto attributeMapFromSwiftAttributes(NSArray<CKComponentViewAttribute_SwiftBridge *> *attributes) -> CKViewComponentAttributeValueMap
{
  auto attrMap = CKViewComponentAttributeValueMap{};
  attrMap.reserve(attributes.count);
  for (CKComponentViewAttribute_SwiftBridge *attr in attributes) {
    attrMap.insert({
      attr.viewAttribute,
      @YES // Bogus value, not actually used
    });
  }
  return attrMap;
}

- (instancetype)initWithViewClass:(Class)viewClass attributes:(NSArray<CKComponentViewAttribute_SwiftBridge *> *)attributes
{
  return [self initWithViewConfiguration:{viewClass, attributeMapFromSwiftAttributes(attributes)}];
}

- (instancetype)initWithViewConfiguration:(const CKComponentViewConfiguration &)viewConfig
{
  if (self = [super init]) {
    _viewConfig = viewConfig;
  }
  return self;
}

- (const CKComponentViewConfiguration &)viewConfig
{
  return _viewConfig;
}

@end
