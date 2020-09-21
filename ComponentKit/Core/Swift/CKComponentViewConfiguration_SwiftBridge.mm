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

- (instancetype)initWithViewClass:(Class)viewClass attributes:(NSArray<CKComponentViewAttribute_SwiftBridge *> *)attributes
{
  return [self initWithViewConfiguration:{viewClass, CKComponentViewAttribute_SwiftBridgeToMap(attributes)}];
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
