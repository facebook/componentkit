/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKTransactionalComponentDataSourceConfiguration.h"

#import "CKEqualityHashHelpers.h"
#import "CKMacros.h"

@implementation CKTransactionalComponentDataSourceConfiguration
{
  CKSizeRange _sizeRange;
}

- (instancetype)initWithComponentProvider:(Class<CKComponentProvider>)componentProvider
                                  context:(id<NSObject>)context
                                sizeRange:(const CKSizeRange &)sizeRange
                               workThread:(NSThread *)workThread
{
  if (self = [super init]) {
    CKAssert(!workThread || workThread.isExecuting, @"The specified work thread must be executing");
    _componentProvider = componentProvider;
    _context = context;
    _sizeRange = sizeRange;
    _workThread = workThread;
  }
  return self;
}

- (const CKSizeRange &)sizeRange
{
  return _sizeRange;
}

- (BOOL)isEqual:(id)object
{
  if (![object isKindOfClass:[CKTransactionalComponentDataSourceConfiguration class]]) {
    return NO;
  } else {
    CKTransactionalComponentDataSourceConfiguration *obj = (CKTransactionalComponentDataSourceConfiguration *)object;
    return (_componentProvider == obj.componentProvider
            && [_context isEqual:obj.context]
            && _sizeRange == obj.sizeRange
            && _workThread == obj.workThread);
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
