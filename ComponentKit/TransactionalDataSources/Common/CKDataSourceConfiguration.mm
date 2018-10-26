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

#import "CKEqualityHashHelpers.h"
#import "CKMacros.h"

@implementation CKDataSourceConfiguration
{
  CKSizeRange _sizeRange;
  std::unordered_set<CKComponentPredicate> _componentPredicates;
  std::unordered_set<CKComponentControllerPredicate> _componentControllerPredicates;
  CKBuildComponentConfig _buildComponentConfig;
  CKDataSourceSplitChangesetOptions _splitChangesetOptions;
}

- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider
                                  context:(id<NSObject>)context
                                sizeRange:(const CKSizeRange &)sizeRange
{
  return [self initWithComponentProvider:componentProvider
                                 context:context
                               sizeRange:sizeRange
                    buildComponentConfig:{}
                   splitChangesetOptions:{}
                               workQueue:nil
           applyModificationsOnWorkQueue:NO
                     unifyBuildAndLayout:NO
                     componentPredicates:{}
           componentControllerPredicates:{}
                       analyticsListener:nil];
}

- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider
                                  context:(id<NSObject>)context
                                sizeRange:(const CKSizeRange &)sizeRange
                     buildComponentConfig:(const CKBuildComponentConfig &)buildComponentConfig
                    splitChangesetOptions:(const CKDataSourceSplitChangesetOptions &)splitChangesetOptions
                                workQueue:(dispatch_queue_t)workQueue
            applyModificationsOnWorkQueue:(BOOL)applyModificationsOnWorkQueue
                      unifyBuildAndLayout:(BOOL)unifyBuildAndLayout
                      componentPredicates:(const std::unordered_set<CKComponentPredicate> &)componentPredicates
            componentControllerPredicates:(const std::unordered_set<CKComponentControllerPredicate> &)componentControllerPredicates
                        analyticsListener:(id<CKAnalyticsListener>)analyticsListener
{
  if (self = [super init]) {
    _componentProvider = componentProvider;
    _context = context;
    _sizeRange = sizeRange;
    _componentPredicates = componentPredicates;
    _componentControllerPredicates = componentControllerPredicates;
    _analyticsListener = analyticsListener;
    _unifyBuildAndLayout = unifyBuildAndLayout;
    _buildComponentConfig = buildComponentConfig;
    _splitChangesetOptions = splitChangesetOptions;
    _workQueue = workQueue;
    _applyModificationsOnWorkQueue = applyModificationsOnWorkQueue;
  }
  return self;
}

- (const CKBuildComponentConfig &)buildComponentConfig
{
  return _buildComponentConfig;
}

- (const CKDataSourceSplitChangesetOptions &)splitChangesetOptions
{
  return _splitChangesetOptions;
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

- (BOOL)isEqual:(id)object
{
  if (![object isKindOfClass:[CKDataSourceConfiguration class]]) {
    return NO;
  } else {
    CKDataSourceConfiguration *obj = (CKDataSourceConfiguration *)object;
    return (_componentProvider == obj.componentProvider
            && (_context == obj.context || [_context isEqual:obj.context])
            && _sizeRange == obj.sizeRange);
  }
}

- (NSUInteger)hash
{
  NSUInteger hashes[2] = {
    [_context hash],
    _sizeRange.hash()
  };
  return CKIntegerArrayHash(hashes, CK_ARRAY_COUNT(hashes));
}

@end
