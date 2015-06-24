/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentDataSourceOutputItem.h"

#import "CKEqualityHashHelpers.h"
#import "ComponentUtilities.h"
#import "CKComponentLifecycleManager.h"
#import "CKMacros.h"

@implementation CKComponentDataSourceOutputItem
{
  CKComponentLifecycleManagerState _lifecycleManagerState;
  NSUInteger _hash;
}

- (instancetype)initWithLifecycleManager:(CKComponentLifecycleManager *)lifecycleManager
                   lifecycleManagerState:(const CKComponentLifecycleManagerState &)lifecycleManagerState
                                 oldSize:(CGSize)oldSize
                                   model:(id<NSObject>)model
                                    UUID:(NSString *)UUID
{
  if (self = [super init]) {
    _lifecycleManager = lifecycleManager;
    _lifecycleManagerState = lifecycleManagerState;
    _oldSize = oldSize;
    _model = model;
    _UUID = [UUID copy];

    NSUInteger subhashes[] = {
      [_lifecycleManager hash],
      [_model hash],
      [_UUID hash],
    };
    _hash = CKIntegerArrayHash(subhashes, CK_ARRAY_COUNT(subhashes));
  }
  return self;
}

- (const CKComponentLifecycleManagerState &)lifecycleManagerState
{
  return _lifecycleManagerState;
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[CKComponentDataSourceOutputItem class]]) {
    return NO;
  }
  CKComponentDataSourceOutputItem *other = (CKComponentDataSourceOutputItem *)object;
  return (
          CKObjectIsEqual(_lifecycleManager, other->_lifecycleManager) &&
          CKObjectIsEqual(_model, other->_model) &&
          CKObjectIsEqual(_UUID, other->_UUID)
          );
}

- (NSUInteger)hash
{
  return _hash;
}

@end
