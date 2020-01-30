/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKDataSourceChange.h"

@implementation CKDataSourceChange

- (instancetype)initWithState:(CKDataSourceState *)state
                previousState:(CKDataSourceState *)previousState
               appliedChanges:(CKDataSourceAppliedChanges *)appliedChanges
             appliedChangeset:(CKDataSourceChangeset *)appliedChangeset
            deferredChangeset:(CKDataSourceChangeset *)deferredChangeset
    addedComponentControllers:(NSArray<CKComponentController *> *)addedComponentControllers
  invalidComponentControllers:(NSArray<CKComponentController *> *)invalidComponentControllers
{
  if (self = [super init]) {
    _state = state;
    _previousState = previousState;
    _appliedChanges = appliedChanges;
    _appliedChangeset = appliedChangeset;
    _deferredChangeset = deferredChangeset;
    _addedComponentControllers = addedComponentControllers;
    _invalidComponentControllers = invalidComponentControllers;
  }
  return self;
}

@end
