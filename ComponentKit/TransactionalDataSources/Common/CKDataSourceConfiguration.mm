/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKDataSourceConfiguration.h"
#import "CKDataSourceConfigurationInternal.h"

#import <ComponentKit/RCEqualityHelpers.h>
#import <ComponentKit/CKGlobalConfig.h>
#import <ComponentKit/CKMacros.h>

static auto nilProvider(id<NSObject>, id<NSObject>) -> CKComponent * { return nil; }

@implementation CKDataSourceConfiguration
{
  CKSizeRange _sizeRange;
  std::unordered_set<CKComponentPredicate> _componentPredicates;
  std::unordered_set<CKComponentControllerPredicate> _componentControllerPredicates;
  CKDataSourceOptions _options;
  CKComponentProviderFunc _componentProvider;
}

- (instancetype)initWithComponentProviderFunc:(CKComponentProviderFunc)componentProvider
                                      context:(id<NSObject>)context
                                    sizeRange:(const CKSizeRange &)sizeRange
{
  return [self initWithComponentProviderFunc:componentProvider
                                     context:context
                                   sizeRange:sizeRange
                                     options:{}
                         componentPredicates:{}
               componentControllerPredicates:{}
                           analyticsListener:nil];
}

- (instancetype)initWithComponentProviderFunc:(CKComponentProviderFunc)componentProvider
                                      context:(id<NSObject>)context
                                    sizeRange:(const CKSizeRange &)sizeRange
                                      options:(const CKDataSourceOptions &)options
                          componentPredicates:(const std::unordered_set<CKComponentPredicate> &)componentPredicates
                componentControllerPredicates:(const std::unordered_set<CKComponentControllerPredicate> &)componentControllerPredicates
                            analyticsListener:(id<CKAnalyticsListener>)analyticsListener
{
  if (self = [super init]) {
    _componentProvider = componentProvider ?: nilProvider;
    _context = context;
    _sizeRange = sizeRange;
    _componentPredicates = componentPredicates;
    _componentControllerPredicates = componentControllerPredicates;
    _analyticsListener = analyticsListener;
    _options = options;
  }
  return self;
}

- (instancetype)copyWithContext:(id<NSObject>)context sizeRange:(const CKSizeRange &)sizeRange
{
  return
  [[CKDataSourceConfiguration alloc]
   initWithComponentProviderFunc:_componentProvider
   context:context
   sizeRange:sizeRange
   options:_options
   componentPredicates:_componentPredicates
   componentControllerPredicates:_componentControllerPredicates
   analyticsListener:_analyticsListener];
}

- (const CKDataSourceOptions &)options
{
  return _options;
}

- (const std::unordered_set<CKComponentPredicate> &)componentPredicates
{
  return _componentPredicates;
}

- (const std::unordered_set<CKComponentControllerPredicate> &)componentControllerPredicates
{
  return _componentControllerPredicates;
}

- (const CKSizeRange &)sizeRange
{
  return _sizeRange;
}

- (CKComponentProviderFunc)componentProvider
{
  return _componentProvider;
}

- (BOOL)isEqual:(id)object
{
  if (![object isKindOfClass:[CKDataSourceConfiguration class]]) {
    return NO;
  } else {
    CKDataSourceConfiguration *obj = (CKDataSourceConfiguration *)object;
    return (_componentProvider == obj->_componentProvider
            && (_context == obj.context || [_context isEqual:obj.context])
            && _sizeRange == obj.sizeRange);
  }
}

- (BOOL)hasSameComponentProviderAndContextAs:(CKDataSourceConfiguration *)other
{
  if (other == nil) {
    return NO;
  }
  return _componentProvider == other->_componentProvider && (_context == other.context || [_context isEqual:other.context]);
}

- (NSUInteger)hash
{
  NSUInteger hashes[2] = {
    [_context hash],
    _sizeRange.hash()
  };
  return RCIntegerArrayHash(hashes, CK_ARRAY_COUNT(hashes));
}

@end
