/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <ComponentKit/RCDimension_SwiftBridge.h>
#import <ComponentKit/RCDimension_SwiftBridge+Internal.h>

#import <ComponentKit/CKCasting.h>

@implementation RCDimension_SwiftBridge {
  RCRelativeDimension _dimension;
}

- (instancetype)initWithDimension:(const RCRelativeDimension &)dimension
{
  self = [super init];
  _dimension = dimension;
  return self;
}

- (instancetype)init
{
  return [self initWithDimension:{}];
}

- (instancetype)initWithPoints:(CGFloat)points
{
  return [self initWithDimension:{points}];
}

- (instancetype)initWithPercent:(CGFloat)percent
{
  return [self initWithDimension:RCRelativeDimension::Percent(percent)];
}

+ (instancetype)autoInstance
{
  return [[self alloc] initWithDimension:RCRelativeDimension::Auto()];
}

- (const RCRelativeDimension &)dimension
{
  return _dimension;
}

- (BOOL)isEqual:(id)other
{
  if (other == nil) {
    return NO;
  } else if (other == self) {
    return YES;
  } else {
    // Intentionally treat passing a different type as a programming error
    return _dimension == CK::objCForceCast<RCDimension_SwiftBridge>(other)->_dimension;
  }
}

- (NSUInteger)hash
{
  return std::hash<RCRelativeDimension>{}(_dimension);
}

- (NSString *)description
{
  return _dimension.description();
}

@end
