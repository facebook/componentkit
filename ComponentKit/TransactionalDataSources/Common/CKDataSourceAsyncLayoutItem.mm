/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKDataSourceAsyncLayoutItem.h"
#import "CKDataSourceItemInternal.h"
#import "CKDataSourceQOSHelper.h"
#import "CKAnalyticsListener.h"
#import "CKDataSourceModificationHelper.h"

#import <ComponentKit/CKComponentLayout.h>

#import <mutex>

@implementation CKDataSourceAsyncLayoutItem
{
  std::atomic<BOOL> _hasScheduledLayout;
  std::atomic<BOOL> _hasStartedLayout;
  NSOperationQueue *_queue;

  std::atomic<BOOL> _isFinished;
  std::mutex _waitOnLayoutMutex;
  CKDataSourceItem *_item;
  id<CKSystraceListener> _systraceListener;

  CKComponentScopeRoot *_previousRoot;
  CKComponentStateUpdateMap _stateUpdateMap;
  CKSizeRange _sizeRange;
  CKDataSourceConfiguration *_configuration;
  id _model;
  id _context;
}

- (instancetype)initWithQueue:(NSOperationQueue *)queue
                 previousRoot:(CKComponentScopeRoot *)previousRoot
                 stateUpdates:(const CKComponentStateUpdateMap &)stateUpdates
                    sizeRange:(const CKSizeRange &)sizeRange
                configuration:(CKDataSourceConfiguration *)configuration
                        model:(id)model
                      context:(id)context
{
  if(self = [self initWithModel:model scopeRoot:previousRoot]) {
    _isFinished = NO;
    _hasScheduledLayout = NO;
    _hasStartedLayout = NO;
    _queue = queue;
    _previousRoot = previousRoot;
    _stateUpdateMap = stateUpdates;
    _sizeRange = sizeRange;
    _configuration = configuration;
    _model = model;
    _context = context;
    _systraceListener = [[previousRoot analyticsListener] systraceListener];
  }
  return self;
}

- (void)beginLayout
{
  if (!_hasStartedLayout && !_hasScheduledLayout.exchange(YES)) {
    [_queue addOperationWithBlock:^{
      if(!_hasStartedLayout.exchange(YES)) {
        std::lock_guard<std::mutex> l(_waitOnLayoutMutex);
        [self _buildDataSourceItem];
      }
    }];
  }
}

- (const CKComponentRootLayout &)rootLayout
{
  return [[self _getItemSync] rootLayout];
}

- (CKComponentBoundsAnimation)boundsAnimation
{
  return [[self _getItemSync] boundsAnimation];
}

- (CKDataSourceItem *)_getItemSync
{
  if (_isFinished == YES) {
    return _item;
  } else if(!_hasStartedLayout.exchange(YES)) {
    return [self _buildDataSourceItem];
  } else {
    [_systraceListener willBlockThreadOnGeneratingItemLayout];
    std::lock_guard<std::mutex> l(_waitOnLayoutMutex);
    [_systraceListener didBlockThreadOnGeneratingItemLayout];
    return _item;
  }
}

- (CKDataSourceItem *)_buildDataSourceItem
{
  auto item = CKBuildDataSourceItem(_previousRoot, _stateUpdateMap, _sizeRange, _configuration, _model, _context);
  _item = item;
  _isFinished = YES;
  return _item;
}

- (BOOL)hasFinishedComputingLayout
{
  return _isFinished;
}

@end
