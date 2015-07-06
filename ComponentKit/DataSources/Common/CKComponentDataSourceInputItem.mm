/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentDataSourceInputItem.h"

#import "CKEqualityHashHelpers.h"
#import "ComponentUtilities.h"
#import "CKComponentLifecycleManager.h"
#import "CKMacros.h"

@implementation CKComponentDataSourceInputItem
{
  NSUInteger _hash;
  CKSizeRange _constrainedSize;
}

- (instancetype)initWithLifecycleManager:(CKComponentLifecycleManager *)lifecycleManager
                                   model:(id<NSObject>)model
                         constrainedSize:(CKSizeRange)constrainedSize
                                    UUID:(NSString *)UUID
{
  if (self = [super init]) {
    _lifecycleManager = lifecycleManager;
    _model = model;
    _constrainedSize = constrainedSize;
    _UUID = [UUID copy];

    NSUInteger subhashes[] = {
      [_lifecycleManager hash],
      [_model hash],
      _constrainedSize.hash(),
      [_UUID hash],
    };
    _hash = CKIntegerArrayHash(subhashes, CK_ARRAY_COUNT(subhashes));
  }
  return self;
}

- (CKSizeRange)constrainedSize
{
  return _constrainedSize;
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[CKComponentDataSourceInputItem class]]) {
    return NO;
  }
  CKComponentDataSourceInputItem *other = (CKComponentDataSourceInputItem *)object;
  return (CKObjectIsEqual(_lifecycleManager, other->_lifecycleManager) &&
          CKObjectIsEqual(_model, other->_model) &&
          _constrainedSize == other->_constrainedSize &&
          CKObjectIsEqual(_UUID, other->_UUID));
}

- (NSUInteger)hash
{
  return _hash;
}

@end
