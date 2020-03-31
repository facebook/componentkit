/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/CKComponentSize_SwiftBridge.h>
#import <ComponentKit/CKComponentSize_SwiftBridge+Internal.h>

#import <ComponentKit/CKCasting.h>
#import <ComponentKit/CKDimension_SwiftBridge+Internal.h>

@implementation CKComponentSize_SwiftBridge {
  CKComponentSize _size;
}

- (instancetype)initWithComponentSize:(const CKComponentSize &)componentSize
{
  self = [super init];
  _size = componentSize;
  return self;
}

- (instancetype)init
{
  return [self initWithComponentSize:{}];
}

- (instancetype)initWithSize:(CGSize)size
{
  return [self initWithComponentSize:CKComponentSize::fromCGSize(size)];
}

- (instancetype)initWithWidth:(CKDimension_SwiftBridge *)width
                       height:(CKDimension_SwiftBridge *)height
                     minWidth:(CKDimension_SwiftBridge *)minWidth
                    minHeight:(CKDimension_SwiftBridge *)minHeight
                     maxWidth:(CKDimension_SwiftBridge *)maxWidth
                    maxHeight:(CKDimension_SwiftBridge *)maxHeight
{
  return
  [self initWithComponentSize:{
    .width = width.dimension,
    .height = height.dimension,
    .minWidth = minWidth.dimension,
    .minHeight = minHeight.dimension,
    .maxWidth = maxWidth.dimension,
    .maxHeight = maxHeight.dimension,
  }];
}

- (const CKComponentSize &)componentSize
{
  return _size;
}

- (BOOL)isEqual:(id)other
{
  if (other == nil) {
    return NO;
  } else if (other == self) {
    return YES;
  } else {
    // Intentionally treat passing a different type as a programming error
    return _size == CK::objCForceCast<CKComponentSize_SwiftBridge>(other)->_size;
  }
}

- (NSUInteger)hash
{
  return std::hash<CKComponentSize>{}(_size);
}

- (NSString *)description
{
  return _size.description();
}

@end
